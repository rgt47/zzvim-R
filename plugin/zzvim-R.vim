" zzvim-R.vim
" A Vim plugin for working with R and R Markdown files, sending code to an R terminal.

"------------------------------------------------------------------------------
" Utility Functions
"------------------------------------------------------------------------------

function! s:has_r_terminal() abort
    try
        return !empty(term_list())  " Return true if terminals exist
    catch
        echom "Error checking R terminal: " . v:exception
        return 0                   " Return false on error
    endtry
endfunction

function! s:choose_terminal(terms) abort
    let choices = ['Cancel'] + map(copy(a:terms), 'bufname(v:val)')
    let choice = inputlist(choices)
    return choice == 0 ? -1 : a:terms[choice - 1]
endfunction

function! s:send_to_r(cmd) abort
    if !s:has_r_terminal()
        echom "No R terminal available. Open one with <localleader>r."
        return
    endif
    try
        let terms = term_list()
        let target_terminal = len(terms) == 1 ? terms[0] : s:choose_terminal(terms)
        if target_terminal == -1
            echom "Command canceled."
            return
        endif
        call term_sendkeys(target_terminal, a:cmd)
        echom "Command sent to terminal buffer: " . target_terminal
    catch
        echom "Error sending command to R terminal: " . v:exception
    endtry
endfunction

"------------------------------------------------------------------------------
" Core Functions
"------------------------------------------------------------------------------


function! s:SubmitLine() abort
    call s:send_to_r(getline(".") . "\n")
    " Move to the next line
    normal! j
endfunction









function! s:SubmitLine() abort
    call s:send_to_r(getline(".") . "\n")
endfunction

function! s:SubmitVisualSelection() abort
    let selection = s:GetVisualSelection(visualmode())
    if !empty(selection)
        call s:send_to_r(selection . "\n")
    else
        echom "No visual selection to submit."
    endif
endfunction

function! s:CollectPreviousChunks() abort
    let chunk_start = '^\s*```{.*'
    let chunk_end = '^\s*```$'
    let all_chunks = []
    let inside_chunk = 0

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
            call add(all_chunks, line_content)
        endif
    endfor
    return join(all_chunks, "\n")
endfunction

function! s:CollectAndSubmitPreviousChunks() abort
    let previous_chunks = s:CollectPreviousChunks()
    if empty(previous_chunks)
        echom "No previous chunks to submit."
        return
    endif
    call s:send_to_r(previous_chunks . "\n")
    echom "Submitted previous chunks."
endfunction

function! s:MoveNextChunk() abort
    if search('```{', 'W')
        normal! j
    else
        echom "No further chunks found."
    endif
    noh
endfunction

function! s:MovePrevChunk() abort
    let opening = '^\s*```{.*'
    let closing = '^\s*```$'
    while line('.') > 1 && (getline('.') =~ opening || getline('.') =~ closing)
        normal! k
    endwhile
    if search(opening, 'bW') > 0
        normal! j
    else
        echom "No previous chunk found."
    endif
    noh
endfunction

function! s:AddPipeAndNewLine() abort
    normal! A |>
    normal! o
    execute "normal! i  "
endfunction

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
" Autocommands and Mappings
"------------------------------------------------------------------------------

augroup zzvim_RMarkdown
    autocmd!
    " Submit the current line in normal mode
    " 
    autocmd FileType r,rmd,qmd nnoremap <buffer> <CR> :call <SID>SubmitLine()<CR>

    " Submit the visual selection in visual mode
    autocmd FileType r,rmd,qmd xnoremap <buffer> <CR> :<C-u>call <SID>SubmitVisualSelection()<CR>

    " Navigate chunks
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>j :call <SID>MoveNextChunk()<CR>
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>k :call <SID>MovePrevChunk()<CR>

    " Submit all previous chunks
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>' :call <SID>CollectAndSubmitPreviousChunks()<CR>

    " Open an R terminal
    autocmd FileType r,rmd,qmd nnoremap <buffer> <localleader>r :vert term R --no-save<CR>

    " Add pipe operator
    autocmd FileType r,rmd,qmd nnoremap <buffer> <C-e> :call <SID>AddPipeAndNewLine()<CR>
augroup END
