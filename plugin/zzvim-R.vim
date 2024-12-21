" zzvim-R.vim
" A Vim plugin for working with R and R Markdown files, sending code to an R terminal.

"------------------------------------------------------------------------------
" User Configurable Options
"------------------------------------------------------------------------------
let g:zzvim_config = extend({
    \ 'temp_file': 'temp.txt',
    \ 'chunk_delimiter': '^\s*```{.*',
    \ }, get(g:, 'zzvim_config', {}))

"------------------------------------------------------------------------------
" Utility Functions (script-local)
"------------------------------------------------------------------------------

" Check if an R terminal is available
function! s:has_r_terminal() abort
    try
        return !empty(term_list())
    catch
        echom "Error checking R terminal: " . v:exception
        return 0
    endtry
endfunction

" Send commands to the R terminal safely
function! s:send_to_r(cmd) abort
    if !s:has_r_terminal()
        echom "No R terminal available."
        return
    endif
    call term_sendkeys(term_list()[0], a:cmd)
endfunction

"------------------------------------------------------------------------------
" Core Functions
"------------------------------------------------------------------------------

" Open an R terminal
function! OpenRTerminal() abort
    execute "vert term R --no-save"
    execute "normal! \<C-w>p"  " Return to the previous window
    echom "R terminal opened."
endfunction

" Submit the current line to the R terminal
function! SubmitLine() abort
    call s:send_to_r(getline(".") . "\n")
endfunction

" Submit the visual selection to the R terminal
function! SubmitVisualSelection() abort
    let selection = s:GetVisualSelection(visualmode())
    if !empty(selection)
        call s:send_to_r(selection . "\n")
    else
        echom "No visual selection to submit."
    endif
endfunction

" Collect all previous chunks
function! s:CollectPreviousChunks() abort
    let l:chunk_start_delimiter = g:zzvim_config.chunk_delimiter
    let l:chunk_end_delimiter = '^\s*```$'
    let l:all_chunk_lines = []
    let l:inside_chunk = 0

    for l:line in range(1, line('.'))
        let l:current_content = getline(l:line)
        if l:current_content =~ l:chunk_start_delimiter
            let l:inside_chunk = 1
            continue
        endif
        if l:current_content =~ l:chunk_end_delimiter
            let l:inside_chunk = 0
            continue
        endif
        if l:inside_chunk
            call add(l:all_chunk_lines, l:current_content)
        endif
    endfor
    return join(l:all_chunk_lines, "\n")
endfunction

" Submit all previous chunks to the R terminal
function! SubmitPreviousChunks() abort
    let chunks = s:CollectPreviousChunks()
    if empty(chunks)
        echom "No previous chunks to submit."
        return
    endif
    call s:send_to_r(chunks . "\n")
    echom "Submitted previous chunks."
endfunction

" Perform an action on the current word in the terminal
function! Raction(action) abort
    if !s:has_r_terminal()
        echom "No R terminal available."
        return
    endif
    let current_word = expand("<cword>")
    let command = a:action . "(" . current_word . ")\n"
    call s:send_to_r(command)
endfunction

" Move to the next chunk
function! MoveNextChunk() abort
    if search(g:zzvim_config.chunk_delimiter, 'W')
        normal! j
    else
        echom "No further chunks found."
    endif
    noh
endfunction

" Move to the previous chunk
function! MovePrevChunk() abort
    let l:opening_delimiter = g:zzvim_config.chunk_delimiter
    let l:closing_delimiter = '^\s*```$'
    while line('.') > 1 && (getline('.') =~ l:opening_delimiter || getline('.') =~ l:closing_delimiter)
        normal! k
    endwhile
    let l:found = search(l:opening_delimiter, 'bW')
    if l:found > 0
        execute l:found + 1 . "normal! 0"
    else
        echom "No previous chunk found."
    endif
    noh
endfunction

" Add a pipe and a new indented line
function! AddPipeAndNewLine() abort
    normal! A |>
    normal! o
    execute "normal! i  "
endfunction

" Get the visual selection
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
        return ''
    endif

    return join(lines, "\n")
endfunction

"------------------------------------------------------------------------------
" Mappings and Autocommands
"------------------------------------------------------------------------------

augroup zzvim_RMarkdown
    autocmd!
    " Submit the current line in normal mode
    autocmd FileType r,rmd,qmd nnoremap <buffer> <CR> :call SubmitLine()<CR>

    " Submit the visual selection in visual mode
    autocmd FileType r,rmd,qmd xnoremap <buffer> <CR> :<C-u>call SubmitVisualSelection()<CR>

    " Navigate chunks
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>j :call MoveNextChunk()<CR>
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>k :call MovePrevChunk()<CR>

    " Submit all previous chunks
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>' :call SubmitPreviousChunks()<CR>

    " Open an R terminal
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>r :call OpenRTerminal()<CR>

    " Add pipe operator
    autocmd FileType r,rmd,qmd nnoremap <buffer> <C-e> :call AddPipeAndNewLine()<CR>

    " Perform actions on the word under the cursor
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>d :call Raction("dim")<CR>
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>h :call Raction("head")<CR>
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>s :call Raction("str")<CR>
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>p :call Raction("print")<CR>
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>n :call Raction("names")<CR>
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>f :call Raction("length")<CR>
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>g :call Raction("glimpse")<CR>
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>b :call Raction("dt")<CR>
augroup END
