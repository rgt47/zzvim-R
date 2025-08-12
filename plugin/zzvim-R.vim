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
" Function: Open a new R terminal
"------------------------------------------------------------------------------
function! s:OpenRTerminal() abort
    if !executable('R')
        call s:Error('R is not installed or not in PATH')
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
            call term_sendkeys(target_terminal, a:cmd . "\n")
            " Add small delay for terminal handling
            sleep 10m
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

" function! s:SendVisualToR() abort
"     " Get the selected text
"     let selection = s:GetVisualSelection()

"     " Check if R terminal exists
"     if !exists('t:is_r_term') || t:is_r_term != 1
"         echohl ErrorMsg
"         echom "Error: No R terminal is active. Open one with :call OpenRTerminal()."
"         echohl None
"         return
"     endif

"     " Send the selection to the R terminal
"     try
"         let terms = term_list()
"         let target_terminal = terms[0]
"         call term_sendkeys(target_terminal, selection . "\n")
"         echo "Sent visual selection to R terminal."

"         " Re-select the Visual selection and move the cursor to its end
"         normal! gv
"         normal! `>j
"         normal! 0
"     catch
"         echohl ErrorMsg
"         echom "Error: Unable to send to R terminal."
"         echohl None
"     endtry
" endfunction
"
" function! s:SendVisualToR() abort
"     " Get the selected text
"     let selection = s:GetVisualSelection()

"     " Check if R terminal exists
"     if !exists('t:is_r_term') || t:is_r_term != 1
"         echohl ErrorMsg
"         echom "Error: No R terminal is active. Open one with :call OpenRTerminal()."
"         echohl None
"         return
"     endif

"     " Send the selection to the R terminal
"     try
"         let terms = term_list()
"         let target_terminal = terms[0] " Assuming the first terminal is R
"         call term_sendkeys(target_terminal, selection . "\n")
"         echo "Sent visual selection to R terminal."
"     catch
"         echohl ErrorMsg
"         echom "Error: Unable to send to R terminal."
"         echohl None
"     endtry
" endfunction
function! s:SendVisualToR() abort
    " Store the end position of the visual selection
    let [line_start, col_start] = getpos("'<")[1:2]
    let [line_end, col_end] = getpos("'>")[1:2]
    
    " Get the selected text
    let selection = s:GetVisualSelection()
    
    " Validate selection isn't empty
    if empty(selection)
        call s:Error("No text selected")
        return
    endif

    " Check if R terminal exists and try to create one if it doesn't
    if !exists('t:is_r_term') || t:is_r_term != 1
        " Try to open R terminal
        call s:OpenRTerminal()
        
        " Verify terminal was created successfully
        if !exists('t:is_r_term') || t:is_r_term != 1
            call s:Error("Could not create R terminal. Please check R installation.")
            return
        endif
    endif

    " Get available terminals
    let terms = term_list()
    if empty(terms)
        call s:Error("No active terminals found")
        return
    endif

    " Send the selection to the R terminal
    try
        let target_terminal = terms[0]
        
        " Split multi-line selections and send line by line
        let lines = split(selection, "\n")
        for line in lines
            " Skip empty lines
            if !empty(trim(line))
                call term_sendkeys(target_terminal, line . "\n")
                " Add small delay between lines for better terminal handling
                sleep 10m
            endif
        endfor
        
        " Provide feedback
        echo "Sent " . len(lines) . " line" . (len(lines) > 1 ? "s" : "") . " to R"
        
        " Exit visual mode, move to next line, and ensure normal mode
        execute "normal! \<ESC>"
        call cursor(line_end + 1, 1)
        
    catch
        call s:Error("Failed to send to R terminal: " . v:exception)
        " Ensure we exit to normal mode even on error
        execute "normal! \<ESC>"
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
    " Ensure the pattern for chunk start is defined
    if !exists('g:zzvim_r_chunk_start')
        call s:Error("Chunk start pattern is not defined.")
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
        call s:Error("No more chunks found.")
    endif
endfunction


"------------------------------------------------------------------------------
" Function: Move to the previous R Markdown chunk
"------------------------------------------------------------------------------
function! s:MovePrevChunk() abort
    let chunk_start = search(g:zzvim_r_chunk_start, 'bW')
    call setpos('.', [0, chunk_start, 1, 0])
    let chunk_end = search(g:zzvim_r_chunk_end, 'bW')
    call setpos('.', [0, chunk_end, 1, 0])
    let chunk_start = search(g:zzvim_r_chunk_start, 'bW')
    call setpos('.', [0, chunk_start, 1, 0])
            normal! j
endfunction


function! s:SubmitChunk() abort
    " Use the generalized function for chunk submission
    call s:SendToR('chunk')
    
    " Navigate to next chunk after submission (preserve original behavior)
    let save_pos = getpos('.')
    let chunk_end = search(g:zzvim_r_chunk_end, 'W')
    if chunk_end > 0
        call setpos('.', [0, chunk_end, 1, 0])
        let next_chunk_start = search(g:zzvim_r_chunk_start, 'W')
        if next_chunk_start > 0
            let line_num = next_chunk_start
            let line_count = line('$')
            while line_num <= line_count
                let current_line = getline(line_num)
                if current_line !~# '^\s*$' && current_line !~# g:zzvim_r_chunk_start 
                    \ && current_line !~# g:zzvim_r_chunk_end
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
    let l:previous_chunks = s:CollectPreviousChunks()

    " Check if there is anything to submit
    if empty(l:previous_chunks)
        echo "No previous chunks to submit."
        return
    endif

    " Submit to R using the existing send_to_r function
    call s:Send_to_r(l:previous_chunks . "\n",0)
    echo "Submitted all previous chunks to R."
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
    " Remove leading/trailing whitespace
    let clean_line = substitute(a:line, '^\s\+\|\s\+$', '', 'g')
    
    " Check each pattern individually
    if clean_line =~# '.*function\s*('
        return 1
    endif
    if clean_line =~# '^\s*if\s*('
        return 1
    endif
    if clean_line =~# '^\s*for\s*('
        return 1
    endif
    if clean_line =~# '^\s*while\s*('
        return 1
    endif
    if clean_line =~# '^\s*repeat\s*{'
        return 1
    endif
    if clean_line =~# '^\s*{'
        return 1
    endif
    
    return 0
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
    " Use the existing GetVisualSelection function logic
    let save_reg = @"
    normal! gvy
    let selected_text = @"
    let @" = save_reg
    
    " Split into lines
    return split(selected_text, '\n')
endfunction

"------------------------------------------------------------------------------
" Function: Get current chunk (reuse existing logic)
"------------------------------------------------------------------------------
function! s:GetCurrentChunk() abort
    let save_pos = getpos('.')
    let chunk_start = search(g:zzvim_r_chunk_start, 'bW')
    if chunk_start == 0
        call setpos('.', save_pos)
        return []
    endif
    let chunk_end = search(g:zzvim_r_chunk_end, 'W')
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
    " This would reuse the existing CollectPreviousChunks logic
    " For now, return empty (to be implemented)
    return []
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
    augroup END
endif
