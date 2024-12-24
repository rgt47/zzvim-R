"
if !exists('g:zzvim_r_chunk_start')
    let g:zzvim_r_chunk_start = '^```{'
endif

if !exists('g:zzvim_r_chunk_end')
    let g:zzvim_r_chunk_end = '^```$'
endif
"------------------------------------------------------------------------------
" Function: Move to the next R Markdown chunk
"------------------------------------------------------------------------------
function! MoveNextChunk() abort
    " Ensure the pattern for chunk start is defined
    if !exists('g:zzvim_r_chunk_start')
        call Error("Chunk start pattern is not defined.")
        return
    endif

    " Search for the next chunk start
    let chunk_start = search(g:zzvim_r_chunk_start, 'W')

    if chunk_start
        " Move the cursor to the first line inside the chunk
        if line('.') < line('$')
            normal! j
            echom "Moved inside the next chunk at line " . line('.')
        else
            call Error("Next chunk found, but no lines inside the chunk.")
        endif
    else
        call Error("No more chunks found.")
    endif
endfunction


"------------------------------------------------------------------------------
" Function: Submit the current R Markdown chunk to R terminal
"------------------------------------------------------------------------------
function! SubmitChunk() abort
    let save_pos = getpos('.')  " Save the current cursor position

    " Find the start of the chunk
    let chunk_start = search(g:zzvim_r_chunk_start, 'bW')
    if chunk_start == 0
        call Error("No valid chunk start found.")
        call setpos('.', save_pos)  " Restore the cursor position
        return
    endif

    " Find the end of the chunk
    let chunk_end = search(g:zzvim_r_chunk_end, 'W')
    if chunk_end == 0
        call Error("No valid chunk end found.")
        call setpos('.', save_pos)  " Restore the cursor position
        return
    endif

    " Extract the lines within the chunk, excluding the closing delimiter
    let chunk_lines = getline(chunk_start + 1, chunk_end - 1)

    " Send the chunk to R
    call Send_to_r(join(chunk_lines, "\n"))
    echom "Submitted current chunk to R."

    call setpos('.', save_pos)  " Restore the cursor position
endfunction



function! GetVisualSelection() abort
    let [line_start, col_start] = getpos("'<")[1:2]
    let [line_end, col_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)

    " Trim the first and last lines to the selection
    let lines[-1] = lines[-1][: col_end - 1]
    let lines[0] = lines[0][col_start - 1:]

    return join(lines, "\n")
endfunction

function! SendVisualToR() abort
    " Get the selected text
    let selection = GetVisualSelection()

    " Check if R terminal exists
    if !exists('t:is_r_term') || t:is_r_term != 1
        echohl ErrorMsg
        echom "Error: No R terminal is active. Open one with :call OpenRTerminal()."
        echohl None
        return
    endif

    " Send the selection to the R terminal
    try
        let terms = term_list()
        let target_terminal = terms[0] " Assuming the first terminal is R
        call term_sendkeys(target_terminal, selection . "\n")
        echo "Sent visual selection to R terminal."
    catch
        echohl ErrorMsg
        echom "Error: Unable to send to R terminal."
        echohl None
    endtry
endfunction

"------------------------------------------------------------------------------
" Function: Send command to R terminal
"------------------------------------------------------------------------------
function! Send_to_r(cmd) abort
    try
        let terms = term_list()
        let target_terminal = terms[0]
        call term_sendkeys(target_terminal, a:cmd . "\n")
    catch
        call Error("Failed to send to R terminal: " . v:exception)
    endtry
    normal! j
endfunction

function! Error(msg) abort
    echohl ErrorMsg
    echom "zzvim-R: " . a:msg
    echohl None
    " call Log(a:msg, 1)
endfunction

if !exists('g:zzvim_r_terminal_width')
    let g:zzvim_r_terminal_width = 100
endif
if !exists('g:zzvim_r_command')
    let g:zzvim_r_command = 'R --no-save --quiet'
endif
"------------------------------------------------------------------------------
" Function: Open a new R terminal
"------------------------------------------------------------------------------
function! OpenRTerminal() abort
    if !executable('R')
        call Error('R is not installed or not in PATH')
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



autocmd FileType * nnoremap <buffer> <silent> <localleader>r :call OpenRTerminal()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <CR> :call Send_to_r(getline("."))<CR>

autocmd FileType *  xnoremap <buffer> <silent> <CR> :<C-u>call SendVisualToR()<CR>

        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>j :call MoveNextChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>l :call SubmitChunk()<CR>
