" ==============================================================================
" package.vim - Package management for zzvim-R plugin
" ==============================================================================
" File:         autoload/zzvim_r/package.vim
" Maintainer:   RG Thomas <rgthomas@ucsd.edu>
" Version:      2.3
" License:      GPL-3.0
" Description:  R package management functions for zzvim-R plugin
"
" OVERVIEW:
" This module provides functionality for managing R packages directly from Vim.
" It supports operations like loading, installing, updating, and removing R
" packages. The module ensures proper validation of package names before
" executing operations.
"
" FUNCTIONS:
" - zzvim_r#package#manage() - Main function for package management operations
"
" DEPENDENCIES:
" - zzvim_r#config          - For configuration settings and operation templates
" - zzvim_r#engine          - For message handling
" - zzvim_r#terminal        - For sending commands to R terminal
"
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#package#manage(action, package)
"
" Manage R packages with various operations
"
" This function performs package management operations by generating appropriate
" R commands based on the requested action and sending them to the R terminal.
"
" Parameters:
"   action  - The package operation to perform (e.g., 'load', 'install', 'update')
"   package - The name of the R package to operate on
"
" Returns:
"   v:true if operation was successful, v:false otherwise
"
" Side effects:
"   - Sends commands to R terminal
"   - Displays messages to the user about operation status
" ------------------------------------------------------------------------------
function! zzvim_r#package#manage(action, package) abort
    if empty(a:package)
        return zzvim_r#engine#msg('Package name required', 'error')
    endif
    
    let l:config = zzvim_r#config#get_all()
    let l:format = get(l:config.package_operations, a:action, l:config.package_operations.load)
    let l:cmd = printf(l:format, a:package)
    let l:success = zzvim_r#terminal#send({'content': l:cmd, 'desc': printf('%s package %s', a:action, a:package)})
    
    if l:success 
        call zzvim_r#engine#msg(printf('Executed %s on package %s', a:action, a:package), 'info') 
    endif
    return l:success
endfunction