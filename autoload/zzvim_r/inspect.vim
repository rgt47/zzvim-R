" ==============================================================================
" inspect.vim - Object inspection for zzvim-R plugin
" ==============================================================================
" File:         autoload/zzvim_r/inspect.vim
" Maintainer:   RG Thomas <rgthomas@ucsd.edu>
" Version:      2.3
" License:      GPL-3.0
" Description:  R object inspection functionality for the zzvim-R plugin
"
" OVERVIEW:
" This module provides functionality for inspecting R objects in various ways,
" such as examining structure, class, dimensions, etc. It supports both
" specialized inspection operations and generic R function application to
" objects under the cursor.
"
" FUNCTIONS:
" - object(): Main function for inspecting R objects with various actions
"
" INSPECTION OPERATIONS:
" - browse:    Show all objects in workspace with structure (ls.str())
" - workspace: List all objects in workspace (ls())
" - class:     Show class and type of an object
" - detailed:  Show detailed structure of an object
" - help_ex:   Show help and examples for a function
" - apropos:   Search for objects matching a pattern
" - find:      Find the source code of a function
" - Standard R functions: head, str, dim, names, print, length, glimpse, summary, help
"
" DEPENDENCIES:
" - zzvim_r#terminal: For sending R commands
" - zzvim_r#engine:   For validation and messaging
" - zzvim_r#config:   For R function templates and configuration
" ==============================================================================

" ==============================================================================
" zzvim_r#inspect#object(action) - Inspect R objects
" ==============================================================================
" PURPOSE: Apply various inspection operations to R objects and workspace
" PARAMETERS:
"   action - String: The inspection operation to perform, which can be:
"            - Special operations: 'browse', 'workspace', 'class', 'detailed',
"              'help_ex', 'apropos', 'find'
"            - Any valid R function name that takes an object as argument
" RETURNS:
"   v:true if inspection was successful
"   v:false if no word was under cursor or operation failed
" LOGIC:
"   1. Handle special cases that don't require a word under cursor
"   2. For word-based operations, validate the word under cursor
"   3. Handle enhanced inspection operations with special formatting
"   4. For standard R functions, apply the function to the word
" ==============================================================================
function! zzvim_r#inspect#object(action) abort
    " Get word under cursor and configuration
    let l:word = expand('<cword>')
    let l:config = zzvim_r#config#get_all()
    
    " ===========================================================================
    " Special cases that don't require a word under cursor
    " ===========================================================================
    if a:action ==# 'browse'
        " Browse all objects with structure
        return zzvim_r#terminal#send({'content': 'ls.str()', 'desc': 'workspace browser'})
    elseif a:action ==# 'workspace'
        " List all objects in workspace
        return zzvim_r#terminal#send({'content': 'ls()', 'desc': 'workspace list'})
    endif
    
    " ===========================================================================
    " For actions that need a word under cursor
    " ===========================================================================
    " Validate that there is a word under cursor
    if empty(l:word) 
        return zzvim_r#engine#msg('No word under cursor', 'error') 
    endif
    
    " Warn if word doesn't look like a valid R object name
    if !zzvim_r#engine#validate('word', l:word) 
        call zzvim_r#engine#msg(l:word . ' may not be valid R object', 'warn') 
    endif
    
    " ===========================================================================
    " Enhanced inspection operations with special formatting
    " ===========================================================================
    if a:action ==# 'class'
        " Show class and type information
        let l:cmd = printf(l:config.enhanced_inspections.class, l:word, l:word)
        return zzvim_r#terminal#send({'content': l:cmd, 'desc': printf('class(%s)', l:word)})
        
    elseif a:action ==# 'detailed'
        " Show detailed structure with limited recursion
        let l:cmd = printf(l:config.enhanced_inspections.detailed, l:word)
        return zzvim_r#terminal#send({'content': l:cmd, 'desc': printf('detailed(%s)', l:word)})
        
    elseif a:action ==# 'help_ex'
        " Show help and examples for a function
        let l:cmd = printf('help(%s); example(%s)', l:word, l:word)
        return zzvim_r#terminal#send({'content': l:cmd, 'desc': printf('help_ex(%s)', l:word)})
        
    elseif a:action ==# 'apropos'
        " Search for objects matching a pattern
        let l:cmd = printf('apropos("%s")', l:word)
        return zzvim_r#terminal#send({'content': l:cmd, 'desc': printf('apropos(%s)', l:word)})
        
    elseif a:action ==# 'find'
        " Find the source code of a function
        let l:cmd = printf('find("%s")', l:word)
        return zzvim_r#terminal#send({'content': l:cmd, 'desc': printf('find(%s)', l:word)})
        
    else
        " ===========================================================================
        " Default case - apply standard R function to the object
        " ===========================================================================
        " Get format string for special functions or use default
        let l:format = get(l:config.r_functions, a:action, '%s')
        
        " Build command string
        let l:cmd = printf('%s(' . l:format . ')', a:action, l:word)
        
        " Send command to terminal
        let l:success = zzvim_r#terminal#send({
            \ 'content': l:cmd, 
            \ 'desc': printf('%s(%s)', a:action, l:word)
            \ })
        
        " Report success
        if l:success 
            call zzvim_r#engine#msg(printf('Applied %s() to %s', a:action, l:word), 'info') 
        endif
        
        return l:success
    endif
endfunction