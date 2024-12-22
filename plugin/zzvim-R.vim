" zzvim-R.vim - R development plugin for Vim
" Maintainer:  [Your Name] <email>
" Version:     1.0
" License:     VIM License
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
"   Sets the default terminal name for R sessions
"   Default: 'R'
"   Example: let g:zzvim_r_default_terminal = 'R-4.1'
"
" g:zzvim_r_disable_mappings    (boolean)
"   If set to 1, disables all default key mappings
"   Default: 0
"   Example: let g:zzvim_r_disable_mappings = 1
"
" g:zzvim_r_map_submit         (string)
"   Sets the key mapping for submitting lines to R
"   Default: '<CR>' (Enter key)
"   Example: let g:zzvim_r_map_submit = '<Leader>s'
"
" Default Mappings (when g:zzvim_r_disable_mappings = 0):
"   <CR>              - Submit current line to R
"   <localleader>z    - Submit visual selection
"   <localleader>o    - Add pipe operator and new line
"   <localleader>j    - Move to next chunk
"   <localleader>k    - Move to previous chunk
"   <localleader>l    - Select and submit current chunk
"   <localleader>'    - Submit all previous chunks
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
" Commands:
"   :RSubmitLine      - Submit current line to R
"   :RNextChunk       - Move to next chunk
"   :RPrevChunk       - Move to previous chunk
"   :RSelectChunk     - Select current chunk
"   :RSubmitChunks    - Submit all previous chunks

" Guard against multiple loading
if exists('g:loaded_zzvim_r')
    finish
endif
let g:loaded_zzvim_r = 1

" Configuration variables with defaults
if !exists('g:zzvim_r_default_terminal')
    let g:zzvim_r_default_terminal = 'R'
endif

if !exists('g:zzvim_r_disable_mappings')
    let g:zzvim_r_disable_mappings = 0
endif

if !exists('g:zzvim_r_map_submit')
    let g:zzvim_r_map_submit = '<CR>'
endif

" Script-local variables
let s:source_file = ''
let s:last_command_time = ''

"------------------------------------------------------------------------------
" Utility Functions
"------------------------------------------------------------------------------
" Function to create a new R terminal
function! s:OpenRTerminal() abort
    " Check if R is installed
    if !executable('R')
        call s:Error('R is not installed or not in PATH')
        return
    endif

    " Check if a terminal with R is already running
    let terms = term_list()
    for term in terms
        if match(term_getline(term, 1), 'R version') != -1
            call s:Error('R terminal is already running')
            " Switch to the existing R terminal
            call win_gotoid(win_findbuf(term)[0])
            return
        endif
    endfor

    " Save current window ID
    let current_window = win_getid()

    " Open vertical split for R terminal only
    let width = get(g:, 'zzvim_r_terminal_width', 80)
    execute 'vertical rightbelow ' . width . ' new'

    " Start R with common startup flags in the new buffer
    let r_cmd = get(g:, 'zzvim_r_command', 'R --no-save --quiet')
    execute 'terminal ' . r_cmd

    " Set terminal window options
    setlocal nobuflisted
    setlocal nonumber
    setlocal norelativenumber
    setlocal signcolumn=no
    let t:is_r_term = 1

    " Return focus to the original buffer
    call win_gotoid(current_window)
endfunction
" Check if terminal feature is available and R terminal exists
" Returns: boolean
function! s:has_r_terminal() abort
    if !has('terminal')
        call s:Error("Terminal feature not available in this Vim version")
        return 0
    endif
    try
        return !empty(term_list())
    catch
        call s:Error("Error checking R terminal: " . v:exception)
        return 0
    endtry
endfunction

" Display consistent error messages
" Args: msg (string) - Error message to display
function! s:Error(msg) abort
    echohl ErrorMsg
    echom "zzvim-R: " . a:msg
    echohl None
endfunction

" Choose a terminal from available terminals
" Args: terms (list) - List of terminal buffers
" Returns: terminal buffer number or -1 if cancelled
function! s:choose_terminal(terms) abort
    let choices = ['Cancel'] + map(copy(a:terms), 'bufname(v:val)')
    let choice = inputlist(choices)
    return choice == 0 ? -1 : a:terms[choice - 1]
endfunction

" Send command to R terminal
" Args: cmd (string) - Command to send
function! s:send_to_r(cmd) abort
    if !s:has_r_terminal()
        call s:Error("No R terminal available. Open one with <localleader>r.")
        return
    endif
    try
        let terms = term_list()
        let target_terminal = len(terms) == 1 ? terms[0] : s:choose_terminal(terms)
        if target_terminal == -1
            call s:Error("Command canceled.")
            return
        endif
        let s:last_command_time = strftime('%H:%M:%S')
        call term_sendkeys(target_terminal, a:cmd)
        let &statusline .= ' [R cmd: ' . s:last_command_time . ']'
        echom "Command sent to terminal buffer: " . target_terminal
    catch
        call s:Error("Error sending command to R terminal: " . v:exception)
    endtry
endfunction

"------------------------------------------------------------------------------
" Core Functions
"------------------------------------------------------------------------------

" Submit current line to R terminal and move cursor down
" Returns: void
function! s:SubmitLine() abort
    call s:send_to_r(getline(".") . "\n")
    normal! j
endfunction

" Execute R action on word under cursor
" Args: action (string) - R function name to execute
function! s:Raction(action) abort
    let current_word = expand("<cword>")
    call s:send_to_r(a:action . "(" . current_word . ")\n")
endfunction

" Send control keys to R terminal
" Args: key (string) - Control key sequence
function! s:SendControlKeys(key) abort
    call s:send_to_r(a:key)
endfunction

" Add pipe operator and create new line
function! s:AddPipeAndNewLine() abort
    normal! A |>
    normal! o
    execute "normal! i  "
endfunction

" Get visual selection and save to temporary file
function! s:Sel() abort
    let visual_selection = s:GetVisualSelection(visualmode())
    if visual_selection == ''
        return
    endif
    let s:source_file = tempname()
    call writefile(split(visual_selection, "\n"), s:source_file)
endfunction

" Submit saved source file to R
function! s:Submit() abort
    if empty(s:source_file)
        call s:Error("No source file available.")
        return
    endif
    let cmd = "source('" . s:source_file . "', echo=T)\n"
    call s:send_to_r(cmd)
endfunction

" Submit visual selection to R
function! s:SubmitVisualSelection() abort
    let selection = s:GetVisualSelection(visualmode())
    if !empty(selection)
        call s:send_to_r(selection . "\n")
    else
        call s:Error("No visual selection to submit.")
    endif
endfunction

" Get visual selection with support for all modes
" Args: mode (string) - Visual mode type
" Returns: string - Selected text
function! s:GetVisualSelection(mode) abort
    let [line_start, col_start] = getpos("'<")[1:2]
    let [line_end, col_end] = getpos("'>")[1:2]
    
    if a:mode ==# "\<C-v>"  " Block mode
        let lines = []
        for lnum in range(line_start, line_end)
            let line = getline(lnum)
            let lines += [line[col_start-1 : col_end-1]]
        endfor
        return join(lines, "\n")
    elseif a:mode ==# 'v'
        let lines = getline(line_start, line_end)
        let lines[-1] = lines[-1][: col_end - (&selection == 'inclusive' ? 1 : 2)]
        let lines[0] = lines[0][col_start - 1:]
        return join(lines, "\n")
    elseif a:mode ==# 'V'
        return join(getline(line_start, line_end), "\n")
    else
        call s:Error("Unsupported visual mode")
        return ''
    endif
endfunction

"------------------------------------------------------------------------------
" Selection and Navigation Functions
"------------------------------------------------------------------------------

" Select current R Markdown chunk
function! s:SelectChunk() abort
    let save_pos = getpos('.')
    if search('^```{', 'bW')
        normal! j
        normal! V
        if search('^```$', 'W')
            normal! k
        else
            call s:Error("No matching closing backticks found.")
            call setpos('.', save_pos)
            normal! <Esc>
        endif
    else
        call s:Error("No R Markdown chunks found above.")
        call setpos('.', save_pos)
    endif
endfunction

" Move to next chunk
function! s:MoveNextChunk() abort
    let save_pos = getpos('.')
    if !search('```{', 'W')
        call setpos('.', save_pos)
        call s:Error("No further chunks found.")
        return
    endif
    normal! j
    noh
endfunction

" Move to previous chunk
function! s:MovePrevChunk() abort
    let save_pos = getpos('.')
    let opening = '^\s*```{.*'
    let closing = '^\s*```$'
    while line('.') > 1 && (getline('.') =~ opening || getline('.') =~ closing)
        normal! k
    endwhile
    if search(opening, 'bW') > 0
        normal! j
    else
        call setpos('.', save_pos)
        call s:Error("No previous chunk found.")
    endif
    noh
endfunction

"------------------------------------------------------------------------------
" Chunk Collection and Submission
"------------------------------------------------------------------------------

" Collect all chunks above current position
" Returns: string - Concatenated chunk content
function! s:CollectPreviousChunks() abort
    let chunk_start = '^\s*```{.*'
    let chunk_end = '^\s*```$'
    let chunk_count = line('.') / 2  " Estimate
    let all_chunks = []
    call extend(all_chunks, repeat([''], chunk_count))
    let inside_chunk = 0
    let chunk_index = 0

    for line_num in range(1, line('.'))
        let line_content = getline(line_num)
        if line_content =~ chunk_start
            let inside_chunk = 1
            continue
        endif
        if line_content =~ chunk_end
            let inside_chunk = 0
            continue
        endif
        if inside_chunk
            let all_chunks[chunk_index] = line_content
            let chunk_index += 1
        endif
    endfor

    return join(filter(all_chunks, '!empty(v:val)'), "\n")
endfunction

" Collect and submit all previous chunks
function! s:CollectAndSubmitPreviousChunks() abort
    let previous_chunks = s:CollectPreviousChunks()
    if empty(previous_chunks)
        call s:Error("No previous chunks to submit.")
        return
    endif
    call s:send_to_r(previous_chunks . "\n")
    echom "Submitted previous chunks."
endfunction

"------------------------------------------------------------------------------
" Commands
"------------------------------------------------------------------------------

command! -nargs=0 RSubmitLine call <SID>SubmitLine()
command! -nargs=0 RNextChunk call <SID>MoveNextChunk()
command! -nargs=0 RPrevChunk call <SID>MovePrevChunk()
command! -nargs=0 RSelectChunk call <SID>SelectChunk()
command! -nargs=0 RSubmitChunks call <SID>CollectAndSubmitPreviousChunks()

"------------------------------------------------------------------------------
" Mappings
"------------------------------------------------------------------------------

if !g:zzvim_r_disable_mappings
    augroup zzvim_RMarkdown
        autocmd!
autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>r 
            \ :call <SID>OpenRTerminal()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <CR> 
\ :call <SID>SubmitLine()<CR>
        autocmd FileType r,rmd,qmd xnoremap <buffer> <silent> <localleader>z 
\ :call <SID>Sel() | 
\ :call <SID>Submit()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>o 
\ :call <SID>AddPipeAndNewLine()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>j 
\ :call <SID>MoveNextChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>k 
\ :call <SID>MovePrevChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>l 
\ :call <SID>SelectChunk()<CR> | :call <SID>Sel() |  :call <SID>Submit()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>' 
\ :call <SID>CollectAndSubmitPreviousChunks()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>q 
\ :call <SID>SendControlKeys("Q")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>c 
\ :call <SID>SendControlKeys("\<C-c>")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>d 
\ :call <SID>Raction("dim")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>h 
\ :call <SID>Raction("head")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>s 
\ :call <SID>Raction("str")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p 
\ :call <SID>Raction("print")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>n 
\ :call <SID>Raction("names")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>f 
\ :call <SID>Raction("length")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>g 
\ :call <SID>Raction("glimpse")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>b 
\ :call <SID>Raction("dt")<CR>
    augroup END
endif

