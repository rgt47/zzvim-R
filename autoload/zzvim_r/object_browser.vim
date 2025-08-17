" =============================================================================
" Object Browser Module for zzvim-R
" =============================================================================
" This module provides a vim-peekaboo style object browser for R workspace
" inspection. It can be loaded independently and tested in isolation.
"
" Author: zzvim-R project
" License: GPL3

" =============================================================================
" PUBLIC API FUNCTIONS
" =============================================================================

" Main object browser function - opens browser window showing R objects
" Similar to vim-peekaboo's register viewer but for R workspace objects
function! zzvim_r#object_browser#open() abort
    " Only works in R files with active terminal
    if &filetype != 'r' && &filetype != 'rmd' && &filetype != 'quarto'
        call s:Error("Object browser only works in R/Rmd/Quarto files")
        return
    endif
    
    " Check if we have an active terminal
    let terminal_id = s:GetBufferTerminal()
    if terminal_id == -1
        call s:Error("No R terminal found. Use <LocalLeader>r to create one.")
        return
    endif
    
    " Save current window to return to
    let current_winnr = winnr()
    
    try
        " Open as a regular new buffer for easier debugging
        enew
        
        " Set buffer name for identification
        silent! file [R-Objects-Debug]
        
        " Basic buffer settings for debugging
        setlocal buftype=nofile
        setlocal noswapfile
        
        " Simple key mappings for debugging
        nnoremap <buffer><silent> q :q<CR>
        
        " Populate with R objects list
        call s:PopulateObjectList()
        
        " Position cursor on first object
        normal! gg
        
        " Silent status message in buffer instead of command line
        call append(line('$'), ["", "=== R Object Browser ===", "Press 'q' to close"])
        
    catch /^Vim\%((\a\+)\)\=:E/
        call s:Error("Failed to open object browser: " . v:exception)
        " Return to original window if something went wrong
        execute current_winnr . 'wincmd w'
    endtry
endfunction

" =============================================================================
" PRIVATE HELPER FUNCTIONS
" =============================================================================

" Populate the browser window with list of R objects
function! s:PopulateObjectList() abort
    " Clear the buffer
    silent! %delete _
    
    " Use a fixed temp file for easier debugging
    let simple_temp = '/tmp/zzvim_r_objects_debug'
    
    " Store ls() result first to avoid timing issues
    call s:Send_to_r("obj_names <- ls()", 1)
    sleep 200m
    let r_cmd = printf("writeLines(paste(seq_along(obj_names), obj_names, sep='. '), '%s'); flush.console()", simple_temp)
    call s:Send_to_r(r_cmd, 1)
    sleep 1000m
    
    " Read the captured output with debugging - don't delete file yet
    if filereadable(simple_temp)
        let lines = readfile(simple_temp)
        " Don't delete file for debugging
        " call delete(simple_temp)
        
        if empty(lines)
            call setline(1, ["Waiting for R objects...", 
                           \ "Debug: File was readable but empty",
                           \ "Temp file: " . simple_temp,
                           \ "R command: " . r_cmd])
        else
            call setline(1, lines)
        endif
    else
        call setline(1, ["Error: Could not retrieve R objects", 
                       \ "Make sure R terminal is active",
                       \ "Debug: File not readable",
                       \ "Temp file: " . simple_temp,
                       \ "R command sent: " . r_cmd])
    endif
    
    " Add footer with instructions
    call append(line('$'), ["", 
                          \ "─────────────────────────────────",
                          \ "Usage:",
                          \ "• q: Close browser"])
endfunction

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