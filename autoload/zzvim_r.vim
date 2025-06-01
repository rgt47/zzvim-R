" ==============================================================================
" zzvim_r.vim - Autoload functions for zzvim_r plugin
" ==============================================================================
" File:        autoload/zzvim_r.vim
" Maintainer:  RG Thomas <rgthomas@ucsd.edu>
" Version:     2.3.2
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
" ARCHITECTURE:
" This module uses functions defined in the plugin module. The plugin must be
" loaded before using these functions. All public API functions delegate to
" the core engines defined in the plugin file.
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
" Function: s:error_msg(message)
"
" A helper function for displaying consistent error messages
"
" Parameters:
"   message - String: The error message to display
"
" Returns:
"   0 - Always returns 0 to indicate failure
" ------------------------------------------------------------------------------
function! s:error_msg(message) abort
    if exists('*s:engine')
        call s:engine('msg', a:message, 'error')
    else
        echom 'zzvim-R: ' . a:message
    endif
    return 0
endfunction

" ------------------------------------------------------------------------------
" Function: s:get_config(section, key, default)
"
" A helper function for safely accessing configuration with fallback
"
" Parameters:
"   section - String: The section in s:config (e.g., 'data_operations')
"   key     - String: The key within the section (e.g., 'read_csv')
"   default - Any: Default value if section or key is not found
"
" Returns:
"   The config value if found, otherwise the default
" ------------------------------------------------------------------------------
function! s:get_config(section, key, default) abort
    if exists('s:config') && has_key(s:config, a:section) &&
       \ has_key(s:config[a:section], a:key)
        return s:config[a:section][a:key]
    else
        return a:default
    endif
endfunction

" ------------------------------------------------------------------------------
" DEPRECATED - Use s:public_wrapper from plugin file instead
" ------------------------------------------------------------------------------
" This function is kept for backward compatibility but should not be used in
" new code. It duplicates the functionality of s:public_wrapper() from the
" plugin file.
" ------------------------------------------------------------------------------
function! zzvim_r#wrapper(Func, ...) abort
    if exists('*s:public_wrapper')
        " Delegate to the plugin's public_wrapper if available
        return s:public_wrapper(a:Func, a:000)
    elseif index(['r', 'rmd', 'rnw', 'qmd'], &filetype) >= 0
        return call(a:Func, a:000)
    else
        echom 'zzvim-R: File type not supported'
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
    if exists('*s:public_wrapper') && exists('*s:terminal_engine')
        return s:public_wrapper(function('s:terminal_engine'), 'create', {})
    else
        return s:error_msg('Plugin core functions not available')
    endif
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
" ------------------------------------------------------------------------------
function! zzvim_r#submit_line() abort
    if exists('*s:public_wrapper') && exists('*s:execute_engine')
        return s:public_wrapper(function('s:execute_engine'), 'line', {})
    else
        return s:error_msg('Plugin core functions not available')
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#submit_selection()
"
" Sends the visually selected text to the R terminal
"
" Gets the text from the current visual selection, ensures a terminal exists,
" sends the selection to the R terminal, and moves the cursor after selection.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#submit_selection() abort
    if exists('*s:public_wrapper') && exists('*s:execute_engine')
        return s:public_wrapper(function('s:execute_engine'), 'selection', {})
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
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
" ------------------------------------------------------------------------------
function! zzvim_r#send_quit() abort
    if exists('*s:terminal_engine') && exists('*s:engine')
        " Make sure we have a terminal
        if !s:terminal_engine('check', {})
            call s:engine('msg', 'No active R terminal', 'error')
            return 0
        endif
        
        " Send 'Q' to quit browser/debugger
        let l:success = s:terminal_engine('send', {'content': 'Q', 
                                                \ 'desc': 'quit signal'})
        if l:success
            call s:engine('msg', 'Sent quit signal (Q) to R', 'info')
        endif
        return l:success
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
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
" ------------------------------------------------------------------------------
function! zzvim_r#send_interrupt() abort
    if exists('*s:terminal_engine') && exists('*s:engine')
        " Make sure we have a terminal
        if !s:terminal_engine('check', {})
            call s:engine('msg', 'No active R terminal', 'error')
            return 0
        endif
        
        " Use terminal engine control action for sending Ctrl-C
        let l:success = s:terminal_engine('control', {'key': "\<C-c>"})
        if l:success
            call s:engine('msg', 'Sent interrupt signal (Ctrl-C) to R', 'info')
        endif
        return l:success
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
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
" ------------------------------------------------------------------------------
function! zzvim_r#navigate_next_chunk() abort
    if exists('*s:engine')
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
            call s:engine('msg', 'Moved to next chunk at line ' . line('.'), 'info')
            return 1
        else
            " No next chunk found, restore position
            call setpos('.', l:current_pos)
            call s:engine('msg', 'No next chunk found', 'warn')
            return 0
        endif
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#navigate_prev_chunk()
"
" Moves the cursor to the previous R code chunk in an R Markdown document
"
" Searches backward for the previous R code chunk marker and positions the
" cursor at the first line of content in that chunk.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if no previous chunk found
" ------------------------------------------------------------------------------
function! zzvim_r#navigate_prev_chunk() abort
    if exists('*s:engine')
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
            call s:engine('msg', 'Moved to previous chunk at line ' . line('.'), 
                        \ 'info')
            return 1
        else
            " No previous chunk found, restore position
            call setpos('.', l:current_pos)
            call s:engine('msg', 'No previous chunk found', 'warn')
            return 0
        endif
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#execute_chunk()
"
" Executes the R code chunk under the cursor in an R Markdown document
"
" Identifies the current R code chunk, extracts its content, and sends it
" to the R terminal for execution.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if not inside a valid R chunk
" ------------------------------------------------------------------------------
function! zzvim_r#execute_chunk() abort
    if exists('*s:public_wrapper') && exists('*s:execute_engine')
        return s:public_wrapper(function('s:execute_engine'), 'chunk', {})
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#execute_previous_chunks()
"
" Executes all R code chunks before the cursor position
"
" Collects all R code from chunks that appear before the current cursor
" position and sends it to the R terminal for execution.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if no chunks found
" ------------------------------------------------------------------------------
function! zzvim_r#execute_previous_chunks() abort
    if exists('*s:public_wrapper') && exists('*s:execute_engine')
        return s:public_wrapper(function('s:execute_engine'), 'previous', {})
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
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
" ------------------------------------------------------------------------------
function! zzvim_r#install_package() abort
    if exists('*s:engine')
        let l:package = input('Install package: ')
        if empty(l:package)
            call s:engine('msg', 'No package name provided', 'error')
            return 0
        endif
        
        return zzvim_r#package_management('install', l:package)
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#load_package()
"
" Loads an R package using library()
"
" Prompts the user for a package name and sends the library() command
" to the R terminal.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#load_package() abort
    if exists('*s:engine')
        let l:package = input('Load package: ')
        if empty(l:package)
            call s:engine('msg', 'No package name provided', 'error')
            return 0
        endif
        
        return zzvim_r#package_management('load', l:package)
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#update_package()
"
" Updates an R package from CRAN
"
" Prompts the user for a package name and sends the update.packages() command
" to the R terminal.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#update_package() abort
    if exists('*s:engine')
        let l:package = input('Update package: ')
        if empty(l:package)
            call s:engine('msg', 'No package name provided', 'error')
            return 0
        endif
        
        return zzvim_r#package_management('update', l:package)
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ==============================================================================
" DATA IMPORT/EXPORT FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#read_csv()
"
" Reads a CSV file into an R variable
"
" Prompts for a CSV file and variable name, then sends the read.csv() command
" to the R terminal.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#read_csv() abort
    if exists('*s:terminal_engine') && exists('*s:engine')
        " Default to current file if in csv format
        let l:file = expand('%:p')
        if l:file !~# '\.csv$'
            let l:file = input('CSV file to read: ', '', 'file')
            if empty(l:file)
                call s:engine('msg', 'No file provided', 'error')
                return 0
            endif
        endif

        " Get variable name
        let l:var = input('Variable name to assign to: ',
                        \ fnamemodify(l:file, ':t:r'))
        if empty(l:var)
            call s:engine('msg', 'No variable name provided', 'error')
            return 0
        endif

        " Get the format string for read_csv with fallback
        let l:format = s:get_config('data_operations', 'read_csv', 'read.csv("%s")')

        " Set up the operation, custom for CSV import with assignment
        let l:cmd = l:var . ' <- ' . printf(l:format, l:file)

        " Use the terminal engine to send the command
        let l:success = s:terminal_engine('send',
                      \ {'content': l:cmd, 'desc': 'read CSV to ' . l:var})

        if l:success
            call s:engine('msg', 'Reading CSV file: ' . l:file .
                         \ ' to variable ' . l:var, 'info')
        endif

        return l:success
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#write_csv()
"
" Writes an R object to a CSV file
"
" Gets the object name from under the cursor or prompts the user, prompts for
" a file name, then sends the write.csv() command to the R terminal.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#write_csv() abort
    if exists('*s:engine')
        " Get object name
        let l:var = expand('<cword>')
        if empty(l:var)
            let l:var = input('R object to write: ')
            if empty(l:var)
                call s:engine('msg', 'No variable name provided', 'error')
                return 0
            endif
        endif
    
        " Get file name
        let l:file = input('CSV file to write to: ', l:var . '.csv', 'file')
        if empty(l:file)
            call s:engine('msg', 'No file provided', 'error')
            return 0
        endif
        
        return zzvim_r#data_operation('write_csv', l:file, l:var)
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#read_rds()
"
" Reads an RDS file into an R variable
"
" Prompts for an RDS file and variable name, then sends the readRDS() command
" to the R terminal.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#read_rds() abort
    if exists('*s:terminal_engine') && exists('*s:engine')
        " Get file name
        let l:file = input('RDS file to read: ', '', 'file')
        if empty(l:file)
            call s:engine('msg', 'No file provided', 'error')
            return 0
        endif

        " Get variable name
        let l:var = input('Variable name to assign to: ',
                        \ fnamemodify(l:file, ':t:r'))
        if empty(l:var)
            call s:engine('msg', 'No variable name provided', 'error')
            return 0
        endif

        " Get the format string for read_rds with fallback
        let l:format = s:get_config('data_operations', 'read_rds', 'readRDS("%s")')

        " Set up the operation, custom for RDS import with assignment
        let l:cmd = l:var . ' <- ' . printf(l:format, l:file)

        " Use the terminal engine to send the command
        let l:success = s:terminal_engine('send',
                      \ {'content': l:cmd, 'desc': 'read RDS to ' . l:var})

        if l:success
            call s:engine('msg', 'Reading RDS file: ' . l:file .
                        \ ' to variable ' . l:var, 'info')
        endif

        return l:success
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#save_rds()
"
" Saves an R object to an RDS file
"
" Gets the object name from under the cursor or prompts the user, prompts for
" a file name, then sends the saveRDS() command to the R terminal.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#save_rds() abort
    if exists('*s:engine')
        " Get object name
        let l:var = expand('<cword>')
        if empty(l:var)
            let l:var = input('R object to save: ')
            if empty(l:var)
                call s:engine('msg', 'No variable name provided', 'error')
                return 0
            endif
        endif
    
        " Get file name
        let l:file = input('RDS file to save to: ', l:var . '.rds', 'file')
        if empty(l:file)
            call s:engine('msg', 'No file provided', 'error')
            return 0
        endif
        
        return zzvim_r#data_operation('save_rds', l:file, l:var)
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
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
" ------------------------------------------------------------------------------
function! zzvim_r#print_directory() abort
    if exists('*zzvim_r#directory_operation')
        return zzvim_r#directory_operation('pwd', '')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#change_directory()
"
" Changes the working directory in R
"
" Prompts the user for a directory path and sends the setwd() command
" to the R terminal.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#change_directory() abort
    if exists('*s:engine')
        " Default to current file's directory
        let l:default_dir = expand('%:p:h')
        let l:dir = input('Change to directory: ', l:default_dir, 'dir')
        if empty(l:dir)
            call s:engine('msg', 'No directory provided', 'error')
            return 0
        endif
        
        return zzvim_r#directory_operation('cd', l:dir)
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#list_directory()
"
" Lists the contents of the current directory in R
"
" Sends the list.files() command to the R terminal to display the files
" in the current working directory.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#list_directory() abort
    if exists('*zzvim_r#directory_operation')
        return zzvim_r#directory_operation('ls', '')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#home_directory()
"
" Changes to the home directory in R
"
" Sends the setwd("~") command to the R terminal to change to the user's
" home directory.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#home_directory() abort
    if exists('*zzvim_r#directory_operation')
        return zzvim_r#directory_operation('home', '')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ==============================================================================
" WORKSPACE AND OBJECT INSPECTION FUNCTIONS
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
" ------------------------------------------------------------------------------
function! s:send_inspect_command(func, extra_args) abort
    if exists('*s:engine') && exists('*s:terminal_engine')
        " Get object name under cursor
        let l:object = expand('<cword>')
        if empty(l:object)
            call s:engine('msg', 'No object name under cursor', 'error')
            return 0
        endif
    
        " Make sure we have a terminal
        if !s:terminal_engine('check', {})
            " Call open_terminal only if it exists
            if exists('*s:public_wrapper') && exists('*s:terminal_engine')
                call s:public_wrapper(function('s:terminal_engine'), 'create', {})
            else
                call s:engine('msg', 'No active terminal and cannot create one', 'error')
                return 0
            endif
        endif
    
        " Construct the R command
        let l:cmd = a:func . '(' . l:object
        if !empty(a:extra_args)
            let l:cmd .= ', ' . a:extra_args
        endif
        let l:cmd .= ')'
    
        " Use terminal engine to send command
        let l:success = s:terminal_engine('send', 
                      \ {'content': l:cmd, 
                      \ 'desc': a:func . '(' . l:object . ')'})
        
        if l:success
            call s:engine('msg', 'Applied ' . a:func . '() to ' . l:object, 'info')
        endif
        
        return l:success
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#browse_workspace()
"
" Shows the workspace browser (ls.str())
"
" Sends the ls.str() command to the R terminal to display a structured
" listing of all objects in the workspace.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#browse_workspace() abort
    if exists('*s:terminal_engine')
        return s:terminal_engine('send', {'content': 'ls.str()', 
                                        \ 'desc': 'workspace browser'})
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#list_workspace()
"
" Lists the variables in the workspace (ls())
"
" Sends the ls() command to the R terminal to display a list of all
" objects in the workspace.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#list_workspace() abort
    if exists('*s:terminal_engine')
        return s:terminal_engine('send', {'content': 'ls()', 
                                        \ 'desc': 'workspace list'})
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#show_class()
"
" Shows class and type information for the object under cursor
"
" Sends a custom command to display both class() and typeof() information
" for the R object under the cursor.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#show_class() abort
    if exists('*s:engine') && exists('*s:terminal_engine')
        " Get object name under cursor
        let l:object = expand('<cword>')
        if empty(l:object)
            call s:engine('msg', 'No object name under cursor', 'error')
            return 0
        endif

        " Get the format with fallback
        let l:format = s:get_config('enhanced_inspections', 'class',
                               \ 'cat("Class:", class(%s), "\nType:", typeof(%s), "\n")')

        " Use enhanced inspection via terminal engine
        let l:cmd = printf(l:format, l:object, l:object)
        let l:success = s:terminal_engine('send',
                      \ {'content': l:cmd, 'desc': 'class info'})

        if l:success
            call s:engine('msg', 'Showing class info for: ' . l:object, 'info')
        endif

        return l:success
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#show_detailed()
"
" Shows detailed structure of the object under cursor
"
" Sends the str() command with max.level=2 to the R terminal to display
" a detailed view of the object's structure without excessive depth.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#show_detailed() abort
    if exists('*s:send_inspect_command')
        return s:send_inspect_command('str', 'max.level = 2')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
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
" ------------------------------------------------------------------------------
function! zzvim_r#help_examples() abort
    if exists('*s:engine') && exists('*s:terminal_engine')
        " Get function name
        let l:func = expand('<cword>')
        if empty(l:func)
            let l:func = input('Function name: ')
            if empty(l:func)
                call s:engine('msg', 'No function name provided', 'error')
                return 0
            endif
        endif
    
        " Make sure we have a terminal
        if !s:terminal_engine('check', {})
            " Call open_terminal only if it exists
            if exists('*s:public_wrapper') && exists('*s:terminal_engine')
                call s:public_wrapper(function('s:terminal_engine'), 'create', {})
            else
                call s:engine('msg', 'No active terminal and cannot create one', 'error')
                return 0
            endif
        endif
    
        " Send help and example commands
        let l:cmd = 'help(' . l:func . '); cat("\n\n## EXAMPLES ##\n\n"); ' .
                  \ 'example(' . l:func . ')'
    
        " Use terminal engine to send command
        let l:success = s:terminal_engine('send', 
                      \ {'content': l:cmd, 'desc': 'help and examples'})
        
        if l:success
            call s:engine('msg', 'Showing help and examples for: ' . l:func, 'info')
        endif
        
        return l:success
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#apropos_help()
"
" Searches for help topics matching a pattern
"
" Gets the word under cursor (or prompts for a search term) and sends
" the apropos() command to search for related functions and help topics.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#apropos_help() abort
    if exists('*s:engine') && exists('*s:terminal_engine')
        " Get search term
        let l:term = expand('<cword>')
        if empty(l:term)
            let l:term = input('Search help for: ')
            if empty(l:term)
                call s:engine('msg', 'No search term provided', 'error')
                return 0
            endif
        endif
    
        " Use terminal engine to send apropos command
        let l:cmd = 'apropos("' . l:term . '")'
        let l:success = s:terminal_engine('send', 
                      \ {'content': l:cmd, 'desc': 'help search'})
        
        if l:success
            call s:engine('msg', 'Searching help for: ' . l:term, 'info')
        endif
        
        return l:success
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#find_definition()
"
" Finds the definition of an R function
"
" Gets the word under cursor (or prompts for a function name) and sends
" the find() command to locate the function definition.
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#find_definition() abort
    if exists('*s:engine') && exists('*s:terminal_engine')
        " Get function name
        let l:func = expand('<cword>')
        if empty(l:func)
            let l:func = input('Function name: ')
            if empty(l:func)
                call s:engine('msg', 'No function name provided', 'error')
                return 0
            endif
        endif
    
        " Use terminal engine to send find command
        let l:cmd = 'print(find("' . l:func . '"))'
        let l:success = s:terminal_engine('send', 
                      \ {'content': l:cmd, 'desc': 'find definition'})
        
        if l:success
            call s:engine('msg', 'Finding definition of: ' . l:func, 'info')
        endif
        
        return l:success
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

" ==============================================================================
" OBJECT INSPECTION FUNCTIONS
" ==============================================================================

" Inspection functions using the s:send_inspect_command helper

function! zzvim_r#inspect_head() abort
    if exists('*s:send_inspect_command')
        return s:send_inspect_command('head', 'n = 10')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

function! zzvim_r#inspect_str() abort
    if exists('*s:send_inspect_command')
        return s:send_inspect_command('str', '')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

function! zzvim_r#inspect_dim() abort
    if exists('*s:send_inspect_command')
        return s:send_inspect_command('dim', '')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

function! zzvim_r#inspect_names() abort
    if exists('*s:send_inspect_command')
        return s:send_inspect_command('names', '')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

function! zzvim_r#inspect_print() abort
    if exists('*s:send_inspect_command')
        return s:send_inspect_command('print', '')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

function! zzvim_r#inspect_length() abort
    if exists('*s:send_inspect_command')
        return s:send_inspect_command('length', '')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

function! zzvim_r#inspect_glimpse() abort
    if exists('*s:send_inspect_command')
        return s:send_inspect_command('dplyr::glimpse', '')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

function! zzvim_r#inspect_summary() abort
    if exists('*s:send_inspect_command')
        return s:send_inspect_command('summary', '')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction

function! zzvim_r#inspect_help() abort
    if exists('*s:send_inspect_command')
        return s:send_inspect_command('help', '')
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction