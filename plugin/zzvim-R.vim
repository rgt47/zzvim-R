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
"   Default: 80
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
" Commands:
"   :RSubmitLine               - Submit current line to R
"   :ROpenTerminal             - Open a new R terminal

"------------------------------------------------------------------------------
" Guard against multiple loading
"------------------------------------------------------------------------------
if exists('g:loaded_script')
    finish
endif
let g:loaded_script = 1

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
    " call Log(a:msg, 1)
endfunction

"------------------------------------------------------------------------------
" Function: Open a new R terminal
"------------------------------------------------------------------------------
function! s:OpenRTerminal() abort
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

"------------------------------------------------------------------------------
" Function: Send command to R terminal
"------------------------------------------------------------------------------
function! s:Send_to_r(cmd) abort
    try
        let terms = term_list()
        let target_terminal = terms[0]
        call term_sendkeys(target_terminal, a:cmd . "\n")
    catch
        call Error("Failed to send to R terminal: " . v:exception)
    endtry
    normal! j
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

function! s:SendVisualToR() abort
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
    if search(g:zzvim_r_chunk_start, 'W')
        " Move cursor to the next line to enter the chunk
        if line('.') < line('$')
            normal! j
            echom "Moved to the next chunk at line " . line('.')
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
    if search(g:zzvim_r_chunk_start, 'bW')
        echom "Moved to the previous chunk."
    else
        call s:Error("No previous chunks found.")
    endif
endfunction

function! s:SubmitChunk() abort
    let save_pos = getpos('.')  " Save the current cursor position

    " Find the start of the current chunk
    let chunk_start = search(g:zzvim_r_chunk_start, 'bW')
    if chunk_start == 0
        call s:Error("No valid chunk start found.")
        call setpos('.', save_pos)  " Restore the cursor position
        return
    endif

    " Find the end of the current chunk
    let chunk_end = search(g:zzvim_r_chunk_end, 'W')
    if chunk_end == 0
        call s:Error("No valid chunk end found.")
        call setpos('.', save_pos)  " Restore the cursor position
        return
    endif

    " Validate chunk range
    if chunk_start + 1 > chunk_end - 1
        call s:Error("Chunk is empty or malformed.")
        call setpos('.', save_pos)  " Restore the cursor position
        return
    endif

    " Extract the lines within the chunk, excluding the closing delimiter
    let chunk_lines = getline(chunk_start + 1, chunk_end - 1)

    " Send the chunk to R
    call s:Send_to_r(join(chunk_lines, "\n"))
    echom "Submitted current chunk to R."

    " Find the next chunk
    let next_chunk_start = search(g:zzvim_r_chunk_start, 'W')
    if next_chunk_start == 0
        call s:Error("No more chunks found after submission.")
        return
    endif

    " Move cursor to the first non-empty line inside the next chunk
    let line_num = next_chunk_start + 1  " Start searching after the delimiter
    while line_num <= line('$') && (getline(line_num) =~# '^\s*$' || getline(line_num) =~# g:zzvim_r_chunk_start)
        let line_num += 1
    endwhile

    if line_num > line('$') || getline(line_num) =~# g:zzvim_r_chunk_start
        call s:Error("No valid lines inside the next chunk.")
        return
    endif

    call setpos('.', [0, line_num, 1, 0])
    echom "Moved to the first non-empty line of the next chunk at line " . line('.')
endfunction


function! s:CollectPreviousChunks() abort
    " Define the chunk delimiter as lines starting with ```
    let l:chunk_start_delimiter = '^\s*```{.*'
    let l:chunk_end_delimiter = '^\s*```$'

    " Get the current line number
    let l:current_line = line('.')

    " Initialize variables
    let l:all_chunk_lines = []
    let l:inside_chunk = 0

    " Loop through lines up to the current line
    for l:line in range(1, l:current_line)
        let l:current_content = getline(l:line)
        
        " Check if the line is a chunk start
        if l:current_content =~ l:chunk_start_delimiter
            let l:inside_chunk = 1
            continue
        endif
        
        " Check if the line is a chunk end
        if l:current_content =~ l:chunk_end_delimiter
            let l:inside_chunk = 0
            continue
        endif

        " If inside a chunk, collect the line
        if l:inside_chunk
            call add(l:all_chunk_lines, l:current_content)
        endif
    endfor

    " Return the collected lines joined as a single string
    return join(l:all_chunk_lines, "\n")
endfunction
"------------------------------------------------------------------------------
" Mapping to Collect and Submit All Previous Chunks
"------------------------------------------------------------------------------

" Collect and submit all previous chunks to R
function! s:CollectAndSubmitPreviousChunks() abort
    " Collect all previous chunks
    let l:previous_chunks = CollectPreviousChunks()

    " Check if there is anything to submit
    if empty(l:previous_chunks)
        echo "No previous chunks to submit."
        return
    endif

    " Submit to R using the existing send_to_r function
    call s:Send_to_r(l:previous_chunks . "\n")
    echo "Submitted all previous chunks to R."
endfunction

"------------------------------------------------------------------------------
" Function: Send control keys (e.g., 'Q' or Ctrl-C)
"------------------------------------------------------------------------------
function! s:SendControlKeys(key) abort
    try
        let terms = term_list()
        let target_terminal = terms[0]
        call term_sendkeys(target_terminal, a:key)
    catch
        call s:Error("Failed to send control key: " . a:key)
    endtry
endfunction

"------------------------------------------------------------------------------
" Function: Perform an R action on the word under the cursor
"------------------------------------------------------------------------------
function! s:RAction(action) abort
    let word = expand('<cword>')
    if empty(word)
        call s:Error("No word under cursor.")
        return
    endif
    call s:Send_to_r(a:action . '(' . word . ')')
    echom "Ran " . a:action . " on " . word . "."
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
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>r :call <SID>OpenRTerminal()<CR>
        autocmd FileType *  xnoremap <buffer> <silent> <CR> :<C-u>call <SID>SendVisualToR()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <CR> :call <SID>Send_to_r(getline("."))<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>o :call <SID>AddPipeAndNewLine()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>j :call <SID>MoveNextChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>k :call <SID>MovePrevChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>l :call <SID>SubmitChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>t :call <SID>CollectAndSubmitPreviousChunks()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>q :call <SID>SendControlKeys("Q")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>c :call <SID>SendControlKeys("\<C-c>")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>d :call <SID>RAction("dim")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>h :call <SID>RAction("head")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>s :call <SID>RAction("str")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p :call <SID>RAction("print")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>n :call <SID>RAction("names")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>f :call <SID>RAction("length")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>g :call <SID>RAction("glimpse")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>b :call <SID>RAction("dt")<CR>
    augroup END
endif
