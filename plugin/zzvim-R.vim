" script3 - R development plugin for Vim
" Maintainer:  [Your Name] <email>
" Version:     1.2
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
" g:zzvim_r_terminal_width      (number)
"   Sets the width of the R terminal in the vertical split
"   Default: 80
"
" g:zzvim_r_command             (string)
"   The command to start the R terminal
"   Default: 'R --no-save --quiet'
"
" g:zzvim_r_debug               (boolean)
"   Enables debug mode with logging to ~/zzvim_r.log
"   Default: 0
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

"------------------------------------------------------------------------------
" Guard against multiple loading
"------------------------------------------------------------------------------
if exists('g:loaded_script3')
    finish
endif
let g:loaded_script3 = 1

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

if !exists('g:zzvim_r_terminal_width')
    let g:zzvim_r_terminal_width = 80
endif

if !exists('g:zzvim_r_command')
    let g:zzvim_r_command = 'R --no-save --quiet'
endif

if !exists('g:zzvim_r_debug')
    let g:zzvim_r_debug = 0
endif

" Script-local variables
let s:last_command_time = ''

"------------------------------------------------------------------------------
" Utility Functions
"------------------------------------------------------------------------------

"==============================================================================
" Log debug messages to a file
"==============================================================================
function! s:Log(msg) abort
    if g:zzvim_r_debug
        call writefile([strftime('%c') . ' - ' . a:msg], expand('~/zzvim_r.log'), 'a')
        echom "Debug: " . a:msg
    endif
endfunction

"==============================================================================
" Display error messages consistently
"==============================================================================
function! s:Error(msg) abort
    echohl ErrorMsg
    echom "zzvim-R: " . a:msg
    echohl None
    call s:Log(a:msg)
endfunction

"==============================================================================
" Open a new R terminal
"==============================================================================
function! s:OpenRTerminal() abort
    if !executable('R')
        call s:Error('R is not installed or not in PATH')
        return
    endif

    let terms = term_list()
    for term in terms
        if match(term_getline(term, 1), 'R version') != -1
            call s:Error('R terminal is already running')
            call win_gotoid(win_findbuf(term)[0])
            return
        endif
    endfor

    let current_window = win_getid()
    execute 'vertical rightbelow ' . g:zzvim_r_terminal_width . 'vsplit'
    execute 'terminal ' . g:zzvim_r_command

    setlocal nobuflisted nonumber norelativenumber signcolumn=no
    let t:is_r_term = 1

    call win_gotoid(current_window)
endfunction

"==============================================================================
" Check if R terminal exists
"==============================================================================
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

"==============================================================================
" Send command to R terminal
"==============================================================================
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
        call term_sendkeys(target_terminal, a:cmd . "\n")
        echom "Command sent to terminal buffer: " . target_terminal
        let &statusline .= ' [R cmd: ' . s:last_command_time . ']'
    catch
        call s:Error("Error sending command to R terminal: " . v:exception)
    endtry
endfunction

"==============================================================================
" Submit the current R Markdown chunk to the R terminal
"==============================================================================
function! s:SubmitChunk() abort
    let save_pos = getpos('.')

    " Find the start of the chunk
    if search('^```{', 'bW') == 0
        call s:Error("No R Markdown chunk found above the current line.")
        call setpos('.', save_pos)
        return
    endif
    let start_line = line('.')

    " Find the end of the chunk
    if search('^```$', 'W') == 0
        call s:Error("No closing backticks for the chunk found.")
        call setpos('.', save_pos)
        return
    endif
    let end_line = line('.')

    " Extract lines within the chunk
    let chunk_lines = getline(start_line, end_line)

    " Submit the chunk to R
    call s:send_to_r(join(chunk_lines, "\n"))
    call setpos('.', save_pos)
    echom "Submitted current chunk to R terminal."
endfunction
"------------------------------------------------------------------------------
" Commands
"------------------------------------------------------------------------------
command! -nargs=0 RSubmitLine call <SID>SubmitLine()
command! -nargs=0 RNextChunk call <SID>MoveNextChunk()
command! -nargs=0 RPrevChunk call <SID>MovePrevChunk()
command! -nargs=0 RSelectChunk call <SID>SelectChunk()
command! -nargs=0 RSubmitChunks call <SID>CollectAndSubmitPreviousChunks()
"==============================================================================
" Submit visual selection to R terminal
"==============================================================================
function! s:SubmitVisualSelection() abort
    let selection = s:GetVisualSelection(visualmode())
    if empty(selection)
        call s:Error("No visual selection to submit.")
        return
    endif
    call s:send_to_r(selection)
endfunction

"==============================================================================
" Get visual selection based on mode
"==============================================================================
function! s:GetVisualSelection(mode) abort
    let [line_start, col_start] = getpos("'<")[1:2]
    let [line_end, col_end] = getpos("'>")[1:2]
    if a:mode ==# "\<C-v>"
        let lines = []
        for lnum in range(line_start, line_end)
            let line = getline(lnum)
            call add(lines, line[col_start-1 : col_end-1])
        endfor
        return join(lines, "\n")
    elseif a:mode ==# 'v'
        let lines = getline(line_start, line_end)
        let lines[0] = lines[0][col_start - 1:]
        let lines[-1] = lines[-1][:col_end - 1]
        return join(lines, "\n")
    elseif a:mode ==# 'V'
        return join(getline(line_start, line_end), "\n")
    else
        call s:Error("Unsupported visual mode")
        return ''
    endif
endfunction
"==============================================================================
" Submit visual selection to R terminal
"==============================================================================
function! s:SubmitVisualSelection() abort
    let selection = s:GetVisualSelection(visualmode())
    if empty(selection)
        call s:Error("No visual selection to submit.")
        return
    endif
    call s:send_to_r(selection)
endfunction

"==============================================================================
" Send visual selection to R terminal and return results as comments
"==============================================================================
function! s:SubmitVisualSelectionWithComment() abort
    let selection = s:GetVisualSelection(visualmode())
    if empty(selection)
        call s:Error("No visual selection to process.")
        return
    endif

    " Send the selection to R
    call s:send_to_r(selection)

    " Mock receiving the result from R (as we cannot directly fetch terminal output)
    let result = "# Simulated R output for: " . substitute(selection, "\n", "; ", "g")

    " Insert result into buffer as an R comment
    let pos = getpos("'>")  " End of visual selection
    call setline(pos[1] + 1, split(result, "\n"))
    echom "Results inserted as R comments."
endfunction
"------------------------------------------------------------------------------
" Mappings
"------------------------------------------------------------------------------
if !g:zzvim_r_disable_mappings
    augroup zzvim_RMarkdown
        autocmd!
        " Mapping to open R terminal
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>r :call <SID>OpenRTerminal()<CR>

        " Mapping to submit the current line to R
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <CR> :call <SID>SubmitLine()<CR>

        " Mapping to submit the current visual selection to R
        autocmd FileType r,rmd,qmd xnoremap <buffer> <silent> <CR> :call <SID>SubmitVisualSelection()<CR>

        " Mapping to add a pipe operator and create a new line
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>o :call <SID>AddPipeAndNewLine()<CR>

        " Mapping to move to the next R Markdown chunk
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>j :call <SID>MoveNextChunk()<CR>

        " Mapping to move to the previous R Markdown chunk
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>k :call <SID>MovePrevChunk()<CR>

        " Mapping to select the current R Markdown chunk and submit the selection
autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>l :call <SID>SubmitChunk()<CR>

        " Mapping to submit all previous R Markdown chunks
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>t :call <SID>CollectAndSubmitPreviousChunks()<CR>

        " Mapping to send 'Q' to the R terminal
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>q :call <SID>SendControlKeys("Q")<CR>

        " Mapping to send Ctrl-C to the R terminal
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>c :call <SID>SendControlKeys("\<C-c>")<CR>

        " Mapping to run dim() on the word under the cursor
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>d :call <SID>Raction("dim")<CR>

        " Mapping to run head() on the word under the cursor
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>h :call <SID>Raction("head")<CR>

        " Mapping to run str() on the word under the cursor
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>s :call <SID>Raction("str")<CR>

        " Mapping to run print() on the word under the cursor
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p :call <SID>Raction("print")<CR>

        " Mapping to run names() on the word under the cursor
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>n :call <SID>Raction("names")<CR>

        " Mapping to run length() on the word under the cursor
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>f :call <SID>Raction("length")<CR>

        " Mapping to run glimpse() on the word under the cursor
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>g :call <SID>Raction("glimpse")<CR>

        " Mapping to run dt() on the word under the cursor
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>b :call <SID>Raction("dt")<CR>
    augroup END
endif
