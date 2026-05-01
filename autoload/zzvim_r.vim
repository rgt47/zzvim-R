" ============================================================================
" zzvim-R autoload entry point
" ============================================================================
" Logic extracted from plugin/zzvim-R.vim. Loaded lazily on first
" reference to a zzvim_r# function, which keeps Vim startup cost
" bounded regardless of plugin feature surface.
"
" Functions in this file are migrated incrementally from the
" monolithic plugin/zzvim-R.vim. See RELEASE_PLAN.md Phase 4.
" ============================================================================

" ----------------------------------------------------------------------------
" Version comparison
" ----------------------------------------------------------------------------

" Compare two semver-style version strings (e.g. '1.0.0' vs '1.0.1').
" Missing components (patch, minor) default to 0, so '1.0' compares
" equal to '1.0.0'. Numeric, not lexicographic: '10.0.0' > '2.0.0'.
" Returns -1 if a < b, 0 if equal, 1 if a > b.
function! zzvim_r#compare_semver(a, b) abort
    let pa = split(a:a, '\.')
    let pb = split(a:b, '\.')
    for i in range(3)
        let na = str2nr(get(pa, i, '0'))
        let nb = str2nr(get(pb, i, '0'))
        if na < nb | return -1 | endif
        if na > nb | return 1 | endif
    endfor
    return 0
endfunction

" Extract semver from the first 20 lines of a file, matching either
" 'zzvim-R .Rprofile.local vX.Y.Z' or legacy 'zzvim-R template version: N'
" (translated to 0.0.N). Returns '' when no marker is present.
function! zzvim_r#get_rprofile_version(filepath) abort
    if !filereadable(a:filepath)
        return ''
    endif
    for line in readfile(a:filepath, '', 20)
        let match = matchlist(line, 'zzvim-R \.Rprofile\.local v\(\d\+\.\d\+\.\d\+\)')
        if !empty(match)
            return match[1]
        endif
        let match = matchlist(line, 'zzvim-R template version:\s*\(\d\+\)')
        if !empty(match)
            return '0.0.' . match[1]
        endif
    endfor
    return ''
endfunction

" ----------------------------------------------------------------------------
" R code pattern detection
" ----------------------------------------------------------------------------

" True when the given line ends with an R infix operator (pipe,
" assignment, arithmetic, logical, comparison, trailing comma).
" Used by <CR> submission to decide whether to collect continuation
" lines into a single multi-line expression.
function! zzvim_r#ends_with_infix_operator(line) abort
    return a:line =~# '[+\-*/^&|<>=!,]\s*$' ||
                \ a:line =~# '%[^%]*%\s*$' ||
                \ a:line =~# '<-\s*$' ||
                \ a:line =~# '|>\s*$'
endfunction

" True when the current cursor line is a continuation of a prior
" incomplete statement. Three branches:
"   1. Current line begins with a closing delimiter )/}/]/,
"   2. Current line is a lone parameter name after '(' or ',' on
"      the previous line
"   3. Previous line ends with an infix operator
function! zzvim_r#is_incomplete_statement() abort
    let current_line = getline('.')

    " Lines that clearly look like continuation/closing lines
    if current_line =~# '^\s*[)}\],]'
        return 1
    endif

    " Lines that are just parameter names or values (common in multi-line calls)
    " Exclude lines that contain assignments as these are statement starts.
    if current_line =~# '^\s*[a-zA-Z_][a-zA-Z0-9_.]*\s*[,)]\s*$' && current_line !~# '<-\|='
        if line('.') > 1
            let prev_line = getline(line('.') - 1)
            if prev_line =~# '[\(,]\s*$'
                return 1
            endif
        endif
    endif

    " Previous line ends with any infix operator
    if line('.') > 1
        let prev_line = getline(line('.') - 1)
        if prev_line =~# '[+\-*/^&|<>=!]\s*$' || prev_line =~# '%[^%]*%\s*$' ||
                    \ prev_line =~# '<-\s*$' || prev_line =~# '|>\s*$'
            return 1
        endif
    endif

    return 0
endfunction

" True when the cursor is positioned inside an R function body
" (between 'function(' and its matching closing '}'). Bounded to
" ~50 lines of backward scan and ~100 lines forward to keep cost
" bounded on large files.
function! zzvim_r#is_inside_function() abort
    let save_pos = getpos('.')
    let current_line = line('.')

    if current_line < 3
        return 0
    endif

    let search_limit = max([1, current_line - 50])
    let function_start = search('function\s*(', 'bcnW', search_limit)

    if function_start == 0
        return 0
    endif

    call cursor(function_start, 1)
    let brace_line = search('{', 'W', function_start + 5)

    if brace_line == 0
        call setpos('.', save_pos)
        return 0
    endif

    let brace_count = 0
    let end_line = -1
    let search_end = min([line('$'), brace_line + 100])

    for line_num in range(brace_line, search_end)
        let line_content = getline(line_num)
        let open_braces = len(substitute(line_content, '[^{]', '', 'g'))
        let close_braces = len(substitute(line_content, '[^}]', '', 'g'))
        let brace_count += open_braces - close_braces

        if brace_count == 0 && (open_braces > 0 || close_braces > 0)
            let end_line = line_num
            break
        endif

        if line_num > current_line + 20
            break
        endif
    endfor

    call setpos('.', save_pos)

    if end_line > 0 && current_line > function_start && current_line < end_line
        return 1
    endif

    return 0
endfunction

" True when the given line begins a multi-line code block:
" function definition, control structure, bare brace, function call
" with open paren, unbalanced assignment, infix-ended expression,
" or bracketed subscript.
function! zzvim_r#is_block_start(line) abort
    if a:line =~# 'function\s*('
        return 1
    endif

    if a:line =~# '^\s*\(if\|for\|while\)\s*('
        return 1
    endif

    if a:line =~# '^\s*\(repeat\s*\)\?{'
        return 1
    endif

    " Function calls that start at beginning of line (not continuation lines).
    " Exclude lines that start with closing characters or are clearly
    " continuation lines, and lone parameter-name lines with parentheses.
    if a:line =~# '^\s*[a-zA-Z_][a-zA-Z0-9_.]*\s*(' && a:line !~ '^\s*[)}\],]'
        if a:line !~ '^\s*[a-zA-Z_][a-zA-Z0-9_.]*\s*)\s*$'
            return 1
        endif
    endif

    " Assignment statements with function calls that look incomplete.
    if a:line =~# '\(<-\|=\).*[a-zA-Z_][a-zA-Z0-9_.]*\s*('
        if a:line =~# ',$' || a:line =~# '(\s*$'
            return 1
        endif
        let open_count = len(substitute(a:line, '[^(]', '', 'g'))
        let close_count = len(substitute(a:line, '[^)]', '', 'g'))
        if open_count > close_count
            return 1
        endif
    endif

    if zzvim_r#ends_with_infix_operator(a:line)
        return 1
    endif

    if a:line =~# '\[\s*$'
        return 1
    endif

    return 0
endfunction

" ----------------------------------------------------------------------------
" Project-root detection (zzcollab workspaces)
" ----------------------------------------------------------------------------

" Path to the zzcollab workspace root (directory containing .zzcollab/)
" by walking up from cwd. Respects a user override via
" g:zzvim_r_project_root. Returns '' if no marker is found.
function! zzvim_r#get_project_root() abort
    if exists('g:zzvim_r_project_root') && !empty(g:zzvim_r_project_root)
        return g:zzvim_r_project_root
    endif

    let dir = getcwd()
    while dir != '/'
        if isdirectory(dir . '/.zzcollab')
            return dir
        endif
        let dir = fnamemodify(dir, ':h')
    endwhile

    return ''
endfunction

" True when the current cwd is inside a zzcollab workspace.
function! zzvim_r#is_inside_zzcollab() abort
    return !empty(zzvim_r#get_project_root())
endfunction

" Change local directory to the zzcollab project root so getcwd()
" aligns with the Docker container's mount/working directory.
function! zzvim_r#auto_lcd_project_root() abort
    let l:root = zzvim_r#get_project_root()
    if !empty(l:root) && getcwd() !=# l:root
        execute 'lcd ' . fnameescape(l:root)
    endif
endfunction

" True when cwd (or an ancestor) contains a Makefile with an 'r:'
" target. Used to decide whether <LocalLeader>r should invoke the
" Docker workflow via 'make r'.
" Known bug (see test/COVERAGE.md): the regex requires a newline
" before 'r:', so a Makefile whose first line is 'r:' is missed.
function! zzvim_r#is_zzcollab_project() abort
    let l:makefile = findfile('Makefile', '.;')
    if empty(l:makefile)
        return 0
    endif
    let l:content = join(readfile(l:makefile), "\n")
    return l:content =~# '\n\s*r\s*:'
endfunction
