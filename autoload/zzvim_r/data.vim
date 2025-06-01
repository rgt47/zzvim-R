" ==============================================================================
" data.vim - Data operations for zzvim-R plugin
" ==============================================================================
" File:         autoload/zzvim_r/data.vim
" Maintainer:   RG Thomas <rgthomas@ucsd.edu>
" Version:      2.3
" License:      GPL-3.0
" Description:  Data import/export operations for zzvim-R plugin
"
" OVERVIEW:
" This module provides functionality for reading and writing data files in R.
" It handles various data operations like reading CSV files, writing R objects
" to files, and other common data import/export tasks. The module ensures proper
" validation of variables and file paths before executing operations.
"
" FUNCTIONS:
" - zzvim_r#data#operate() - Main function for performing data operations
"
" DEPENDENCIES:
" - zzvim_r#config        - For configuration settings and operation templates
" - zzvim_r#engine        - For validation and message handling
" - zzvim_r#terminal      - For sending commands to R terminal
"
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#data#operate(action, ...)
"
" Perform data operations like reading and writing files in R
"
" This function handles various data operations by generating appropriate
" R commands based on the requested action and sending them to the R terminal.
"
" Parameters:
"   action   - The data operation to perform (e.g., 'read_csv', 'write_csv')
"   ...      - Optional parameters:
"              1. file path (defaults to current file)
"              2. variable name (defaults to word under cursor)
"
" Returns:
"   v:true if operation was successful, v:false otherwise
"
" Side effects:
"   - Sends commands to R terminal
"   - Displays messages to the user about operation status
" ------------------------------------------------------------------------------
function! zzvim_r#data#operate(action, ...) abort
    " Get file path and variable with validation
    let l:file = get(a:, 1, expand('%:p'))
    let l:variable = get(a:, 2, expand('<cword>'))
    
    " Escape special characters in file path
    let l:file = substitute(l:file, '[%#<]', '\\&', 'g')
    
    " For write operations, ensure we have a variable name
    if a:action =~# '^write\|^save'
        if empty(l:variable)
            return zzvim_r#engine#msg('No variable under cursor for writing', 'error')
        endif
        
        " Validate variable name
        if !zzvim_r#engine#validate('word', l:variable)
            return zzvim_r#engine#msg('Invalid variable name for writing: ' . l:variable, 'warn')
        endif
    endif
    
    " For read operations, validate file exists (except for write operations which create files)
    if a:action =~# '^read' && !filereadable(l:file)
        return zzvim_r#engine#msg('File not readable: ' . l:file, 'error')
    endif
    
    " Get the operation format
    let l:config = zzvim_r#config#get_all()
    let l:format = get(l:config.data_operations, a:action, '')
    if empty(l:format)
        return zzvim_r#engine#msg('Unknown data operation: ' . a:action, 'error')
    endif
    
    " Build command with appropriate parameters
    let l:cmd = a:action =~# '^write\|^save' ? printf(l:format, l:variable, l:file) : printf(l:format, l:file)
    
    " Improved error context for terminal command
    let l:desc = a:action =~# '^write\|^save' ? 
               \ printf('%s variable %s to %s', a:action, l:variable, l:file) : 
               \ printf('%s from %s', a:action, l:file)
    
    let l:success = zzvim_r#terminal#send({'content': l:cmd, 'desc': l:desc})
    
    if l:success
        call zzvim_r#engine#msg(printf('Executed %s on %s', a:action, l:file), 'info')
    endif
    return l:success
endfunction