" zzvim-R - R development plugin for Vim
" Maintainer:  RG Thomas rgthomas@ucsd.edu
" Version:     1.0
" License:     GPL3 License
"
" Description:
" This plugin provides integration between Vim and R, allowing users to
" send commands to an R terminal, navigate R Markdown chunks, and perform
" common R operations directly from Vim.
"
" Configuration:
" The following variables can be set in your vimrc to customize the plugin's
" behavior:
"
" g:zzvim_r_default_terminal    (string)
"   Sets the default terminal name for R sessions.
"   Default: 'R'
"   Example: let g:zzvim_r_default_terminal = 'R-4.1'
"
" g:zzvim_r_disable_mappings    (boolean)
"   If set to 1, disables all default key mappings.
"   Default: 0
"   Example: let g:zzvim_r_disable_mappings = 1
"
" g:zzvim_r_map_submit         (string)
"   Sets the key mapping for submitting lines to R.
"   Default: '<CR>' (Enter key)
"   Example: let g:zzvim_r_map_submit = '<Leader>s'
"
" g:zzvim_r_terminal_width      (number)
"   Sets the width of the R terminal in the vertical split.
"   Default: 100
"
" g:zzvim_r_command             (string)
"   The command to start the R terminal.
"   Default: 'R --no-save --quiet'
"
" g:zzvim_r_chunk_start         (string)
"   Sets the regular expression for the start of an R Markdown chunk.
"   Default: '^```{'
"
" g:zzvim_r_chunk_end           (string)
"   Sets the regular expression for the end of an R Markdown chunk.
"   Default: '^```$'
"
" g:zzvim_r_debug               (boolean)
"   Enables debug mode with logging to ~/zzvim_r.log.
"   Default: 0
"
" Default Mappings (when g:zzvim_r_disable_mappings = 0):
"   <CR>              - Submit current line to R
"   <localleader>r    - Open R terminal
"   <localleader>o    - Add pipe operator and new line
"   <localleader>j    - Move to next chunk
"   <localleader>k    - Move to previous chunk
"   <localleader>l    - Select and submit current chunk
"   <localleader>t    - Submit all previous chunks
"   <localleader>q    - Send 'Q' to R terminal
"   <localleader>c    - Send Ctrl-C to R terminal
"   <localleader>d    - Run dim() on word under cursor
"   <localleader>h    - Run head() on word under cursor
"   <localleader>s    - Run str() on word under cursor
"   <localleader>p    - Run print() on word under cursor
"   <localleader>n    - Run names() on word under cursor
"   <localleader>f    - Run length() on word under cursor
"   <localleader>g    - Run glimpse() on word under cursor
"   <localleader>b    - Run dt() on word under cursor
"
" Ex Commands:
"   Core Operations:
"     :ROpenTerminal           - Open a new R terminal
"     :RSendLine               - Submit current line to R
"     :RSendSelection          - Send visual selection to R
"     :RSendFunction           - Send function block to R
"     :RSendSmart              - Smart auto-detection send
"     :RAddPipe                - Add pipe operator and new line
"   
"   Chunk Navigation & Execution:
"     :RNextChunk              - Move to next R Markdown chunk
"     :RPrevChunk              - Move to previous R Markdown chunk
"     :RSendChunk              - Send current chunk to R
"     :RSendPreviousChunks     - Send all previous chunks to R
"   
"   Object Inspection (optional arguments):
"     :RHead [object]          - Run head() on object or word under cursor
"     :RStr [object]           - Run str() on object or word under cursor
"     :RDim [object]           - Run dim() on object or word under cursor
"     :RPrint [object]         - Run print() on object or word under cursor
"     :RNames [object]         - Run names() on object or word under cursor
"     :RLength [object]        - Run length() on object or word under cursor
"     :RGlimpse [object]       - Run glimpse() on object or word under cursor
"     :RTail [object]          - Run tail() on object or word under cursor
"     :RHelp [topic]           - Get help on topic or word under cursor
"     :RSummary [object]       - Run summary() on object or word under cursor
"   
"   Control Commands:
"     :RQuit                   - Send Q to R terminal (quit)
"     :RInterrupt              - Send Ctrl-C to R terminal (interrupt)
"   
"   Advanced Commands:
"     :RSend {code}            - Send arbitrary R code
"     :RSource {file}          - Source R file
"     :RLibrary {package}      - Load library/package
"     :RInstall {package}      - Install package
"     :RLoad {file}            - Load RDS file (prompts for variable name)
"     :RSave {object} {file}   - Save object to RDS file
"   
"   Utility Commands:
"     :RSetwd [directory]      - Set working directory (defaults to Vim's cwd)
"     :RGetwd                  - Get current working directory
"     :RLs                     - List objects in workspace
"     :RRm                     - Remove all objects from workspace

"------------------------------------------------------------------------------
" Guard against multiple loading
"------------------------------------------------------------------------------
if exists('g:loaded_zzvim_r')
    finish
endif
let g:loaded_zzvim_r = 1

"------------------------------------------------------------------------------
" Configuration variables with defaults
"------------------------------------------------------------------------------
if !exists('g:zzvim_r_default_terminal')
    let g:zzvim_r_default_terminal = 'R'
endif

if !exists('g:zzvim_r_disable_mappings')
    let g:zzvim_r_disable_mappings = 0
endif

if !exists('g:zzvim_r_map_submit')
    let g:zzvim_r_map_submit = '<CR>'
endif

if !exists('g:zzvim_r_terminal_width')
    let g:zzvim_r_terminal_width = 100
endif
if !exists('g:zzvim_r_command')
    let g:zzvim_r_command = 'R --no-save --quiet'
endif

if !exists('g:zzvim_r_chunk_start')
    let g:zzvim_r_chunk_start = '^```{'
endif

if !exists('g:zzvim_r_chunk_end')
    let g:zzvim_r_chunk_end = '^```$'
endif

if !exists('g:zzvim_r_debug')
    let g:zzvim_r_debug = 0
endif

"------------------------------------------------------------------------------
" Utility Functions
"------------------------------------------------------------------------------
function! s:Log(msg, level) abort
    if g:zzvim_r_debug >= a:level
        call writefile([strftime('%c') . ' - ' . a:msg], expand('~/zzvim_r.log'), 'a')
        echom "Debug: " . a:msg
    endif
endfunction

function! s:Error(msg) abort
    echohl ErrorMsg
    echom "zzvim-R: " . a:msg
    echohl None
    call s:Log(a:msg, 1)
endfunction

"------------------------------------------------------------------------------
" Function: Open a new R terminal
"------------------------------------------------------------------------------
function! s:OpenRTerminal() abort
    if !executable('R')
        call s:Error('R is not installed or not in PATH')
        return
    endif

    " Open a vertical split and start the R terminal
    execute 'vertical term ' . g:zzvim_r_command
    execute 'vertical resize ' . g:zzvim_r_terminal_width

    " Set terminal-specific options
    setlocal norelativenumber nonumber signcolumn=no

    " Indicate that an R terminal is active
    let t:is_r_term = 1

    " Return focus to the previous window
    wincmd p
endfunction

"------------------------------------------------------------------------------
" Function: Send command to R terminal
"------------------------------------------------------------------------------
function! s:Send_to_r(cmd, stay_on_line) abort
    " Check if R terminal exists
    if !exists('t:is_r_term') || t:is_r_term != 1
        echohl WarningMsg
        echo "No R terminal open - creating new terminal and submitting line..."
        echohl None
        
        " Try to open R terminal
        call s:OpenRTerminal()
        
        " Verify terminal was created successfully
        if !exists('t:is_r_term') || t:is_r_term != 1
            call s:Error("Could not create R terminal. Please check R installation.")
            return
        endif
        
        " Small delay to ensure terminal is ready
        sleep 100m
    endif

    " Get available terminals
    let terms = term_list()
    if empty(terms)
        call s:Error("No active terminals found")
        return
    endif

    try
        let target_terminal = terms[0]
        " Skip empty commands
        if !empty(trim(a:cmd))
            " Validate terminal is still active
            if term_getstatus(target_terminal) =~# 'running'
                call term_sendkeys(target_terminal, a:cmd . "\n")
                " Add small delay for terminal handling
                sleep 10m
            else
                call s:Error("Terminal is not active")
                return
            endif
        endif
    catch
        call s:Error("Failed to send to R terminal: " . v:exception)
        return
    endtry

    if !a:stay_on_line
        normal! j
    endif
endfunction

function! s:GetVisualSelection() abort
    let [line_start, col_start] = getpos("'<")[1:2]
    let [line_end, col_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)

    " Trim the first and last lines to the selection
    let lines[-1] = lines[-1][: col_end - 1]
    let lines[0] = lines[0][col_start - 1:]

    return join(lines, "\n")
endfunction

"------------------------------------------------------------------------------
" Function: Add a pipe operator and create a new line
"------------------------------------------------------------------------------
function! s:AddPipeAndNewLine() abort
    call append(line('.'), ' %>%')
    normal! j
endfunction

"------------------------------------------------------------------------------
" Function: Move to the next R Markdown chunk
"------------------------------------------------------------------------------
function! s:MoveNextChunk() abort
    let chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{')
    let chunk_start = search(chunk_start_pattern, 'W')

    if chunk_start
        " Move the cursor to the first line inside the chunk
        if line('.') < line('$')
            normal! j
            echom "Moved inside the next chunk at line " . line('.')
        else
            call s:Error("Next chunk found, but no lines inside the chunk.")
        endif
    else
        call s:Error("No more chunks found.")
    endif
endfunction


"------------------------------------------------------------------------------
" Function: Move to the previous R Markdown chunk
"------------------------------------------------------------------------------
function! s:MovePrevChunk() abort
    " Get patterns for R code chunks from plugin config
    let chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{')
    
    " Save current position
    let current_pos = getpos('.')
    let current_line_num = line('.')
    
    " First, find the current chunk we might be in
    let current_chunk_start = search(chunk_start_pattern, 'bcnW')
    
    " If we're inside or at the start of the current chunk,
    " we need to move before this chunk to find the previous one
    if current_chunk_start > 0
        " If we're not at the chunk start itself, go to it first
        if current_line_num > current_chunk_start
            call cursor(current_chunk_start, 1)
        endif
        
        " Now go one line above the current chunk start to search
        if current_chunk_start > 1
            call cursor(current_chunk_start - 1, 1)
        endif
    endif
    
    " Now search for the previous chunk
    let prev_chunk_start = search(chunk_start_pattern, 'bW')
    
    if prev_chunk_start > 0
        " Move inside the chunk (to the line after the chunk header)
        call cursor(prev_chunk_start + 1, 1)
        normal! zz
        echom "Moved to previous chunk at line " . line('.')
        return 1
    else
        " No previous chunk found, restore position
        call setpos('.', current_pos)
        echom "No previous chunk found"
        return 0
    endif
endfunction


function! s:SubmitChunk() abort
    " Use the generalized function for chunk submission
    call s:SendToR('chunk')
    
    " Navigate to next chunk after submission (preserve original behavior)
    let save_pos = getpos('.')
    let chunk_end_pattern = get(g:, 'zzvim_r_chunk_end', '^```$')
    let chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{')
    
    let chunk_end = search(chunk_end_pattern, 'W')
    if chunk_end > 0
        call setpos('.', [0, chunk_end, 1, 0])
        let next_chunk_start = search(chunk_start_pattern, 'W')
        if next_chunk_start > 0
            let line_num = next_chunk_start
            let line_count = line('$')
            while line_num <= line_count
                let current_line = getline(line_num)
                if current_line !~# '^\s*$' && current_line !~# chunk_start_pattern 
                    \ && current_line !~# chunk_end_pattern
                    break
                endif
                let line_num += 1
            endwhile
            if line_num <= line_count
                call setpos('.', [0, line_num, 1, 0])
            endif
        endif
    else
        call setpos('.', save_pos)
    endif
endfunction

"------------------------------------------------------------------------------
" Mapping to Collect and Submit All Previous Chunks
"------------------------------------------------------------------------------

" Collect and submit all previous chunks to R
function! s:CollectAndSubmitPreviousChunks() abort
    " Use the generalized SendToR system for previous chunks
    call s:SendToR('previous_chunks')
endfunction

"------------------------------------------------------------------------------
" Function: Send control keys (e.g., 'Q' or Ctrl-C)
"------------------------------------------------------------------------------
function! s:SendControlKeys(key) abort
    try
        let terms = term_list()
        if empty(terms)
            call s:Error("No active terminals found.")
            return
        endif

        " Assume the first terminal in the list is the target
        let target_terminal = terms[0]
        " Use term_sendkeys to send the control key
        call term_sendkeys(target_terminal, a:key)
        echom "Sent control key: " . a:key
    catch
        call s:Error("Failed to send control key: " . a:key)
    endtry
endfunction

"------------------------------------------------------------------------------
" Function: Perform an R action on the word under the cursor
"------------------------------------------------------------------------------
function! s:RAction(action, stay_on_line) abort
    let word = expand('<cword>')
    if empty(word)
        call s:Error("No word under cursor.")
        return
    endif
    call s:Send_to_r(a:action . '(' . word . ')', a:stay_on_line)
    echom "Ran " . a:action . " on " . word . "."
endfunction

"------------------------------------------------------------------------------
" Function: Generalized text sending to R with smart detection
"------------------------------------------------------------------------------
function! s:SendToR(selection_type, ...) abort
    " Get text lines based on selection type or smart detection
    let text_lines = s:GetTextByType(a:selection_type)
    
    if empty(text_lines)
        call s:Error("No text to send to R.")
        return
    endif
    
    " Always use temp file approach for consistency
    let temp_file = tempname()
    call writefile(text_lines, temp_file)
    let cmd = "source('" . temp_file . "', echo=T)\n"
    call s:Send_to_r(cmd, 0)
    
    " Provide feedback about what was sent
    let line_count = len(text_lines)
    if line_count == 1
        echom "Sent 1 line to R."
    else
        echom "Sent " . line_count . " lines to R."
    endif
endfunction

"------------------------------------------------------------------------------
" Function: Extract text based on selection type with smart detection
"------------------------------------------------------------------------------
function! s:GetTextByType(selection_type) abort
    let current_line = getline('.')
    
    " Smart detection: check if current line starts a code block
    if s:IsBlockStart(current_line)
        return s:GetCodeBlock()
    endif
    
    " Use explicit selection type
    if a:selection_type ==# 'line'
        return [current_line]
    elseif a:selection_type ==# 'selection'
        return s:GetVisualSelectionLines()
    elseif a:selection_type ==# 'chunk'
        return s:GetCurrentChunk()
    elseif a:selection_type ==# 'previous_chunks'
        return s:GetPreviousChunks()
    elseif a:selection_type ==# 'function'
        return s:GetCodeBlock()
    else
        " Default to current line
        return [current_line]
    endif
endfunction

"------------------------------------------------------------------------------
" Function: Check if line starts a code block (function, control structure, etc.)
"------------------------------------------------------------------------------
function! s:IsBlockStart(line) abort
    " Single optimized regex to match all R block start patterns
    return a:line =~# '\v(.*function\s*\(|^\s*(if|for|while)\s*\(|^\s*(repeat\s*)?\{)'
endfunction

"------------------------------------------------------------------------------
" Function: Get complete code block by matching braces
"------------------------------------------------------------------------------
function! s:GetCodeBlock() abort
    let save_pos = getpos('.')
    let current_line_num = line('.')
    let current_line = getline('.')
    
    " Find the opening brace on current line or next lines
    let brace_line = current_line_num
    let found_opening = 0
    
    " Search for opening brace starting from current line
    while brace_line <= line('$')
        let line_content = getline(brace_line)
        if line_content =~ '{'
            let found_opening = 1
            break
        endif
        let brace_line += 1
        " Don't search too far
        if brace_line > current_line_num + 5
            break
        endif
    endwhile
    
    if !found_opening
        call setpos('.', save_pos)
        call s:Error("No opening brace found for code block.")
        return []
    endif
    
    " Find matching closing brace
    call cursor(brace_line, 1)
    let brace_count = 0
    let start_line = current_line_num
    let end_line = -1
    
    for line_num in range(brace_line, line('$'))
        let line_content = getline(line_num)
        
        " Count braces in this line
        let open_braces = len(substitute(line_content, '[^{]', '', 'g'))
        let close_braces = len(substitute(line_content, '[^}]', '', 'g'))
        
        let brace_count += open_braces - close_braces
        
        " When brace_count reaches 0, we found the matching closing brace
        if brace_count == 0 && (open_braces > 0 || close_braces > 0)
            let end_line = line_num
            break
        endif
    endfor
    
    call setpos('.', save_pos)
    
    if end_line == -1
        call s:Error("No matching closing brace found.")
        return []
    endif
    
    " Get lines from start to end (inclusive)
    return getline(start_line, end_line)
endfunction

"------------------------------------------------------------------------------
" Function: Get visual selection as lines
"------------------------------------------------------------------------------
function! s:GetVisualSelectionLines() abort
    " Reuse existing GetVisualSelection function and split into lines
    return split(s:GetVisualSelection(), '\n')
endfunction

"------------------------------------------------------------------------------
" Function: Get current chunk (reuse existing logic)
"------------------------------------------------------------------------------
function! s:GetCurrentChunk() abort
    let save_pos = getpos('.')
    let chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{')
    let chunk_end_pattern = get(g:, 'zzvim_r_chunk_end', '^```$')
    
    let chunk_start = search(chunk_start_pattern, 'bW')
    if chunk_start == 0
        call setpos('.', save_pos)
        return []
    endif
    let chunk_end = search(chunk_end_pattern, 'W')
    if chunk_end == 0
        call setpos('.', save_pos)
        return []
    endif
    
    call setpos('.', save_pos)
    return getline(chunk_start + 1, chunk_end - 1)
endfunction

"------------------------------------------------------------------------------
" Function: Get all previous chunks (reuse existing logic)
"------------------------------------------------------------------------------
function! s:GetPreviousChunks() abort
    " Get patterns for R code chunks from plugin config
    let l:chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{')
    let l:chunk_end_pattern = get(g:, 'zzvim_r_chunk_end', '^```$')
    
    " Get the current line number
    let l:current_line = line('.')
    
    " Initialize variables
    let l:all_chunk_lines = []
    let l:inside_chunk = 0
    
    " Loop through lines up to the current line (exclusive)
    for l:line_num in range(1, l:current_line - 1)
        let l:line_content = getline(l:line_num)
        
        " Check if the line is a chunk start
        if l:line_content =~ l:chunk_start_pattern
            let l:inside_chunk = 1
            continue
        endif
        
        " Check if the line is a chunk end
        if l:line_content =~ l:chunk_end_pattern
            let l:inside_chunk = 0
            continue
        endif
        
        " If inside a chunk, collect the line
        if l:inside_chunk
            call add(l:all_chunk_lines, l:line_content)
        endif
    endfor
    
    " Return the collected lines as array (for consistency with other GetText functions)
    return l:all_chunk_lines
endfunction

"------------------------------------------------------------------------------
" Function: Smart submission - uses generalized function with auto-detection
"------------------------------------------------------------------------------
function! s:SmartSubmit() abort
    " Use smart detection (empty string triggers auto-detection)
    call s:SendToR('')
endfunction

"------------------------------------------------------------------------------
" Function: Visual selection submission using generalized function
"------------------------------------------------------------------------------  
function! s:SendVisualToRGeneralized() abort
    call s:SendToR('selection')
endfunction


"------------------------------------------------------------------------------
" Mappings
"------------------------------------------------------------------------------
"
"
"
if !g:zzvim_r_disable_mappings
    augroup zzvim_RMarkdown
        autocmd!
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>r  :call <SID>OpenRTerminal()<CR>
        autocmd FileType r,rmd,qmd xnoremap <buffer> <silent> <CR>    :<C-u>call <SID>SendVisualToRGeneralized()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <CR>  :call <SID>SmartSubmit()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>o   :call <SID>AddPipeAndNewLine()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>j   :call <SID>MoveNextChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>k :call <SID>MovePrevChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>l :call <SID>SubmitChunk()<CR>zz
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>t :call <SID>CollectAndSubmitPreviousChunks()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>q :call <SID>SendControlKeys("Q")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>c :call <SID>SendControlKeys("\<C-c>")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>d :call <SID>RAction("dim", 1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>h :call <SID>RAction("head",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>u :call <SID>RAction("tail",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>s :call <SID>RAction("str",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p :call <SID>RAction("print",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>n :call <SID>RAction("names",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>f :call <SID>RAction("length",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>g :call <SID>RAction("glimpse",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>b :call <SID>RAction("dt",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>y :call <SID>RAction("help", 1)<CR>
        " Additional generalized send mappings
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>sf :call <SID>SendToR('function')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>sl :call <SID>SendToR('line')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>sa :call <SID>SendToR('')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>sp :call <SID>SendToR('previous_chunks')<CR>
    augroup END
endif

"------------------------------------------------------------------------------
" Ex Commands
"------------------------------------------------------------------------------

" Core Operations
command! ROpenTerminal call s:OpenRTerminal()
command! RSendLine call s:SendToR('line')
command! RSendSelection call s:SendVisualToRGeneralized()
command! RSendFunction call s:SendToR('function')
command! RSendSmart call s:SendToR('')
command! RAddPipe call s:AddPipeAndNewLine()

" Chunk Navigation and Execution
command! RNextChunk call s:MoveNextChunk()
command! RPrevChunk call s:MovePrevChunk()
command! RSendChunk call s:SendToR('chunk')
command! RSendPreviousChunks call s:SendToR('previous_chunks')

" Object Inspection Commands (with optional arguments)
command! -nargs=? RHead call s:RCommandWithArg('head', <q-args>)
command! -nargs=? RStr call s:RCommandWithArg('str', <q-args>)
command! -nargs=? RDim call s:RCommandWithArg('dim', <q-args>)
command! -nargs=? RPrint call s:RCommandWithArg('print', <q-args>)
command! -nargs=? RNames call s:RCommandWithArg('names', <q-args>)
command! -nargs=? RLength call s:RCommandWithArg('length', <q-args>)
command! -nargs=? RGlimpse call s:RCommandWithArg('glimpse', <q-args>)
command! -nargs=? RTail call s:RCommandWithArg('tail', <q-args>)
command! -nargs=? RHelp call s:RCommandWithArg('help', <q-args>)
command! -nargs=? RSummary call s:RCommandWithArg('summary', <q-args>)

" Control Commands
command! RQuit call s:SendControlKeys("Q")
command! RInterrupt call s:SendControlKeys("\<C-c>")

" Advanced Commands with Argument Handling
command! -nargs=1 RSend call s:RSendCommand(<q-args>)
command! -nargs=1 RSource call s:RSourceCommand(<q-args>)
command! -nargs=1 RLibrary call s:RLibraryCommand(<q-args>)
command! -nargs=1 RInstall call s:RInstallCommand(<q-args>)
command! -nargs=1 RLoad call s:RLoadCommand(<q-args>)
command! -nargs=1 RSave call s:RSaveCommand(<q-args>)

" Utility Commands
command! -nargs=? RSetwd call s:RSetwdCommand(<q-args>)
command! RGetwd call s:Send_to_r('getwd()', 1)
command! RLs call s:Send_to_r('ls()', 1)
command! RRm call s:Send_to_r('rm(list=ls())', 1)

"------------------------------------------------------------------------------
" Helper Functions for Commands
"------------------------------------------------------------------------------

" Generic function for R commands that can take optional arguments
function! s:RCommandWithArg(action, arg) abort
    if empty(a:arg)
        " Use word under cursor if no argument provided
        let word = expand('<cword>')
        if empty(word)
            call s:Error("No argument provided and no word under cursor for " . a:action . "()")
            return
        endif
        let target = word
    else
        let target = a:arg
    endif
    
    call s:Send_to_r(a:action . '(' . target . ')', 1)
    echom "Executed " . a:action . "(" . target . ")"
endfunction

" Send arbitrary R code
function! s:RSendCommand(code) abort
    if empty(a:code)
        call s:Error("No R code provided")
        return
    endif
    call s:Send_to_r(a:code, 0)
    echom "Sent: " . a:code
endfunction

" Source an R file
function! s:RSourceCommand(file) abort
    if empty(a:file)
        call s:Error("No file path provided")
        return
    endif
    
    " Handle relative paths and expand ~
    let expanded_file = expand(a:file)
    call s:Send_to_r("source('" . expanded_file . "')", 0)
    echom "Sourced: " . expanded_file
endfunction

" Load a library/package
function! s:RLibraryCommand(package) abort
    if empty(a:package)
        call s:Error("No package name provided")
        return
    endif
    call s:Send_to_r('library(' . a:package . ')', 0)
    echom "Loaded library: " . a:package
endfunction

" Install a package
function! s:RInstallCommand(package) abort
    if empty(a:package)
        call s:Error("No package name provided")
        return
    endif
    call s:Send_to_r("install.packages('" . a:package . "')", 0)
    echom "Installing package: " . a:package
endfunction

" Load RDS file
function! s:RLoadCommand(file) abort
    if empty(a:file)
        call s:Error("No file path provided")
        return
    endif
    
    let expanded_file = expand(a:file)
    let var_name = input("Variable name (or press Enter for auto): ")
    
    if empty(var_name)
        " Generate variable name from filename
        let var_name = fnamemodify(expanded_file, ':t:r')
        let var_name = substitute(var_name, '[^a-zA-Z0-9_]', '_', 'g')
    endif
    
    call s:Send_to_r(var_name . " <- readRDS('" . expanded_file . "')", 0)
    echom "Loaded " . expanded_file . " into " . var_name
endfunction

" Save to RDS file
function! s:RSaveCommand(args) abort
    if empty(a:args)
        call s:Error("Usage: RSave object filename")
        return
    endif
    
    let parts = split(a:args)
    if len(parts) < 2
        call s:Error("Usage: RSave object filename")
        return
    endif
    
    let object = parts[0]
    let filename = join(parts[1:])
    let expanded_file = expand(filename)
    
    call s:Send_to_r("saveRDS(" . object . ", '" . expanded_file . "')", 0)
    echom "Saved " . object . " to " . expanded_file
endfunction

" Set working directory
function! s:RSetwdCommand(dir) abort
    if empty(a:dir)
        " Use current Vim directory if no argument
        let target_dir = getcwd()
    else
        let target_dir = expand(a:dir)
    endif
    
    call s:Send_to_r("setwd('" . target_dir . "')", 0)
    echom "Set R working directory to: " . target_dir
endfunction
