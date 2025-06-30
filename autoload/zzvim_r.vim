" ==============================================================================
" zzvim_r.vim - Autoload functions for zzvim_r plugin
" ==============================================================================
" File:        autoload/zzvim_r.vim
" Maintainer:  RG Thomas <rgthomas@ucsd.edu>
" Version:     3.0.0
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
" - Terminal control: send_quit, send_interrupt
" - Chunk operations: navigate_next/prev_chunk, execute_chunk/previous_chunks
" - Package management: install/load/update_package
" - Data operations: read/write_csv, read/save_rds
" - Object inspection: inspect function, browse_workspace, etc.
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
" Function: s:get_package_input(prompt)
"
" Helper function to get package name input with validation
"
" Parameters:
"   prompt - String: The input prompt to display
"
" Returns:
"   String: Package name if valid, empty string if cancelled or invalid
" ------------------------------------------------------------------------------
function! s:get_package_input(prompt) abort
    let l:package = input(a:prompt)
    if empty(l:package)
        call s:engine('msg', 'No package name provided', 'error')
        return ''
    endif
    return l:package
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
        let l:package = s:get_package_input('Install package: ')
        if empty(l:package)
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
        let l:package = s:get_package_input('Load package: ')
        if empty(l:package)
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
        let l:package = s:get_package_input('Update package: ')
        if empty(l:package)
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
    if exists('*ZzvimR_TerminalEngine')
        return ZzvimR_TerminalEngine('send', {'content': 'ls.str()', 
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

" ------------------------------------------------------------------------------
" Function: zzvim_r#inspect(type, ...)
"
" Unified object inspection function that replaces individual inspection functions
"
" Parameters:
"   type  - String: Type of inspection (head, str, dim, names, etc.)
"   ...   - Any: Optional extra arguments for the R function
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#inspect(type, ...) abort
    " Define a dictionary mapping inspection types to R functions and default args
    let l:inspect_map = {
        \ 'head': ['head', 'n = 10'],
        \ 'str': ['str', ''],
        \ 'dim': ['dim', ''],
        \ 'names': ['names', ''],
        \ 'print': ['print', ''],
        \ 'length': ['length', ''],
        \ 'glimpse': ['dplyr::glimpse', ''],
        \ 'summary': ['summary', ''],
        \ 'help': ['help', '']
    \ }

    " Check if the requested inspection type is supported
    if !has_key(l:inspect_map, a:type)
        return s:error_msg('Unknown inspection type: ' . a:type)
    endif

    " Get the R function and default args for this inspection type
    let [l:func, l:default_args] = l:inspect_map[a:type]

    " Override default args if provided
    let l:extra_args = get(a:, 1, l:default_args)

    " Delegate to send_inspect_command
    if exists('*s:send_inspect_command')
        return s:send_inspect_command(l:func, l:extra_args)
    else
        return s:error_msg('Plugin core functions not available')
    endif
endfunction

" For backward compatibility, provide the individual inspection functions
" that delegate to the unified function
function! zzvim_r#inspect_head() abort
    return zzvim_r#inspect('head')
endfunction

function! zzvim_r#inspect_str() abort
    return zzvim_r#inspect('str')
endfunction

function! zzvim_r#inspect_dim() abort
    return zzvim_r#inspect('dim')
endfunction

function! zzvim_r#inspect_names() abort
    return zzvim_r#inspect('names')
endfunction

function! zzvim_r#inspect_print() abort
    return zzvim_r#inspect('print')
endfunction

function! zzvim_r#inspect_length() abort
    return zzvim_r#inspect('length')
endfunction

function! zzvim_r#inspect_glimpse() abort
    return zzvim_r#inspect('glimpse')
endfunction

function! zzvim_r#inspect_summary() abort
    return zzvim_r#inspect('summary')
endfunction

function! zzvim_r#inspect_help() abort
    return zzvim_r#inspect('help')
endfunction

" ==============================================================================
" ENVIRONMENT PANE SIMULATION (RStudio-like feature)
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#toggle_environment()
"
" Toggles the R environment pane display (similar to peekaboo plugin)
"
" Creates a floating/split window showing the current R workspace with:
" - Object names, types, sizes, and previews
" - Interactive navigation and inspection
" - Auto-refresh on code execution
" - Search and filtering capabilities
"
" Inspired by peekaboo plugin's approach to showing register contents
"
" Parameters:
"   None
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! zzvim_r#toggle_environment() abort
    " Check if environment pane is already open
    let l:env_bufnr = s:find_environment_buffer()
    
    if l:env_bufnr > 0
        " Environment pane is open - close it
        call s:close_environment_pane(l:env_bufnr)
        return 1
    else
        " Environment pane is closed - open it
        return s:open_environment_pane()
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#refresh_environment()
"
" Refreshes the environment pane if it's currently open
" Called automatically after code execution
"
" Returns:
"   1 if refreshed, 0 if pane not open
" ------------------------------------------------------------------------------
function! zzvim_r#refresh_environment() abort
    let l:env_bufnr = s:find_environment_buffer()
    if l:env_bufnr > 0 && bufexists(l:env_bufnr)
        " Clear the current content and repopulate with fresh data
        let l:current_buf = bufnr('%')
        
        " Only switch if buffer still exists
        if bufexists(l:env_bufnr)
            silent execute 'buffer' l:env_bufnr
            setlocal modifiable noreadonly
            
            " Clear existing content but keep the buffer structure
            silent %delete _
            
            " Repopulate with fresh environment data  
            call s:populate_environment_buffer_simple(l:env_bufnr)
            
            " Return to original buffer if it still exists and is different
            if bufexists(l:current_buf) && l:current_buf != l:env_bufnr
                silent execute 'buffer' l:current_buf
            endif
        endif
        
        return 1
    endif
    return 0
endfunction

" ------------------------------------------------------------------------------
" Function: s:find_environment_buffer()
"
" Finds the environment pane buffer if it exists
"
" Returns:
"   Buffer number if found, 0 if not found
" ------------------------------------------------------------------------------
function! s:find_environment_buffer() abort
    " Look for buffer with our special name pattern
    for l:bufnr in range(1, bufnr('$'))
        if bufexists(l:bufnr) && bufname(l:bufnr) =~# '^\[R-Environment\]'
            return l:bufnr
        endif
    endfor
    return 0
endfunction

" ------------------------------------------------------------------------------
" Function: s:open_environment_pane()
"
" Opens the environment pane window with proper layout
"
" Creates either a floating window (if supported) or a split window
" Similar to how peekaboo creates its register display
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! s:open_environment_pane() abort
    if !exists('*ZzvimR_TerminalEngine')
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
    
    " Make sure we have an active R terminal
    if !ZzvimR_TerminalEngine('check', {})
        if !ZzvimR_TerminalEngine('create', {})
            call ZzvimR_Engine('msg', 'Cannot open environment: R terminal unavailable', 'error')
            return 0
        endif
    endif
    
    " Save current window info
    let l:current_win = winnr()
    let l:current_buf = bufnr('%')
    
    try
        " Create environment window (try floating first, fall back to split)
        if s:create_environment_window()
            " Populate with initial data BEFORE setting readonly
            silent call s:populate_environment_buffer_simple(bufnr('%'))
            
            " Set up the environment buffer (makes it readonly)
            silent call s:setup_environment_buffer()
            
            " Return to original window
            silent execute l:current_win . 'wincmd w'
            
            " Don't show the message to avoid "Press ENTER" prompt
            " call ZzvimR_Engine('msg', 'Environment pane opened', 'info')
            return 1
        else
            call ZzvimR_Engine('msg', 'Failed to create environment window', 'error')
            return 0
        endif
    catch
        call ZzvimR_Engine('msg', 'Error opening environment: ' . v:exception, 'error')
        return 0
    endtry
endfunction

" ------------------------------------------------------------------------------
" Function: s:create_environment_window()
"
" Creates the environment window (floating or split)
"
" Uses modern Vim features if available, falls back to split window
" Similar to peekaboo's window creation strategy
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! s:create_environment_window() abort
    " Use split window like peekaboo for better reliability
    " Floating windows can be disabled by setting g:zzvim_r_use_floating = 0
    if get(g:, 'zzvim_r_use_floating', 0) && (has('patch-8.2.0191') || has('nvim-0.4'))
        return s:create_floating_environment()
    else
        return s:create_split_environment()
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: s:create_floating_environment()
"
" Creates a floating window for the environment pane
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! s:create_floating_environment() abort
    " Calculate floating window dimensions (similar to peekaboo)
    let l:width = min([80, &columns - 4])
    let l:height = min([20, &lines - 6])
    let l:row = (&lines - l:height) / 2
    let l:col = (&columns - l:width) / 2
    
    try
        " Check if we're in Neovim
        if has('nvim')
            " Neovim floating window
            let l:opts = {
                \ 'relative': 'editor',
                \ 'width': l:width,
                \ 'height': l:height,
                \ 'row': l:row,
                \ 'col': l:col,
                \ 'style': 'minimal',
                \ 'border': 'single'
            \ }
            
            " Create buffer first
            let l:buf = nvim_create_buf(v:false, v:true)
            
            " Open floating window
            let l:win = nvim_open_win(l:buf, v:true, l:opts)
            
            " Set buffer name
            execute 'file [R-Environment]'
            
            " Populate the buffer with environment data
            call s:populate_environment_buffer_simple(l:buf)
            
            return 1
        else
            " Vim 8.2+ popup window
            let l:opts = {
                \ 'line': l:row + 1,
                \ 'col': l:col + 1,
                \ 'minwidth': l:width,
                \ 'minheight': l:height,
                \ 'border': [],
                \ 'close': 'click'
            \ }
            
            " Create popup window with empty content
            let l:popup_id = popup_create('', l:opts)
            
            " Get the buffer number of the popup
            let l:bufnr = winbufnr(popup_getwid(l:popup_id))
            
            " Switch to the popup buffer and set it up
            execute 'buffer' l:bufnr
            
            " Set buffer name
            execute 'file [R-Environment]'
            
            " Populate the buffer with environment data
            call s:populate_environment_buffer_simple(l:bufnr)
            
            return 1
        endif
    catch
        " Fall back to split if floating/popup fails
        return s:create_split_environment()
    endtry
endfunction

" ------------------------------------------------------------------------------
" Function: s:create_split_environment()
"
" Creates a split window for the environment pane
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! s:create_split_environment() abort
    try
        " Create vertical split on the right (like RStudio)
        silent execute 'rightbelow vnew'
        
        " Resize to reasonable width
        silent execute 'vertical resize 40'
        
        " Set buffer name
        silent execute 'file [R-Environment]'
        
        return 1
    catch
        return 0
    endtry
endfunction

" ------------------------------------------------------------------------------
" Function: s:setup_environment_buffer()
"
" Sets up buffer options and key mappings for the environment pane
"
" Configures the buffer similar to how peekaboo sets up its register buffer
" ------------------------------------------------------------------------------
function! s:setup_environment_buffer() abort
    " Set buffer options for environment display
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nobuflisted
    setlocal readonly
    setlocal nomodifiable
    setlocal nowrap
    setlocal number
    setlocal cursorline
    setlocal filetype=r-environment
    
    " Set up key mappings for interaction
    nnoremap <buffer> <silent> q :call <SID>close_environment_pane(bufnr('%'))<CR>
    nnoremap <buffer> <silent> <Esc> :call <SID>close_environment_pane(bufnr('%'))<CR>
    nnoremap <buffer> <silent> r :call zzvim_r#refresh_environment()<CR>
    nnoremap <buffer> <silent> <CR> :call <SID>inspect_object_under_cursor()<CR>
    nnoremap <buffer> <silent> h :call <SID>show_help()<CR>
    
    " Store buffer-local variables
    let b:environment_last_update = localtime()
    
    " Set up auto-refresh timer (configurable, default: disabled in favor of command-based refresh)
    let l:refresh_interval = get(g:, 'zzvim_r_env_refresh_interval', 0) * 1000
    if l:refresh_interval > 0
        let b:environment_timer = timer_start(l:refresh_interval, 
                                            \ function('s:auto_refresh_environment', [bufnr('%')]), 
                                            \ {'repeat': -1})
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: s:auto_refresh_environment(bufnr, timer)
"
" Timer callback to automatically refresh environment pane
" ------------------------------------------------------------------------------
function! s:auto_refresh_environment(bufnr, timer) abort
    " Only refresh if the buffer still exists and is visible
    if bufexists(a:bufnr) && bufwinnr(a:bufnr) != -1
        " Check if R terminal is still active
        if exists('t:zzvim_r_terminal_id') && exists('*ZzvimR_TerminalEngine')
            if ZzvimR_TerminalEngine('check', {})
                " Refresh the environment data silently
                try
                    call zzvim_r#refresh_environment()
                catch
                    " If refresh fails, stop the timer to prevent repeated errors
                    call timer_stop(a:timer)
                endtry
            endif
        endif
    else
        " Buffer is gone or not visible, stop the timer
        call timer_stop(a:timer)
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: s:update_environment_content(bufnr)
"
" Updates the environment pane content with current R workspace data
"
" Parameters:
"   bufnr - Buffer number of environment pane
"
" Returns:
"   1 if successful, 0 if failed
" ------------------------------------------------------------------------------
function! s:update_environment_content(bufnr) abort
    if !exists('*s:terminal_engine')
        return 0
    endif
    
    " Make sure R terminal is available
    if !s:terminal_engine('check', {})
        return 0
    endif
    
    " Create R command to get workspace information
    let l:temp_file = tempname() . '.txt'
    let l:r_cmd = printf('
    \ tryCatch({
    \   objects <- ls(envir = .GlobalEnv, all.names = FALSE)
    \   if (length(objects) == 0) {
    \     cat("# R Environment (Empty)\n")
    \     cat("# No objects in workspace\n")
    \   } else {
    \     # Get detailed information about each object
    \     info_list <- lapply(objects, function(obj_name) {
    \       obj <- get(obj_name, envir = .GlobalEnv)
    \       
    \       # Get object class and type
    \       obj_class <- class(obj)[1]
    \       obj_type <- typeof(obj)
    \       
    \       # Get object size
    \       obj_size <- object.size(obj)
    \       size_str <- if (obj_size < 1024) {
    \         paste(obj_size, "B")
    \       } else if (obj_size < 1024^2) {
    \         paste(round(obj_size/1024, 1), "KB")
    \       } else if (obj_size < 1024^3) {
    \         paste(round(obj_size/1024^2, 1), "MB")
    \       } else {
    \         paste(round(obj_size/1024^3, 1), "GB")
    \       }
    \       
    \       # Get object preview
    \       preview <- tryCatch({
    \         if (is.data.frame(obj)) {
    \           paste0(nrow(obj), " obs. of ", ncol(obj), " variables")
    \         } else if (is.matrix(obj)) {
    \           paste0(paste(dim(obj), collapse=" x "), " matrix")
    \         } else if (is.vector(obj) && length(obj) <= 5) {
    \           paste(head(obj, 5), collapse=", ")
    \         } else if (is.vector(obj)) {
    \           paste0("length ", length(obj), " vector")
    \         } else if (is.function(obj)) {
    \           "function"
    \         } else {
    \           paste(obj_class, "object")
    \         }
    \       }, error = function(e) "object")
    \       
    \       return(data.frame(
    \         Name = obj_name,
    \         Type = obj_class,
    \         Size = size_str,
    \         Preview = preview,
    \         stringsAsFactors = FALSE
    \       ))
    \     })
    \     
    \     # Combine all info
    \     env_info <- do.call(rbind, info_list)
    \     
    \     # Write formatted output
    \     cat("# R Environment (", nrow(env_info), " objects)\n")
    \     cat("# Press <CR> to inspect, r to refresh, q to close\n")
    \     cat("#", rep("-", 50), "\n")
    \     
    \     # Format as table
    \     for (i in 1:nrow(env_info)) {
    \       cat(sprintf("%%-%ds %%-%ds %%-%ds %%s\n",
    \           max(12, nchar(env_info$Name[i])),
    \           max(8, nchar(env_info$Type[i])),
    \           max(8, nchar(env_info$Size[i])),
    \           env_info$Name[i], env_info$Type[i], 
    \           env_info$Size[i], env_info$Preview[i]))
    \     }
    \   }
    \ }, error = function(e) {
    \   cat("# R Environment (Error)\n")
    \   cat("# Error getting workspace: ", e$message, "\n")
    \ })', '')
    
    " Execute R command and capture output
    let l:success = s:terminal_engine('send', 
                  \ {'content': l:r_cmd, 'desc': 'get environment info'})
    
    if !l:success
        return 0
    endif
    
    " Wait a moment for R to process and then capture output
    sleep 500m
    
    " For now, we'll use a simpler approach - get the output directly
    " This is a simplified version - in a full implementation, you'd want
    " to capture the R output more reliably
    call s:populate_environment_buffer_simple(a:bufnr)
    
    return 1
endfunction

" ------------------------------------------------------------------------------
" Function: s:populate_environment_buffer_simple(bufnr)
"
" Simplified version that populates environment buffer with basic info
"
" Parameters:
"   bufnr - Buffer number of environment pane
" ------------------------------------------------------------------------------
function! s:populate_environment_buffer_simple(bufnr) abort
    " Switch to environment buffer silently
    let l:current_buf = bufnr('%')
    silent execute 'buffer' a:bufnr
    
    " Make buffer modifiable temporarily
    setlocal modifiable
    
    " Clear existing content
    silent %delete _
    
    " Add header
    call append(0, [
        \ '# R Environment (auto-refreshes on R command execution)',
        \ '# <CR> inspect in terminal, r manual refresh, q close',
        \ '#' . repeat('-', 50),
        \ ''
    \ ])
    
    " Get actual workspace data from R
    call s:fetch_workspace_data_async(a:bufnr)
    
    " Add workspace information and commands
    call append(line('$'), [
        \ 'Object Name     Type      Size     Preview',
        \ repeat('-', 50),
        \ '',
        \ 'Workspace data will appear in R terminal below.',
        \ '',
        \ 'Available commands:',
        \ '• <LocalLeader>wb - Browse workspace (ls.str())',
        \ '• <LocalLeader>wl - List workspace (ls())',
        \ '• r - Refresh this pane',
        \ '• q - Close this pane'
    \ ])
    
    " Remove the first empty line
    1delete _
    
    " Position cursor
    normal! gg
    
    " Return to original buffer if different
    if l:current_buf != a:bufnr
        silent execute 'buffer' l:current_buf
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: s:fetch_workspace_data_async(bufnr)
"
" Fetches workspace data from R and populates the environment buffer
"
" Parameters:
"   bufnr - Buffer number of environment pane
" ------------------------------------------------------------------------------
function! s:fetch_workspace_data_async(bufnr) abort
    " Get workspace data using direct R commands and show in the pane
    call s:populate_workspace_data_directly(a:bufnr)
endfunction

" ------------------------------------------------------------------------------
" Function: s:populate_workspace_data_directly(bufnr)
"
" Directly populate the environment pane with R workspace data
" ------------------------------------------------------------------------------
function! s:populate_workspace_data_directly(bufnr) abort
    if !exists('*ZzvimR_TerminalEngine') || !exists('t:zzvim_r_terminal_id')
        return 0
    endif
    
    " Create a simple R script to get workspace info and save to file
    let l:output_file = tempname() . '.txt'
    let l:r_script = [
        \ 'tryCatch({',
        \ '  # Use local() to avoid polluting global environment',
        \ '  local({',
        \ '    objects <- ls(envir = .GlobalEnv)',
        \ '    if (length(objects) == 0) {',
        \ '      cat("No objects in workspace", file="' . l:output_file . '")',
        \ '    } else {',
        \ '      output <- c()',
        \ '      for (obj_name in objects) {',
        \ '        obj <- get(obj_name, envir = .GlobalEnv)',
        \ '        obj_class <- class(obj)[1]',
        \ '        obj_size <- format(object.size(obj), units = "auto")',
        \ '        if (is.data.frame(obj)) {',
        \ '          preview <- paste0(nrow(obj), " obs. of ", ncol(obj), " vars")',
        \ '        } else if (is.vector(obj) && length(obj) <= 3) {',
        \ '          preview <- paste(obj, collapse = ", ")',
        \ '        } else if (is.vector(obj)) {',
        \ '          preview <- paste0("length ", length(obj))',
        \ '        } else if (is.function(obj)) {',
        \ '          preview <- "function"',
        \ '        } else if (is.matrix(obj)) {',
        \ '          preview <- paste0(nrow(obj), "x", ncol(obj), " matrix")',
        \ '        } else {',
        \ '          preview <- "object"',
        \ '        }',
        \ '        line <- sprintf("%-15s %-10s %-10s %s", obj_name, obj_class, obj_size, preview)',
        \ '        output <- c(output, line)',
        \ '      }',
        \ '      writeLines(output, "' . l:output_file . '")',
        \ '    }',
        \ '  })',
        \ '}, error = function(e) {',
        \ '  cat("Error getting workspace data:", e$message, file="' . l:output_file . '")',
        \ '})'
    \ ]
    
    " Execute the R script
    try
        let l:script_file = tempname() . '.R'
        call writefile(l:r_script, l:script_file)
        call ZzvimR_TerminalEngine('send', {
            \ 'content': printf("source('%s')", l:script_file),
            \ 'desc': 'workspace data collection'
        \ })
        
        " Set timer to read the output file and update buffer
        call timer_start(1500, function('s:read_workspace_file_and_update', [a:bufnr, l:output_file]))
    catch
        " Fallback: show error message
        call s:show_workspace_error(a:bufnr, 'Failed to execute R workspace command')
    endtry
endfunction

" ------------------------------------------------------------------------------
" Function: s:read_workspace_file_and_update(bufnr, output_file, timer)
"
" Timer callback to read workspace data file and update environment buffer
" ------------------------------------------------------------------------------
function! s:read_workspace_file_and_update(bufnr, output_file, timer) abort
    if !bufexists(a:bufnr)
        return
    endif
    
    try
        " Read the output file
        if filereadable(a:output_file)
            let l:workspace_data = readfile(a:output_file)
            call delete(a:output_file)  " Clean up temp file
        else
            let l:workspace_data = ['Workspace data not available']
        endif
        
        " Update the environment buffer
        let l:current_buf = bufnr('%')
        silent execute 'buffer' a:bufnr
        setlocal modifiable noreadonly
        
        " Find where to insert the data (after the header lines)
        let l:insert_line = search('^Object Name', 'n') + 2
        if l:insert_line > 2
            " Remove any existing data
            execute (l:insert_line) . ',$delete _'
            
            " Insert the new workspace data
            call append(l:insert_line - 1, l:workspace_data)
        endif
        
        setlocal nomodifiable readonly
        
        " Return to original buffer
        if l:current_buf != a:bufnr
            silent execute 'buffer' l:current_buf
        endif
    catch
        call s:show_workspace_error(a:bufnr, 'Error reading workspace data: ' . v:exception)
    endtry
endfunction

" ------------------------------------------------------------------------------
" Function: s:show_workspace_error(bufnr, message)
"
" Show error message in environment buffer
" ------------------------------------------------------------------------------
function! s:show_workspace_error(bufnr, message) abort
    if !bufexists(a:bufnr)
        return
    endif
    
    let l:current_buf = bufnr('%')
    execute 'buffer' a:bufnr
    setlocal modifiable noreadonly
    
    let l:insert_line = search('^Object Name', 'n') + 2
    if l:insert_line > 2
        execute (l:insert_line) . ',$delete _'
        call append(l:insert_line - 1, ['Error: ' . a:message])
    endif
    
    setlocal nomodifiable readonly
    if l:current_buf != a:bufnr
        execute 'buffer' l:current_buf
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: s:update_environment_buffer_delayed(bufnr, timer)
"
" Timer callback to update environment buffer with a simple message
" ------------------------------------------------------------------------------
function! s:update_environment_buffer_delayed(bufnr, timer) abort
    if bufexists(a:bufnr)
        let l:current_buf = bufnr('%')
        execute 'buffer' a:bufnr
        setlocal modifiable noreadonly
        
        " Add simple workspace listing
        call append(line('$'), [
            \ 'Object Name     Type      Size     Preview',
            \ repeat('-', 50),
            \ '',
            \ 'Note: Check R terminal for detailed workspace output',
            \ 'Use :call zzvim_r#list_workspace() for simple listing'
        \ ])
        
        setlocal nomodifiable readonly
        if l:current_buf != a:bufnr
            execute 'buffer' l:current_buf
        endif
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: s:update_environment_buffer_fallback(bufnr)
"
" Fallback when R terminal is not available
" ------------------------------------------------------------------------------
function! s:update_environment_buffer_fallback(bufnr) abort
    let l:current_buf = bufnr('%')
    execute 'buffer' a:bufnr
    setlocal modifiable noreadonly
    
    call append(line('$'), [
        \ 'R terminal not available',
        \ 'Press \\r to open R terminal first'
    \ ])
    
    setlocal nomodifiable readonly
    if l:current_buf != a:bufnr
        execute 'buffer' l:current_buf
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: s:close_environment_pane(bufnr)
"
" Closes the environment pane
"
" Parameters:
"   bufnr - Buffer number of environment pane
" ------------------------------------------------------------------------------
function! s:close_environment_pane(bufnr) abort
    " Stop auto-refresh timer if it exists
    if bufexists(a:bufnr)
        let l:current_buf = bufnr('%')
        silent execute 'buffer' a:bufnr
        if exists('b:environment_timer')
            call timer_stop(b:environment_timer)
            unlet b:environment_timer
        endif
        if l:current_buf != a:bufnr
            silent execute 'buffer' l:current_buf
        endif
    endif
    
    " Close the window/buffer
    if bufexists(a:bufnr)
        execute 'bwipeout' a:bufnr
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: s:inspect_object_under_cursor()
"
" Inspects the R object under cursor in environment pane
" ------------------------------------------------------------------------------
function! s:inspect_object_under_cursor() abort
    " Get the line under cursor and extract object name and type
    let l:line = getline('.')
    let l:object_match = matchstr(l:line, '^\s*\zs\w\+')
    
    if !empty(l:object_match)
        " Extract object type from the line (handle data.frame with dot)
        let l:type_match = matchstr(l:line, '^\s*\w\+\s\+\zs[a-zA-Z0-9_.]\+')
        
        " Check if it's a data frame or tibble for enhanced inspection
        if l:type_match =~# '\v(data\.frame|tbl_df|tibble)'
            " For data frames/tibbles, show both str() and glimpse() in R terminal
            if exists('*ZzvimR_TerminalEngine')
                call ZzvimR_TerminalEngine('send', {
                    \ 'content': printf("cat('=== str(%s) ===\\n'); str(%s)", l:object_match, l:object_match),
                    \ 'desc': 'inspect ' . l:object_match
                \ })
                
                " Add glimpse() if dplyr is available
                call ZzvimR_TerminalEngine('send', {
                    \ 'content': printf("if (requireNamespace('dplyr', quietly=TRUE)) { cat('\\n=== glimpse(%s) ===\\n'); dplyr::glimpse(%s) } else { cat('\\n(Install dplyr package for glimpse() output)\\n') }", l:object_match, l:object_match),
                    \ 'desc': 'glimpse ' . l:object_match
                \ })
            else
                echom 'zzvim-R: R terminal not available'
            endif
        else
            " For other objects, use standard str() inspection in R terminal
            if exists('*ZzvimR_TerminalEngine')
                call ZzvimR_TerminalEngine('send', {
                    \ 'content': printf("str(%s)", l:object_match),
                    \ 'desc': 'inspect ' . l:object_match
                \ })
            else
                echom 'zzvim-R: R terminal not available'
            endif
        endif
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: s:show_help()
"
" Shows help for environment pane usage
" ------------------------------------------------------------------------------
function! s:show_help() abort
    echo 'Environment Pane Help:'
    echo '<CR>  - Inspect object under cursor'
    echo 'r     - Refresh environment data'  
    echo 'q/Esc - Close environment pane'
    echo 'h     - Show this help'
endfunction