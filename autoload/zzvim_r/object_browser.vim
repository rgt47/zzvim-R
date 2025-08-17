" =============================================================================
" Enhanced Object Inspection Module for zzvim-R  
" =============================================================================
" This module provides enhanced R workspace inspection based on the glimpse
" function pattern. Much more reliable than complex browser approaches.
"
" Author: zzvim-R project
" License: GPL3

" =============================================================================
" PUBLIC API FUNCTIONS
" =============================================================================

" Show glimpse of all objects in workspace
function! zzvim_r#object_browser#glimpse_all() abort
    " Only works in R files with active terminal
    if &filetype != 'r' && &filetype != 'rmd' && &filetype != 'quarto'
        call s:Error("Enhanced inspection only works in R/Rmd/Quarto files")
        return
    endif
    
    " Check if we have an active terminal
    let terminal_id = s:GetBufferTerminal()
    if terminal_id == -1
        call s:Error("No R terminal found. Use <LocalLeader>r to create one.")
        return
    endif
    
    " Send clean workspace overview
    call s:Send_to_r('cat("\n=== Workspace Overview ===\n")', 1)
    call s:Send_to_r('for(obj in ls()) cat(obj, ":", class(get(obj))[1], "\n")', 1)
    call s:Send_to_r('cat("========================\n")', 1)
    
    echom "Workspace overview sent to R terminal"
endfunction

" Smart inspection of specific object or word under cursor
function! zzvim_r#object_browser#inspect_smart(...) abort
    " Only works in R files with active terminal
    if &filetype != 'r' && &filetype != 'rmd' && &filetype != 'quarto'
        call s:Error("Enhanced inspection only works in R/Rmd/Quarto files")
        return
    endif
    
    " Get object name from argument or word under cursor
    let obj_name = a:0 > 0 ? a:1 : expand('<cword>')
    if empty(obj_name)
        call s:Error("No object specified and no word under cursor")
        return
    endif
    
    " Check if we have an active terminal
    let terminal_id = s:GetBufferTerminal()
    if terminal_id == -1
        call s:Error("No R terminal found. Use <LocalLeader>r to create one.")
        return
    endif
    
    " Send simple inspection commands with graceful dplyr fallback
    call s:Send_to_r(printf('cat("\n=== %s ===\n")', obj_name), 1)
    call s:Send_to_r(printf('if(exists("%s")) { cat("Class:", class(%s)[1], "\n"); if(is.data.frame(%s)) { if(require(dplyr, quietly=TRUE)) glimpse(%s) else { cat("(using str - install dplyr for glimpse)\n"); str(%s) } } else str(%s) } else cat("Not found\n")', obj_name, obj_name, obj_name, obj_name, obj_name, obj_name), 1)
    echom "Inspection of '" . obj_name . "' sent to R terminal"
endfunction

" =============================================================================
" PRIVATE HELPER FUNCTIONS
" =============================================================================

" Get buffer-specific R terminal (uses core plugin functions)
function! s:GetBufferTerminal() abort
    " Use the public API from the main plugin
    return zzvim_r#GetBufferTerminal()
endfunction

" Send commands to R terminal (uses core plugin functions)
function! s:Send_to_r(cmd, stay_on_line) abort
    " Use the public API from the main plugin
    return zzvim_r#Send_to_r(a:cmd, a:stay_on_line)
endfunction

" Error display function
function! s:Error(msg) abort
    echohl ErrorMsg
    echom "zzvim-R Object Browser: " . a:msg
    echohl None
endfunction