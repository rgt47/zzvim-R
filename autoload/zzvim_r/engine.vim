" ==============================================================================
" engine.vim - Core engine functions for zzvim-R plugin
" ==============================================================================
" File:         autoload/zzvim_r/engine.vim
" Maintainer:   RG Thomas <rgthomas@ucsd.edu>
" Version:      2.3
" License:      GPL-3.0
" Description:  Dispatcher engine for zzvim-R plugin operations
"
" OVERVIEW:
" This module implements a dispatcher pattern that serves as the central
" coordination point for the zzvim-R plugin. It provides a unified interface
" for various operations including logging, messaging, validation, and
" delegating to specialized modules.
"
" FUNCTIONS:
" - zzvim_r#engine#process()   - Main dispatcher function that routes operations
" - zzvim_r#engine#log()       - Convenience function for logging
" - zzvim_r#engine#msg()       - Convenience function for user messages
" - zzvim_r#engine#validate()  - Convenience function for validation
"
" INTERNAL FUNCTIONS:
" - s:engine_log()             - Handler for logging operations
" - s:engine_msg()             - Handler for message display
" - s:engine_validate()        - Handler for validation operations
"
" DEPENDENCIES:
" - zzvim_r#config            - For configuration settings
" - zzvim_r#terminal          - For terminal operations
" - zzvim_r#text              - For text extraction operations
" - zzvim_r#execute           - For code execution operations
" - zzvim_r#package           - For package management operations
" - zzvim_r#data              - For data operations
" - zzvim_r#directory         - For directory operations
"
" ==============================================================================

" ==============================================================================
" DISPATCHER REGISTRY
" ==============================================================================
" Registry of handler functions for different operations in the engine
let s:engine_handlers = {}

" ------------------------------------------------------------------------------
" Function: s:engine_log(msg, level)
"
" Write a message to the plugin log file if debug level permits
"
" Parameters:
"   msg   - The message string to log
"   level - The log level (1-4, where 1 is critical and 4 is verbose debug)
"
" Returns:
"   v:true - Operation always succeeds (even if log file writing fails)
"
" Side effects:
"   - Writes to log file specified in configuration
"   - May echo message to command line if debug level is 4 or higher
" ------------------------------------------------------------------------------
function! s:engine_log(msg, level) abort
    let l:config = zzvim_r#config#get_all()
    if l:config.debug >= a:level
        let l:entry = printf('[%s] %s: %s', strftime('%H:%M:%S'), 
                           \ l:config.log_levels[a:level], a:msg)
        try | call writefile([l:entry], expand(l:config.log_file), 'a') | catch | endtry
        if l:config.debug >= 4 | echom 'zzvim-R: ' . a:msg | endif
    endif
    return v:true
endfunction
let s:engine_handlers.log = function('s:engine_log')

" ------------------------------------------------------------------------------
" Function: s:engine_msg(msg, type)
"
" Display a formatted message to the user with appropriate highlighting
"
" Parameters:
"   msg  - The message string to display
"   type - The message type (e.g., 'error', 'warning', 'info') which determines
"          highlighting and log level
"
" Returns:
"   The appropriate return value for the message type:
"   - 0 for error messages (to indicate failure)
"   - 1 for other message types (to indicate success)
"
" Side effects:
"   - Displays message to the user with highlighting
"   - Logs the message to the log file
" ------------------------------------------------------------------------------
function! s:engine_msg(msg, type) abort
    let l:config = zzvim_r#config#get_all()
    let [l:level, l:hl, l:ret] = get(l:config.msg_types, a:type, [3, 'None', 1])
    if l:hl !=# 'None' | execute 'echohl ' . l:hl | endif
    echom 'zzvim-R: ' . a:msg
    if l:hl !=# 'None' | echohl None | endif
    call zzvim_r#engine#process('log', a:msg, l:level)
    return l:ret
endfunction
let s:engine_handlers.msg = function('s:engine_msg')

" ------------------------------------------------------------------------------
" Function: s:engine_validate(type, value)
"
" Validate different types of inputs based on validation rules
"
" Parameters:
"   type  - The type of validation to perform:
"           - 'filetype': Checks if current filetype is supported
"           - 'word': Checks if value is a valid R identifier
"           - 'r_executable': Checks if R is available in the path
"   value - The value to validate (only used for 'word' validation)
"
" Returns:
"   v:true if validation passes, v:false otherwise
"
" Side effects:
"   None
" ------------------------------------------------------------------------------
function! s:engine_validate(type, value) abort
    let l:config = zzvim_r#config#get_all()
    return a:type ==# 'filetype' ? index(l:config.supported_types, &filetype) >= 0 :
         \ a:type ==# 'word' ? (!empty(a:value) && a:value =~# '^[a-zA-Z_\.][a-zA-Z0-9_\.\$]*$') :
         \ a:type ==# 'r_executable' ? executable('R') : v:false
endfunction
let s:engine_handlers.validate = function('s:engine_validate')

" ==============================================================================
" PUBLIC API FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#engine#process(operation, ...)
"
" Main dispatcher function that routes operations to appropriate handlers
"
" This is the central routing function for the plugin. It dispatches operations
" to appropriate module handlers or internal handlers.
"
" Parameters:
"   operation - The operation to perform (e.g., 'terminal', 'text', 'log', etc.)
"   ...       - Variable arguments passed to the specific handler function
"
" Returns:
"   The return value from the handler function, or v:false if no handler exists
"
" Side effects:
"   Depends on the handler function called
" ------------------------------------------------------------------------------
function! zzvim_r#engine#process(operation, ...) abort
    " Special case handlers with custom argument handling
    if a:operation ==# 'terminal'
        return call('zzvim_r#terminal#process', [a:1, get(a:000, 1, {})])
    elseif a:operation ==# 'text'
        return call('zzvim_r#text#process', [a:1, get(a:000, 1, {})])
    elseif a:operation ==# 'execute'
        return call('zzvim_r#execute#process', [a:1, get(a:000, 1, {})])
    elseif a:operation ==# 'package'
        return call('zzvim_r#package#manage', [a:1, a:2])
    elseif a:operation ==# 'data'
        return call('zzvim_r#data#operate', [a:1, get(a:000, 1, ''), get(a:000, 2, '')])
    elseif a:operation ==# 'directory'
        return call('zzvim_r#directory#operate', [a:1, get(a:000, 1, '')])
    endif
    
    " Handle registered operations
    if has_key(s:engine_handlers, a:operation)
        return call(s:engine_handlers[a:operation], a:000)
    endif
    
    return v:false
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#engine#log(msg, level)
"
" Convenience function for logging messages
"
" This is a wrapper around the 'log' operation in the engine dispatcher
"
" Parameters:
"   msg   - The message string to log
"   level - The log level (1-4, where 1 is critical and 4 is verbose debug)
"
" Returns:
"   v:true - Operation always succeeds
" ------------------------------------------------------------------------------
function! zzvim_r#engine#log(msg, level) abort
    return zzvim_r#engine#process('log', a:msg, a:level)
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#engine#msg(msg, type)
"
" Convenience function for displaying messages to the user
"
" This is a wrapper around the 'msg' operation in the engine dispatcher
"
" Parameters:
"   msg  - The message string to display
"   type - The message type (e.g., 'error', 'warning', 'info') which determines
"          highlighting and log level
"
" Returns:
"   The appropriate return value for the message type:
"   - 0 for error messages (to indicate failure)
"   - 1 for other message types (to indicate success)
" ------------------------------------------------------------------------------
function! zzvim_r#engine#msg(msg, type) abort
    return zzvim_r#engine#process('msg', a:msg, a:type)
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#engine#validate(type, value)
"
" Convenience function for validation operations
"
" This is a wrapper around the 'validate' operation in the engine dispatcher
"
" Parameters:
"   type  - The type of validation to perform:
"           - 'filetype': Checks if current filetype is supported
"           - 'word': Checks if value is a valid R identifier
"           - 'r_executable': Checks if R is available in the path
"   value - The value to validate (only used for 'word' validation)
"
" Returns:
"   v:true if validation passes, v:false otherwise
" ------------------------------------------------------------------------------
function! zzvim_r#engine#validate(type, value) abort
    return zzvim_r#engine#process('validate', a:type, a:value)
endfunction