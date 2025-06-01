" ==============================================================================
" zzvim_r.vim - Autoload functions for zzvim_r plugin
" ==============================================================================
" File:        autoload/zzvim_r.vim
" Maintainer:  RG Thomas <rgthomas@ucsd.edu>
" Version:     2.3
" License:     GPL-3.0
" Description: Autoload functions for zzvim_r plugin for lazy loading.
"
" OVERVIEW:
" This file contains the public API functions for the zzvim-R plugin. These
" functions are loaded on-demand through Vim's autoload mechanism when first
" called, improving startup time. The file implements all the functionality for
" interacting with R from Vim, including terminal management, code execution,
" chunk navigation, object inspection, package management, data import/export,
" directory operations, and help functionality.
"
" FUNCTION CATEGORIES:
" - Core terminal management: open_terminal, submit_line, submit_selection
" - Terminal control: send_quit, send_interrupt
" - Chunk operations: navigate_next/prev_chunk, execute_chunk/previous_chunks
" - Package management: install/load/update_package
" - Data operations: read/write_csv, read/save_rds
" - Directory operations: print/change/list/home_directory
" - Object inspection: inspect_* functions, browse_workspace, etc.
" - Help functions: help_examples, apropos_help, find_definition
"
" DEPENDENCIES:
" None - this is a self-contained implementation
"
" ==============================================================================

" Prevent loading this file multiple times
if exists('g:autoloaded_zzvim_r')
  finish
endif
let g:autoloaded_zzvim_r = 1

" ==============================================================================
" HELPER FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#wrapper(Func, ...)
"
" A wrapper that validates filetype before executing a function
"
" Parameters:
"   Func - Function: The function to call if filetype is valid
"   ...  - Any: Arguments to pass to Func
"
" Returns:
"   The result of calling Func if filetype is valid, otherwise an error message
" ------------------------------------------------------------------------------
function! zzvim_r#wrapper(Func, ...) abort
    if index(['r', 'rmd', 'rnw', 'qmd'], &filetype) >= 0
        return call(a:Func, a:000)
    else
        echo 'zzvim-R: File type not supported'
        return 0
    endif
endfunction

" ==============================================================================
" TERMINAL MANAGEMENT FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#open_terminal()
"
" Creates a new R terminal in a vertical split on the right side of the screen
"
" Creates a persistent terminal running R that is associated with the current
" tab. The terminal can be used to send R commands from Vim.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
"
" Side effects:
"   - Creates a new terminal window
"   - Sets terminal buffer options
"   - Sets tab-local variables to track the terminal
" ------------------------------------------------------------------------------
function! zzvim_r#open_terminal() abort
    " Create a terminal if it doesn't exist
    if exists('t:zzvim_r_terminal_id') && bufexists(t:zzvim_r_terminal_id)
        " Terminal already exists
        return 1
    endif

    " Create a vertical split on the right side for the terminal
    rightbelow vsplit

    " Start R in the terminal
    if has('nvim')
        " Neovim approach
        terminal R --no-save --quiet
        let t:zzvim_r_terminal_id = bufnr('%')
    else
        " Vim approach
        terminal ++curwin ++close R --no-save --quiet
        let t:zzvim_r_terminal_id = bufnr('%')
        let t:zzvim_r_job_id = term_getjob(t:zzvim_r_terminal_id)
    endif

    " Set terminal buffer options
    setlocal nobuflisted
    setlocal nonumber
    setlocal norelativenumber
    setlocal signcolumn=no

    " Return to previous window
    wincmd p

    return 1
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#submit_line()
"
" Sends the current line to the R terminal
"
" Gets the text from the current line, ensures a terminal exists, sends the
" line to the R terminal, and advances the cursor to the next line.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
"
" Side effects:
"   - Opens an R terminal if one doesn't exist
"   - Sends text to the R terminal
"   - Moves the cursor to the next line
" ------------------------------------------------------------------------------
function! zzvim_r#submit_line() abort
    " Get the current line text
    let l:line = getline('.')
    if empty(trim(l:line))
        echo "No content to send"
        return 0
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send the line to the terminal
    if has('nvim')
        " Neovim approach
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:line . "\n")
            echo "Sent: " . l:line
            normal! j
            return 1
        endif
    else
        " Vim approach
        call term_sendkeys(t:zzvim_r_terminal_id, l:line . "\n")
        echo "Sent: " . l:line
        normal! j
        return 1
    endif

    echo "Failed to send line to R"
    return 0
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#submit_selection()
"
" Sends the visually selected text to the R terminal
"
" Gets the text from the current visual selection, ensures a terminal exists,
" sends each line to the R terminal, and moves the cursor to the next line
" after the selection.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
"
" Side effects:
"   - Opens an R terminal if one doesn't exist
"   - Sends selected text to the R terminal
"   - Exits visual mode
"   - Moves the cursor to the line after the selection
" ------------------------------------------------------------------------------
function! zzvim_r#submit_selection() abort
    " Get the selected text
    let [l:start, l:end] = [getpos("'<"), getpos("'>")]
    let l:lines = getline(l:start[1], l:end[1])
    if empty(l:lines)
        echo "No selection to send"
        return 0
    endif

    " Handle single line selection with column ranges
    if len(l:lines) == 1
        let l:lines[0] = l:lines[0][l:start[2]-1 : l:end[2]-1]
    else
        " Handle multi-line selection with column ranges
        let l:lines[0] = l:lines[0][l:start[2]-1:]
        let l:lines[-1] = l:lines[-1][:l:end[2]-1]
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send each line to the terminal
    for l:line in l:lines
        if !empty(trim(l:line))
            if has('nvim')
                " Neovim approach
                let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
                if l:chan != -1
                    call chansend(l:chan, l:line . "\n")
                else
                    echo "Failed to send selection to R"
                    return 0
                endif
            else
                " Vim approach
                call term_sendkeys(t:zzvim_r_terminal_id, l:line . "\n")
            endif
        endif
    endfor

    " Exit visual mode and move cursor after selection
    execute "normal! \<Esc>"
    call cursor(l:end[1] + 1, 1)

    echo "Selection sent to R"
    return 1
endfunction

" ==============================================================================
" TERMINAL CONTROL FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#send_quit()
"
" Sends the 'Q' command to the R terminal to quit from browser or debugger
"
" Ensures a terminal exists and sends the 'Q' key to exit from browser()
" or debug() mode in R.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
"
" Side effects:
"   - Sends 'Q' to the R terminal
" ------------------------------------------------------------------------------
function! zzvim_r#send_quit() abort
    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        echo "No active R terminal"
        return 0
    endif

    " Send Q to quit from browser() or debugger
    if has('nvim')
        " Neovim approach
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, "Q\n")
            echo "Sent quit signal (Q) to R"
            return 1
        endif
    else
        " Vim approach
        call term_sendkeys(t:zzvim_r_terminal_id, "Q\n")
        echo "Sent quit signal (Q) to R"
        return 1
    endif

    echo "Failed to send quit signal"
    return 0
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#send_interrupt()
"
" Sends Ctrl-C to the R terminal to interrupt running operations
"
" Ensures a terminal exists and sends the Ctrl-C signal to interrupt
" long-running operations in R.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
"
" Side effects:
"   - Sends Ctrl-C to the R terminal
" ------------------------------------------------------------------------------
function! zzvim_r#send_interrupt() abort
    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        echo "No active R terminal"
        return 0
    endif

    " Send Ctrl-C to interrupt R
    if has('nvim')
        " Neovim approach
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, "\<C-c>")
            echo "Sent interrupt signal (Ctrl-C) to R"
            return 1
        endif
    else
        " Vim approach
        call term_sendkeys(t:zzvim_r_terminal_id, "\<C-c>")
        echo "Sent interrupt signal (Ctrl-C) to R"
        return 1
    endif

    echo "Failed to send interrupt signal"
    return 0
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#add_pipe()
"
" Adds a pipe operator (%>%) on a new line below the current line
"
" Inserts a new line with a pipe operator and moves the cursor to that line.
" This is useful for building dplyr pipelines in R.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful
"
" Side effects:
"   - Adds a new line with " %>%" below the current line
"   - Moves the cursor to the new line
" ------------------------------------------------------------------------------
function! zzvim_r#add_pipe() abort
    " Add pipe operator with two spaces to end of current line
    call setline('.', getline('.') . '  %>%')
    
    " Add a blank line below current line
    call append(line('.'), '')
    
    " Move to the new blank line
    normal! j
    
    " Add indentation matching the previous line (or use automatic indentation)
    let l:indent_level = indent(line('.') - 1)
    call setline('.', repeat(' ', l:indent_level))
    
    " Position cursor at end of indentation
    normal! $
    
    return 1
endfunction

" ==============================================================================
" CHUNK NAVIGATION FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#navigate_next_chunk()
"
" Moves the cursor to the next R code chunk in an R Markdown document
"
" Searches forward for the next R code chunk marker and positions the cursor
" at the first line of content in that chunk.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if no next chunk found
"
" Side effects:
"   - Moves the cursor to the next code chunk
" ------------------------------------------------------------------------------
function! zzvim_r#navigate_next_chunk() abort
    " Get patterns for R code chunks from plugin config
    let l:chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{[rR]')

    " Save current position
    let l:current_pos = getpos('.')
    let l:current_line_num = line('.')

    " First, find the current chunk we might be in
    let l:current_chunk_start = search(l:chunk_start_pattern, 'bcnW')

    " If we're inside or at the start of the current chunk,
    " we need to move past this chunk to find the next one
    if l:current_chunk_start > 0 && l:current_line_num >= l:current_chunk_start
        " Go to the current chunk start first
        call cursor(l:current_chunk_start, 1)

        " Then advance one position to start the next search
        normal! j
    endif

    " Now search for the next chunk
    let l:next_chunk_start = search(l:chunk_start_pattern, 'W')

    if l:next_chunk_start > 0
        " Move inside the chunk (to the line after the chunk header)
        call cursor(l:next_chunk_start + 1, 1)
        normal! zz
        echom "Moved to next chunk at line " . line('.')
        return 1
    else
        " No next chunk found, restore position
        call setpos('.', l:current_pos)
        echom "No next chunk found"
        return 0
    endif
endfunction

function! zzvim_r#navigate_prev_chunk() abort
    " Get patterns for R code chunks from plugin config
    let l:chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{[rR]')

    " Save current position
    let l:current_pos = getpos('.')
    let l:current_line_num = line('.')

    " First, find the current chunk we might be in
    let l:current_chunk_start = search(l:chunk_start_pattern, 'bcnW')

    " If we're inside or at the start of the current chunk,
    " we need to move before this chunk to find the previous one
    if l:current_chunk_start > 0
        " If we're not at the chunk start itself, go to it first
        if l:current_line_num > l:current_chunk_start
            call cursor(l:current_chunk_start, 1)
        endif

        " Now go one line above the current chunk start to search
        if l:current_chunk_start > 1
            call cursor(l:current_chunk_start - 1, 1)
        endif
    endif

    " Now search for the previous chunk
    let l:prev_chunk_start = search(l:chunk_start_pattern, 'bW')

    if l:prev_chunk_start > 0
        " Move inside the chunk (to the line after the chunk header)
        call cursor(l:prev_chunk_start + 1, 1)
        normal! zz
        echom "Moved to previous chunk at line " . line('.')
        return 1
    else
        " No previous chunk found, restore position
        call setpos('.', l:current_pos)
        echom "No previous chunk found"
        return 0
    endif
endfunction

function! zzvim_r#execute_chunk() abort
    " Get patterns for R code chunks from plugin config
    let l:chunk_start = get(g:, 'zzvim_r_chunk_start', '^```{[rR]')
    let l:chunk_end = get(g:, 'zzvim_r_chunk_end', '^```\s*$')

    " Save cursor position
    let l:cursor_pos = getpos('.')

    " Search backwards for chunk start
    let l:start_line = search(l:chunk_start, 'bcnW')
    if l:start_line == 0
        echo "Not inside an R chunk"
        return 0
    endif

    " From the start line, search forward for chunk end
    call setpos('.', [0, l:start_line, 1, 0])
    let l:end_line = search(l:chunk_end, 'nW')

    " Restore cursor position
    call setpos('.', l:cursor_pos)

    " Check if cursor is within the chunk
    if l:end_line == 0 || l:cursor_pos[1] < l:start_line || l:cursor_pos[1] > l:end_line
        echo "Not inside an R chunk"
        return 0
    endif

    " Also reject if cursor is exactly on chunk delimiters
    let l:current_line = getline(l:cursor_pos[1])
    if (l:cursor_pos[1] == l:start_line && l:current_line =~# l:chunk_start) ||
     \ (l:cursor_pos[1] == l:end_line && l:current_line =~# l:chunk_end)
        echo "Not inside R chunk content (on delimiter line)"
        return 0
    endif

    " Extract chunk content (skip the chunk header and footer)
    let l:chunk_content = getline(l:start_line + 1, l:end_line - 1)
    if empty(l:chunk_content)
        echo "Empty chunk, nothing to execute"
        return 0
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send each line to the terminal
    for l:line in l:chunk_content
        if !empty(trim(l:line))
            if has('nvim')
                " Neovim approach
                let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
                if l:chan != -1
                    call chansend(l:chan, l:line . "\n")
                else
                    echo "Failed to send chunk to R"
                    return 0
                endif
            else
                " Vim approach
                call term_sendkeys(t:zzvim_r_terminal_id, l:line . "\n")
            endif
        endif
    endfor

    " Position cursor at the end of the current chunk to find next chunk
    call setpos('.', [0, l:end_line, 1, 0])

    " Search for the next immediate chunk (the first one after this one)
    let l:next_chunk_start = search(l:chunk_start, 'W')
    if l:next_chunk_start > 0
        " Move to the first line of R code in the next chunk (skip the chunk header)
        call setpos('.', [0, l:next_chunk_start + 1, 1, 0])
        normal! zz
    else
        " If no next chunk found, just move after the current chunk
        call setpos('.', [0, l:end_line + 1, 1, 0])
    endif

    echo "Executed R chunk"
    return 1
endfunction

function! zzvim_r#execute_previous_chunks() abort
    " Get patterns for R code chunks from plugin config
    let l:chunk_start = get(g:, 'zzvim_r_chunk_start', '^```{[rR]')
    let l:chunk_end = get(g:, 'zzvim_r_chunk_end', '^```\s*$')

    " Current cursor position
    let l:cursor_line = line('.')

    " Variables to track chunks
    let l:in_chunk = 0
    let l:chunk_lines = []
    let l:all_chunk_lines = []

    " Scan from start of file to current position
    for l:line_num in range(1, l:cursor_line)
        let l:line = getline(l:line_num)

        " Check for chunk start
        if l:line =~# l:chunk_start
            let l:in_chunk = 1
            let l:chunk_lines = []
            continue  " Skip the chunk header line
        endif

        " Check for chunk end
        if l:in_chunk && l:line =~# l:chunk_end
            let l:in_chunk = 0
            let l:all_chunk_lines += l:chunk_lines
            continue  " Skip the chunk end line
        endif

        " Collect lines within chunks
        if l:in_chunk
            call add(l:chunk_lines, l:line)
        endif
    endfor

    " Check if we collected any lines
    if empty(l:all_chunk_lines)
        echo "No previous chunks found"
        return 0
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send each line to the terminal
    for l:line in l:all_chunk_lines
        if !empty(trim(l:line))
            if has('nvim')
                " Neovim approach
                let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
                if l:chan != -1
                    call chansend(l:chan, l:line . "\n")
                else
                    echo "Failed to send previous chunks to R"
                    return 0
                endif
            else
                " Vim approach
                call term_sendkeys(t:zzvim_r_terminal_id, l:line . "\n")
            endif
        endif
    endfor

    echo "Executed previous R chunks"
    return 1
endfunction

" ==============================================================================
" PACKAGE MANAGEMENT FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#install_package()
"
" Installs an R package from CRAN
"
" Prompts the user for a package name and sends the install.packages() command
" to the R terminal.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
"
" Side effects:
"   - Prompts the user for a package name
"   - Opens an R terminal if one doesn't exist
"   - Sends install.packages() command to the R terminal
" ------------------------------------------------------------------------------
function! zzvim_r#install_package() abort
    let l:package = input('Install package: ')
    if empty(l:package)
        echo "No package name provided"
        return 0
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send install.packages() command
    let l:cmd = 'install.packages("' . l:package . '")'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Installing package: " . l:package
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Installing package: " . l:package
        return 1
    endif

    return 0
endfunction

function! zzvim_r#load_package() abort
    let l:package = input('Load package: ')
    if empty(l:package)
        echo "No package name provided"
        return 0
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send library() command
    let l:cmd = 'library(' . l:package . ')'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Loading package: " . l:package
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Loading package: " . l:package
        return 1
    endif

    return 0
endfunction

function! zzvim_r#update_package() abort
    let l:package = input('Update package: ')
    if empty(l:package)
        echo "No package name provided"
        return 0
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send update.packages() command
    let l:cmd = 'update.packages("' . l:package . '")'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Updating package: " . l:package
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Updating package: " . l:package
        return 1
    endif

    return 0
endfunction

" ==============================================================================
" DATA IMPORT/EXPORT FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#read_csv()
"
" Reads a CSV file into an R variable
"
" Prompts the user for a CSV file (defaulting to the current file if it's a CSV)
" and a variable name to assign the data to, then sends the read.csv() command
" to the R terminal.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
"
" Side effects:
"   - Prompts the user for file and variable names
"   - Opens an R terminal if one doesn't exist
"   - Sends read.csv() command to the R terminal
" ------------------------------------------------------------------------------
function! zzvim_r#read_csv() abort
    " Default to current file if in csv format
    let l:file = expand('%:p')
    if l:file !~# '\.csv$'
        let l:file = input('CSV file to read: ', '', 'file')
        if empty(l:file)
            echo "No file provided"
            return 0
        endif
    endif

    " Get variable name
    let l:var = input('Variable name to assign to: ', fnamemodify(l:file, ':t:r'))
    if empty(l:var)
        echo "No variable name provided"
        return 0
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send read.csv command
    let l:cmd = l:var . ' <- read.csv("' . l:file . '")'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Reading CSV file: " . l:file
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Reading CSV file: " . l:file
        return 1
    endif

    return 0
endfunction

function! zzvim_r#write_csv() abort
    " Get object name
    let l:var = expand('<cword>')
    if empty(l:var)
        let l:var = input('R object to write: ')
        if empty(l:var)
            echo "No variable name provided"
            return 0
        endif
    endif

    " Get file name
    let l:file = expand('%:p')
    if l:file !~# '\.csv$'
        let l:file = input('CSV file to write to: ', l:var . '.csv', 'file')
        if empty(l:file)
            echo "No file provided"
            return 0
        endif
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send write.csv command
    let l:cmd = 'write.csv(' . l:var . ', file="' . l:file . '", row.names=FALSE)'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Writing " . l:var . " to CSV file: " . l:file
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Writing " . l:var . " to CSV file: " . l:file
        return 1
    endif

    return 0
endfunction

function! zzvim_r#read_rds() abort
    " Get file name
    let l:file = expand('%:p')
    if l:file !~# '\.rds$'
        let l:file = input('RDS file to read: ', '', 'file')
        if empty(l:file)
            echo "No file provided"
            return 0
        endif
    endif

    " Get variable name
    let l:var = input('Variable name to assign to: ', fnamemodify(l:file, ':t:r'))
    if empty(l:var)
        echo "No variable name provided"
        return 0
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send readRDS command
    let l:cmd = l:var . ' <- readRDS("' . l:file . '")'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Reading RDS file: " . l:file
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Reading RDS file: " . l:file
        return 1
    endif

    return 0
endfunction

function! zzvim_r#save_rds() abort
    " Get object name
    let l:var = expand('<cword>')
    if empty(l:var)
        let l:var = input('R object to save: ')
        if empty(l:var)
            echo "No variable name provided"
            return 0
        endif
    endif

    " Get file name
    let l:file = expand('%:p')
    if l:file !~# '\.rds$'
        let l:file = input('RDS file to save to: ', l:var . '.rds', 'file')
        if empty(l:file)
            echo "No file provided"
            return 0
        endif
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send saveRDS command
    let l:cmd = 'saveRDS(' . l:var . ', file="' . l:file . '")'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Saving " . l:var . " to RDS file: " . l:file
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Saving " . l:var . " to RDS file: " . l:file
        return 1
    endif

    return 0
endfunction

" ==============================================================================
" DIRECTORY OPERATION FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#print_directory()
"
" Prints the current working directory in R
"
" Sends the getwd() command to the R terminal to display the current
" working directory.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
"
" Side effects:
"   - Opens an R terminal if one doesn't exist
"   - Sends getwd() command to the R terminal
" ------------------------------------------------------------------------------
function! zzvim_r#print_directory() abort
    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send getwd() command
    let l:cmd = 'getwd()'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Printing R working directory"
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Printing R working directory"
        return 1
    endif

    return 0
endfunction

function! zzvim_r#change_directory() abort
    " Default to current file's directory
    let l:default_dir = expand('%:p:h')
    let l:dir = input('Change to directory: ', l:default_dir, 'dir')
    if empty(l:dir)
        echo "No directory provided"
        return 0
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send setwd() command
    let l:cmd = 'setwd("' . l:dir . '")'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Changing to directory: " . l:dir
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Changing to directory: " . l:dir
        return 1
    endif

    return 0
endfunction

function! zzvim_r#list_directory() abort
    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send list.files() command
    let l:cmd = 'list.files()'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Listing directory contents"
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Listing directory contents"
        return 1
    endif

    return 0
endfunction

function! zzvim_r#home_directory() abort
    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send setwd("~") command
    let l:cmd = 'setwd("~")'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Changing to home directory"
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Changing to home directory"
        return 1
    endif

    return 0
endfunction

function! zzvim_r#browse_workspace() abort
    echo "Browsing workspace"
    return 1
endfunction

function! zzvim_r#list_workspace() abort
    echo "Listing workspace"
    return 1
endfunction

function! zzvim_r#show_class() abort
    echo "Showing class of current object"
    return 1
endfunction

function! zzvim_r#show_detailed() abort
    echo "Showing detailed information"
    return 1
endfunction

" ==============================================================================
" HELP AND DOCUMENTATION FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#help_examples()
"
" Shows help and examples for an R function
"
" Gets the word under cursor (or prompts for a function name) and sends
" commands to display help and examples for that function.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
"
" Side effects:
"   - May prompt the user for a function name
"   - Opens an R terminal if one doesn't exist
"   - Sends help() and example() commands to the R terminal
" ------------------------------------------------------------------------------
function! zzvim_r#help_examples() abort
    " Get function name
    let l:func = expand('<cword>')
    if empty(l:func)
        let l:func = input('Function name: ')
        if empty(l:func)
            echo "No function name provided"
            return 0
        endif
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send help and example commands
    let l:cmd = 'help(' . l:func . '); cat("\n\n## EXAMPLES ##\n\n"); example(' . l:func . ')'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Showing help and examples for: " . l:func
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Showing help and examples for: " . l:func
        return 1
    endif

    return 0
endfunction

function! zzvim_r#apropos_help() abort
    " Get search term
    let l:term = expand('<cword>')
    if empty(l:term)
        let l:term = input('Search help for: ')
        if empty(l:term)
            echo "No search term provided"
            return 0
        endif
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send apropos command
    let l:cmd = 'apropos("' . l:term . '")'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Searching help for: " . l:term
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Searching help for: " . l:term
        return 1
    endif

    return 0
endfunction

function! zzvim_r#find_definition() abort
    " Get function name
    let l:func = expand('<cword>')
    if empty(l:func)
        let l:func = input('Function name: ')
        if empty(l:func)
            echo "No function name provided"
            return 0
        endif
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send find command
    let l:cmd = 'print(find("' . l:func . '"))'

    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Finding definition of: " . l:func
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Finding definition of: " . l:func
        return 1
    endif

    return 0
endfunction

" ==============================================================================
" OBJECT INSPECTION FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: s:send_inspect_command(func, extra_args)
"
" Helper function for sending inspection commands to the R terminal
"
" Gets the word under cursor as an object name and sends a function call
" with that object as the first argument to the R terminal.
"
" Parameters:
"   func       - String: The R function name to call
"   extra_args - String: Additional arguments to pass to the function
"
" Returns:
"   1 if successful, 0 if failed
"
" Side effects:
"   - Opens an R terminal if one doesn't exist
"   - Sends R command to the terminal
" ------------------------------------------------------------------------------
function! s:send_inspect_command(func, extra_args) abort
    " Get object name under cursor
    let l:object = expand('<cword>')
    if empty(l:object)
        echo "No object name under cursor"
        return 0
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Construct the R command
    let l:cmd = a:func . '(' . l:object
    if !empty(a:extra_args)
        let l:cmd .= ', ' . a:extra_args
    endif
    let l:cmd .= ')'

    " Send the command to R
    if has('nvim')
        " Neovim approach
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Sent: " . l:cmd
            return 1
        endif
    else
        " Vim approach
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Sent: " . l:cmd
        return 1
    endif

    echo "Failed to send command to R"
    return 0
endfunction

function! zzvim_r#inspect_head() abort
    return s:send_inspect_command('head', 'n = 10')
endfunction

function! zzvim_r#inspect_str() abort
    return s:send_inspect_command('str', '')
endfunction

function! zzvim_r#inspect_dim() abort
    return s:send_inspect_command('dim', '')
endfunction

function! zzvim_r#inspect_names() abort
    return s:send_inspect_command('names', '')
endfunction

function! zzvim_r#inspect_print() abort
    return s:send_inspect_command('print', '')
endfunction

function! zzvim_r#inspect_length() abort
    return s:send_inspect_command('length', '')
endfunction

function! zzvim_r#inspect_glimpse() abort
    return s:send_inspect_command('dplyr::glimpse', '')
endfunction

function! zzvim_r#inspect_summary() abort
    return s:send_inspect_command('summary', '')
endfunction

function! zzvim_r#inspect_help() abort
    return s:send_inspect_command('help', '')
endfunction

function! zzvim_r#browse_workspace() abort
    return s:send_inspect_command('ls.str', '')
endfunction

function! zzvim_r#list_workspace() abort
    return s:send_inspect_command('ls', '')
endfunction

function! zzvim_r#show_class() abort
    " Get object name under cursor
    let l:object = expand('<cword>')
    if empty(l:object)
        echo "No object name under cursor"
        return 0
    endif

    " Make sure we have a terminal
    if !exists('t:zzvim_r_terminal_id') || !bufexists(t:zzvim_r_terminal_id)
        call zzvim_r#open_terminal()
    endif

    " Send commands to show class and type info
    let l:cmd = 'cat("Class:", class(' . l:object . '), "\nType:", typeof(' . l:object . '), "\n")'

    " Send the command to R
    if has('nvim')
        let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
        if l:chan != -1
            call chansend(l:chan, l:cmd . "\n")
            echo "Showing class info for: " . l:object
            return 1
        endif
    else
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        echo "Showing class info for: " . l:object
        return 1
    endif

    return 0
endfunction

function! zzvim_r#show_detailed() abort
    return s:send_inspect_command('str', 'max.level = 2')
endfunction
