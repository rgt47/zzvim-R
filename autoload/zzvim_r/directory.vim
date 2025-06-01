" ==============================================================================
" directory.vim - Directory operations for zzvim-R plugin
" ==============================================================================
" File:         autoload/zzvim_r/directory.vim
" Maintainer:   RG Thomas <rgthomas@ucsd.edu>
" Version:      2.3
" License:      GPL-3.0
" Description:  Directory management functions for zzvim-R plugin
"
" OVERVIEW:
" This module provides functionality for directory operations in R, such as
" changing the working directory, listing files, and other directory management
" tasks. It ensures proper validation of directory paths before executing
" operations.
"
" FUNCTIONS:
" - zzvim_r#directory#operate() - Main function for performing directory operations
"
" DEPENDENCIES:
" - zzvim_r#config              - For configuration settings and operation templates
" - zzvim_r#engine              - For message handling
" - zzvim_r#terminal            - For sending commands to R terminal
"
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#directory#operate(action, ...)
"
" Perform directory operations in R, such as changing working directories
"
" This function handles directory management by generating appropriate R commands
" based on the requested action and sending them to the R terminal.
"
" Parameters:
"   action   - The directory operation to perform (e.g., 'cd', 'ls', 'files')
"   ...      - Optional parameters:
"              1. directory path (defaults to current file's directory)
"
" Returns:
"   v:true if operation was successful, v:false otherwise
"
" Side effects:
"   - Sends commands to R terminal
"   - Displays messages to the user about operation status
" ------------------------------------------------------------------------------
function! zzvim_r#directory#operate(action, ...) abort
    " Get the path with improved validation
    let l:path = get(a:, 1, expand('%:p:h'))
    
    " Validate directory path for the 'cd' action
    if a:action ==# 'cd' && !empty(l:path)
        " Escape special characters in path
        let l:path = substitute(l:path, '[%#<]', '\\&', 'g')
        
        " Additional validation could be added here
        if !isdirectory(l:path)
            return zzvim_r#engine#msg('Invalid directory path: ' . l:path, 'error')
        endif
    endif
    
    " Get the operation format string
    let l:config = zzvim_r#config#get_all()
    let l:format = get(l:config.directory_operations, a:action, '')
    if empty(l:format)
        return zzvim_r#engine#msg('Unknown directory operation: ' . a:action, 'error')
    endif
    
    " Format command based on action
    let l:cmd = a:action ==# 'cd' ? printf(l:format, l:path) : l:format
    
    " Send command to terminal with better error context
    let l:success = zzvim_r#terminal#send({
                \ 'content': l:cmd, 
                \ 'desc': printf('directory %s%s', a:action, a:action ==# 'cd' ? ' to ' . l:path : '')
                \ })
    
    if l:success
        call zzvim_r#engine#msg(printf('Executed directory %s', a:action), 'info')
    endif
    return l:success
endfunction