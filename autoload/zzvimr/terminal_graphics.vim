" ============================================================================
" Terminal Graphics Setup for zzvim-R
" ============================================================================
" Handles automatic setup of inline plot display for R development
" Supports: Kitty, Ghostty, WezTerm, iTerm2
" Injects terminal graphics configuration into .Rprofile.local
" Works with zzcollab workspaces and standalone R projects

" Current template version - increment when template changes significantly
let s:template_version = 2

" Detect terminal type
" Returns 'kitty' for terminals supporting Kitty graphics protocol
" Returns 'iterm2' for iTerm2 (uses imgcat)
" Returns 'none' for unsupported terminals
function! zzvimr#terminal_graphics#detect_terminal() abort
    " Kitty - native Kitty graphics protocol
    if !empty($KITTY_WINDOW_ID)
        return 'kitty'
    endif
    " Ghostty - supports Kitty graphics protocol
    if !empty($GHOSTTY_RESOURCES_DIR) || $TERM ==# 'xterm-ghostty'
        return 'kitty'
    endif
    " WezTerm - supports Kitty graphics protocol
    if !empty($WEZTERM_EXECUTABLE) || stridx($TERM_PROGRAM, 'WezTerm') >= 0
        return 'kitty'
    endif
    " iTerm2 - uses imgcat for inline images (macOS only)
    if !empty($ITERM_SESSION_ID) || stridx($TERM_PROGRAM, 'iTerm') >= 0
        return 'iterm2'
    endif
    return 'none'
endfunction

" Check if we're in a project with .Rprofile (zzcollab workspace or R project)
function! zzvimr#terminal_graphics#is_r_project() abort
    return filereadable('.Rprofile') || filereadable('DESCRIPTION')
endfunction

" Get the path to .Rprofile.local template (in the plugin directory)
function! zzvimr#terminal_graphics#get_template_path() abort
    " Use the actual path of this script file, not <sfile> which can be
    " unreliable when called indirectly. We know this file is at:
    " <plugin_root>/autoload/zzvimr/terminal_graphics.vim
    " So we go up 3 levels to get to plugin_root.
    let l:this_file = expand('<script>:p')
    let l:plugin_dir = fnamemodify(l:this_file, ':h:h:h')
    let l:template_path = l:plugin_dir . '/templates/.Rprofile.local'
    return l:template_path
endfunction

" Extract version number from .Rprofile.local file
" Returns 0 if no version found (pre-versioning or missing)
function! zzvimr#terminal_graphics#get_file_version(filepath) abort
    if !filereadable(a:filepath)
        return 0
    endif
    " Read first 10 lines looking for version marker
    let l:lines = readfile(a:filepath, '', 10)
    for l:line in l:lines
        " Match "zzvim-R template version: N"
        let l:match = matchstr(l:line, 'zzvim-R template version:\s*\zs\d\+')
        if !empty(l:match)
            return str2nr(l:match)
        endif
    endfor
    return 0
endfunction

" Backup existing .Rprofile.local before overwriting
function! zzvimr#terminal_graphics#backup_rprofile_local() abort
    if !filereadable('.Rprofile.local')
        return ''
    endif
    let l:backup = '.Rprofile.local.backup.' . strftime('%Y%m%d%H%M%S')
    call system('cp .Rprofile.local ' . shellescape(l:backup))
    if v:shell_error == 0
        return l:backup
    endif
    return ''
endfunction

" Prompt user to update outdated .Rprofile.local
function! zzvimr#terminal_graphics#prompt_update(current_version) abort
    let l:msg = printf(
        \ '.Rprofile.local is outdated (v%d -> v%d). Update for dual-resolution plots? [y/N]: ',
        \ a:current_version, s:template_version)
    echohl WarningMsg
    let l:choice = input(l:msg)
    echohl None
    echo ''
    return l:choice =~? '^y'
endfunction

" Copy or create .Rprofile.local in current working directory
function! zzvimr#terminal_graphics#setup_rprofile_local() abort
    let l:terminal = zzvimr#terminal_graphics#detect_terminal()

    " Only proceed if we're in a supported terminal and R project
    if l:terminal ==# 'none' || !zzvimr#terminal_graphics#is_r_project()
        return 0
    endif

    let l:template_path = zzvimr#terminal_graphics#get_template_path()

    " Check if .Rprofile.local already exists
    if filereadable('.Rprofile.local')
        " Check version
        let l:current_version = zzvimr#terminal_graphics#get_file_version('.Rprofile.local')
        let l:template_version = zzvimr#terminal_graphics#get_file_version(l:template_path)

        " If template is newer, prompt user to update
        if l:template_version > l:current_version
            if zzvimr#terminal_graphics#prompt_update(l:current_version)
                let l:backup = zzvimr#terminal_graphics#backup_rprofile_local()
                if !empty(l:backup)
                    echomsg '[zzvim-R] Backed up to ' . l:backup
                endif
                " Fall through to copy template
            else
                " User declined update
                return 0
            endif
        else
            " Up to date
            return 0
        endif
    endif

    " Try to copy from template
    if filereadable(l:template_path)
        " Copy template to .Rprofile.local
        try
            call system('cp ' . shellescape(l:template_path) . ' .Rprofile.local')
            if v:shell_error == 0
                echomsg '[zzvim-R] Terminal graphics enabled for ' . toupper(l:terminal) . ' (v' . s:template_version . ')'
                return 1
            endif
        catch
            " Silently fail if copy doesn't work
        endtry
    else
        " Template not found, try to create basic .Rprofile.local
        " This is a fallback - ideally template should be included
        call zzvimr#terminal_graphics#create_basic_rprofile_local(l:terminal)
        return 1
    endif

    return 0
endfunction

" Create a basic .Rprofile.local if template is not available
function! zzvimr#terminal_graphics#create_basic_rprofile_local(terminal) abort
    let l:content = [
        \ "# Terminal graphics setup for " . toupper(a:terminal),
        \ "# Auto-generated by zzvim-R",
        \ "",
        \ ".terminal <- '" . a:terminal . "'",
        \ "",
        \ "if (.terminal != 'none') {",
        \ "  .plot_file <- NULL",
        \ "",
        \ "  .display_plot <- function(f) {",
        \ "    if (.terminal == 'kitty') {",
        \ "      result <- suppressWarnings(",
        \ "        system(paste('kitty +kitten icat --align=right', shQuote(f)),",
        \ "               ignore.stderr = TRUE, ignore.stdout = TRUE)",
        \ "      )",
        \ "      if (result != 0) {",
        \ "        system(paste('kitty @ launch --type=window --keep-focus',",
        \ "                     'kitty +kitten icat --hold', shQuote(f)),",
        \ "               ignore.stderr = TRUE)",
        \ "      }",
        \ "    } else if (.terminal == 'iterm2') {",
        \ "      system(paste('imgcat', shQuote(f)))",
        \ "    }",
        \ "  }",
        \ "",
        \ "  zzplot <- function(...) {",
        \ "    f <- tempfile(fileext = '.png')",
        \ "    assign('.plot_file', f, envir = .GlobalEnv)",
        \ "    png(f, width = 800, height = 600)",
        \ "    plot(...)",
        \ "    dev.off()",
        \ "    .display_plot(f)",
        \ "  }",
        \ "",
        \ "  zzggplot <- function(p) {",
        \ "    f <- tempfile(fileext = '.png')",
        \ "    assign('.plot_file', f, envir = .GlobalEnv)",
        \ "    png(f, width = 800, height = 600)",
        \ "    print(p)",
        \ "    dev.off()",
        \ "    .display_plot(f)",
        \ "  }",
        \ "",
        \ "  save_plot <- function(filename) {",
        \ "    if (!is.null(.plot_file) && file.exists(.plot_file)) {",
        \ "      file.copy(.plot_file, filename, overwrite = TRUE)",
        \ "      message('Plot saved to: ', filename)",
        \ "    }",
        \ "  }",
        \ "",
        \ "  if (interactive()) {",
        \ "    message('Terminal graphics enabled (', toupper(.terminal), ')')",
        \ "    message('  zzplot(...)  : Base R plots')",
        \ "    message('  zzggplot(p)  : ggplot2 plots')",
        \ "    message('  save_plot(f) : Save current plot')",
        \ "  }",
        \ "}"
    \ ]

    try
        call writefile(l:content, '.Rprofile.local')
        echomsg '[zzvim-R] Created basic .Rprofile.local for ' . toupper(a:terminal)
    catch
        echomsg '[zzvim-R] Failed to create .Rprofile.local'
    endtry
endfunction

" Add .Rprofile.local to .gitignore if needed
function! zzvimr#terminal_graphics#add_to_gitignore() abort
    let l:gitignore_path = '.gitignore'

    " Check if .gitignore exists
    if !filereadable(l:gitignore_path)
        return  " No .gitignore, skip
    endif

    " Read existing .gitignore
    let l:lines = readfile(l:gitignore_path)

    " Check if .Rprofile.local is already in .gitignore
    for l:line in l:lines
        if l:line =~# '.Rprofile.local'
            return  " Already in .gitignore
        endif
    endfor

    " Add .Rprofile.local to .gitignore
    try
        call writefile(['.Rprofile.local'], l:gitignore_path, 'a')
        echomsg '[zzvim-R] Added .Rprofile.local to .gitignore'
    catch
        " Silently fail if we can't write to .gitignore
    endtry
endfunction

" Initialize terminal graphics on plugin load
function! zzvimr#terminal_graphics#init() abort
    if zzvimr#terminal_graphics#setup_rprofile_local()
        call zzvimr#terminal_graphics#add_to_gitignore()
    endif
endfunction

" Export public functions
let g:zzvimr_terminal_graphics = {
    \ 'detect': function('zzvimr#terminal_graphics#detect_terminal'),
    \ 'init': function('zzvimr#terminal_graphics#init'),
\ }
