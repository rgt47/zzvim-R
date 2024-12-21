" zzvim-R.vim
" A Vim plugin for working with R and R Markdown files, sending code to an R terminal.
" Namespace: zzvim
" Author: [Your Name]
" Description: Provides functionality for navigating and executing R code in R and R Markdown files.

"------------------------------------------------------------------------------
" User Configurable Options
"------------------------------------------------------------------------------
if !exists("g:zzvim_config")
    let g:zzvim_config = {}
endif

" Temporary file for storing output
let g:zzvim_config.temp_file = get(g:zzvim_config, 'temp_file', 'temp.txt')

"------------------------------------------------------------------------------
" Utility Functions (script-local)
"------------------------------------------------------------------------------

" Check if an R terminal is available
" Returns 1 if a terminal is available, 0 otherwise.
function! s:has_r_terminal() abort
    try
        let terms = term_list()
        return !empty(terms)
    catch
        echoerr "Error checking R terminal: " . v:exception
        return 0
    endtry
endfunction

" Send commands to the R terminal safely
" Arguments:
"   a:cmd (string): The command to send to the R terminal.
" Returns: None
function! s:send_to_r(cmd) abort
    if !s:has_r_terminal()
        echoerr "No R terminal available."
        return
    endif
    let terms = term_list()
    call term_sendkeys(terms[0], a:cmd)
endfunction

"------------------------------------------------------------------------------
" Core Functions
"------------------------------------------------------------------------------

" Get the visual selection from the current buffer
" Arguments:
"   a:mode (string): Visual mode ('v' for character, 'V' for line).
" Returns:
"   (string) The selected text joined by newlines.
function! s:GetVisualSelection(mode) abort
    let [line_start, col_start] = getpos("'<")[1:2]
    let [line_end, col_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)

    if a:mode ==# 'v'
        let lines[-1] = lines[-1][: col_end - (&selection == 'inclusive' ? 1 : 2)]
        let lines[0] = lines[0][col_start - 1:]
    elseif a:mode ==# 'V'
        " Line-wise selection, no trimming needed
    else
        echoerr "Unsupported visual mode."
        return ''
    endif

    return join(lines, "\n")
endfunction

" Select an R Markdown chunk
" Highlights the chunk containing the cursor.
" Moves to the chunk's start and end delimiters (` ```{` and ` ``` `).
function! s:SelectChunk() abort
    if search('^```{', 'bW')
        normal! j
        normal! V
        if search('^```$', 'W')
            normal! k
        else
            echoerr "No matching closing backticks found."
            normal! <Esc>
        endif
    else
        echoerr "No R Markdown chunks found above."
    endif
    normal! <Esc>
endfunction

" Move to the next chunk
function! s:MoveNextChunk() abort
    if search('^```{', 'W')
        normal! j
    else
        echo "No further chunks found."
    endif
    noh
endfunction

" Move to the previous chunk
function! s:MovePrevChunk() abort
    let l:opening_delimiter = '^\s*```{.*'
    let l:closing_delimiter = '^\s*```$'

    while line('.') > 1 && (getline('.') =~ l:opening_delimiter || getline('.') =~ l:closing_delimiter)
        normal! k
    endwhile

    let l:found = search(l:opening_delimiter, 'bW')

    if l:found > 0
        execute l:found + 1 . "normal! 0"
    else
        echo "No previous chunk found."
    endif

    noh
endfunction

" Collect all previous chunks
function! s:CollectPreviousChunks() abort
    let l:chunk_lines = []
    let l:start = searchpair('^\s*```{.*', '', '^\s*```$', 'bnW', '', 0, 0)
    while l:start > 0
        let l:end = search('^\s*```$', 'nW', l:start)
        if l:end > 0
            call extend(l:chunk_lines, getline(l:start + 1, l:end - 1))
            let l:start = searchpair('^\s*```{.*', '', '^\s*```$', 'bnW', '', 0, l:start - 1)
        else
            break
        endif
    endwhile
    return join(l:chunk_lines, "\n")
endfunction

"------------------------------------------------------------------------------
" Check and Submit Functions
"------------------------------------------------------------------------------

" Submit the current line to the R terminal
function! s:SubmitLine() abort
    call s:send_to_r(getline(".") . "\n")
endfunction

" Submit all previous chunks to R
function! zzvim#SubmitPreviousChunks() abort
    let chunks = s:CollectPreviousChunks()
    if empty(chunks)
        echo "No previous chunks to submit."
        return
    endif
    call s:send_to_r(chunks . "\n")
    echo "Submitted previous chunks."
endfunction

"------------------------------------------------------------------------------
" Autocommands and Mappings
"------------------------------------------------------------------------------

augroup zzvim_RMarkdown
    autocmd!
    " Submit line in normal mode
    autocmd FileType r,rmd,qmd nnoremap <buffer> <CR> :call zzvim#SubmitLine()<CR>

    " Navigate chunks
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>j :call zzvim#MoveNextChunk()<CR>
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>k :call zzvim#MovePrevChunk()<CR>

    " Submit all previous chunks
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>' :call zzvim#SubmitPreviousChunks()<CR>
augroup END
