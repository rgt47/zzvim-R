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
    
    " Send enhanced workspace overview command directly to R
    " This uses the reliable pattern - output goes to R terminal
    let r_cmd = 'cat("\\n=== R Workspace Overview ===\\n"); '
    let r_cmd .= 'objs <- ls(); '
    let r_cmd .= 'if(length(objs) == 0) { cat("No objects in workspace\\n") } else { '
    let r_cmd .= 'for(obj in objs) { '
    let r_cmd .= 'cat("\\n", obj, " (", class(get(obj))[1], "):\\n", sep=""); '
    let r_cmd .= 'if(inherits(get(obj), "data.frame")) { '
    let r_cmd .= 'if(require(dplyr, quietly=TRUE)) glimpse(get(obj)) else str(get(obj)); '
    let r_cmd .= '} else if(is.vector(get(obj)) && length(get(obj)) > 10) { '
    let r_cmd .= 'cat("  Length:", length(get(obj)), "\\n  First 5: "); print(head(get(obj), 5)); '
    let r_cmd .= '} else { str(get(obj)) } }; '
    let r_cmd .= 'cat("\\n=== End Overview ===\\n") }'
    
    " Send to R terminal - user sees results immediately
    call s:Send_to_r(r_cmd, 1)
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
    
    " Send smart inspection command
    let r_cmd = printf('cat("\\n=== Inspecting: %s ===\\n"); ', obj_name)
    let r_cmd .= printf('if(!exists("%s")) { cat("Object does not exist\\n") } else { ', obj_name)
    let r_cmd .= printf('obj <- %s; cat("Class:", class(obj)[1], "\\n"); ', obj_name)
    let r_cmd .= 'if(inherits(obj, "data.frame")) { '
    let r_cmd .= 'cat("Dimensions:", nrow(obj), "x", ncol(obj), "\\n"); '
    let r_cmd .= 'if(require(dplyr, quietly=TRUE)) glimpse(obj) else { str(obj); head(obj) }; '
    let r_cmd .= '} else if(inherits(obj, c("lm", "glm"))) { '
    let r_cmd .= 'summary(obj); '
    let r_cmd .= '} else if(is.function(obj)) { '
    let r_cmd .= 'cat("Arguments:\\n"); print(args(obj)); '
    let r_cmd .= '} else if(is.vector(obj) && length(obj) > 20) { '
    let r_cmd .= 'cat("Length:", length(obj), "\\n"); cat("Summary:\\n"); summary(obj); '
    let r_cmd .= '} else { str(obj); if(length(obj) <= 100) print(obj) }; '
    let r_cmd .= 'cat("\\n=== End Inspection ===\\n") }'
    
    " Send to R terminal
    call s:Send_to_r(r_cmd, 1)
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