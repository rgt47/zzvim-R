function! SubmitChunk() abort
    let save_pos = getpos('.')  " Save the current cursor position
    let chunk_start = search(g:zzvim_r_chunk_start, 'bW')
    if chunk_start == 0
        call Error("No valid chunk start found.")
        call setpos('.', save_pos)  " Restore the cursor position
        return
    endif
    let chunk_end = search(g:zzvim_r_chunk_end, 'W')
    if chunk_end == 0
        call Error("No valid chunk end found.")
        call setpos('.', save_pos)  " Restore the cursor position
        return
    endif
    let chunk_lines = getline(chunk_start + 1, chunk_end - 1)
    let g:source_file = tempname()
    call writefile(chunk_lines, g:source_file)

    let cmd = "source('" . g:source_file . "', echo=T)\n"
    call Send_to_r(cmd)
    echom "Submitted current chunk to R."
    call setpos('.', [0, chunk_end, 1, 0])
    let next_chunk_start = search(g:zzvim_r_chunk_start, 'W')
    if next_chunk_start == 0
        call Error("No more chunks found after submission.")
        return
    endif
    let line_num = next_chunk_start
    let line_count = line('$')
    while line_num <= line_count
        let current_line = getline(line_num)
        if current_line !~# '^\s*$' && current_line !~# g:zzvim_r_chunk_start && current_line !~# g:zzvim_r_chunk_end
            break
        endif
        let line_num += 1
    endwhile
    if line_num > line_count
        call Error("No valid lines inside the next chunk.")
        return
    endif
    call setpos('.', [0, line_num, 1, 0])
endfunction

"
" Select and write visual selection to a temporary file
"
" Select a markdown chunk by searching for backticks and entering visual mode
function! SelectChunk() abort
    if search('```{', 'bW')
        normal! jV
        if !search('```', 'W')
            echo "No matching closing backticks found."
        endif
    else
        echo "No R Markdown chunks found above."
    endif
endfunction
function! Sel() abort
    let visual_selection = GetVisualSelection(visualmode())
    if visual_selection == ''
        return
    endif
    let g:source_file = tempname()
    call writefile(split(visual_selection, "\n"), g:source_file)
endfunction
if !exists('g:zzvim_r_chunk_start')
    let g:zzvim_r_chunk_start = '^```{'
endif

function! Submit() abort
    if !exists("g:source_file")
        echo "No source file available."
        return
    endif
    let cmd = "source('" . g:source_file . "', echo=T)\n"
    call s:send_to_r(cmd)
endfunction
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
" Function: Move to the previous R Markdown chunk
"------------------------------------------------------------------------------
function! MovePrevChunk() abort
    let chunk_start = search(g:zzvim_r_chunk_start, 'bW')
    call setpos('.', [0, chunk_start, 1, 0])
    let chunk_end = search(g:zzvim_r_chunk_end, 'bW')
    call setpos('.', [0, chunk_end, 1, 0])
    let chunk_start = search(g:zzvim_r_chunk_start, 'bW')
    call setpos('.', [0, chunk_start, 1, 0])
            normal! j
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
    " execute 'vertical resize ' . g:zzvim_r_terminal_width

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
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>k :call MovePrevChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>l :call SubmitChunk()<CR>zz
