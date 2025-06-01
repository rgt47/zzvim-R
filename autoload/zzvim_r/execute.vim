" ==============================================================================
" execute.vim - Execution functions for zzvim-R plugin
" ==============================================================================
" File:         autoload/zzvim_r/execute.vim
" Maintainer:   RG Thomas <rgthomas@ucsd.edu>
" Version:      2.3
" License:      GPL-3.0
" Description:  Code execution functionality for the zzvim-R plugin
"
" OVERVIEW:
" This module is responsible for executing R code from various sources such as
" individual lines, visual selections, and R markdown chunks. It handles the
" process of extracting code, sending it to the R terminal, and managing
" cursor navigation after execution.
"
" FUNCTIONS:
" - process(): Main execution function that handles all content types
"
" CONTENT TYPES:
" - line:      Single line of R code
" - selection: Visually selected R code
" - chunk:     R code within a markdown code chunk
" - previous:  All code in previous chunks (for sequential execution)
"
" DEPENDENCIES:
" - zzvim_r#text    : Text extraction functions
" - zzvim_r#terminal: Terminal operations
" - zzvim_r#engine  : Messaging and error handling
" - zzvim_r#config  : Configuration settings
" ==============================================================================

" ==============================================================================
" zzvim_r#execute#process(type, options) - Execute R code
" ==============================================================================
" PURPOSE: Executes R code from different sources and handles post-execution
"          cursor movement and navigation
" PARAMETERS:
"   type    - String: Source of code to execute ('line', 'selection', 'chunk', 'previous')
"   options - Dict: Execution options {
"       stay_on_line: Boolean - Whether to stay on the current line after execution (line only)
"   }
" RETURNS:
"   v:true if execution was successful
"   v:false if no content was found or execution failed
" LOGIC:
"   1. Extract the appropriate content based on type
"   2. Send content to R terminal
"   3. Handle post-execution cursor movement based on content type
" ==============================================================================
function! zzvim_r#execute#process(type, options) abort
    " Extract content based on type
    let l:content = zzvim_r#text#extract(a:type, a:options)
    let l:names = {'line': 'current line', 'selection': 'selection', 'chunk': 'current chunk', 'previous': 'previous chunks'}
    
    " Validate content
    if empty(l:content)
        " Generate appropriate error message based on content type
        let l:msg = a:type ==# 'chunk' ? 'Not inside R chunk' :
                  \ a:type ==# 'previous' ? 'No previous chunks' : 'No content'
        
        " Return info message for 'previous' chunks, error for others
        return zzvim_r#engine#msg(l:msg, a:type ==# 'previous' ? 'info' : 'error')
    endif
    
    " Prepare content for execution
    " - For line execution, send just the line as a string
    " - For other types, send the entire list of lines
    let l:send_content = a:type ==# 'line' ? l:content[0] : l:content
    
    " Send content to R terminal
    let l:success = zzvim_r#terminal#send({
        \ 'content': l:send_content, 
        \ 'desc': l:names[a:type]
        \ })
    
    " Handle post-execution navigation if execution was successful
    if l:success
        " For line execution: move to next line unless stay_on_line is true
        if a:type ==# 'line' && !get(a:options, 'stay_on_line', 0)
            normal! j

        " For selection execution: exit visual mode and move to line after selection
        elseif a:type ==# 'selection'
            let l:end = getpos("'>")  " Get end position of visual selection
            execute "normal! \<Esc>"  " Exit visual mode
            call cursor(l:end[1] + 1, 1)  " Move to line after selection

        " For chunk execution: move to next chunk if available
        elseif a:type ==# 'chunk'
            let l:config = zzvim_r#config#get_all()

            " Find the end of current chunk
            let l:end = search(l:config.chunk_end, 'nW')
            if l:end > 0
                " Move to line after chunk end
                call setpos('.', [0, l:end + 1, 1, 0])

                " If there's another chunk, move to its first code line
                if search(l:config.chunk_start, 'W') > 0
                    normal! j
                endif

                " Center the screen on the new position
                normal! zz
            endif
        endif
    endif
    
    return l:success
endfunction