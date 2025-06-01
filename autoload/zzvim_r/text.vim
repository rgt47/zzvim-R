" ==============================================================================
" text.vim - Text extraction and processing for zzvim-R plugin
" ==============================================================================
" File:         autoload/zzvim_r/text.vim
" Maintainer:   RG Thomas <rgthomas@ucsd.edu>
" Version:      2.3
" License:      GPL-3.0
" Description:  Text extraction and navigation functions for zzvim-R plugin
"
" OVERVIEW:
" This module provides specialized functions for extracting and processing text
" from various sources (lines, visual selections, code chunks) in R markdown
" documents and R scripts. It also provides navigation between code chunks and
" utility functions for working with R pipe operators.
"
" FUNCTIONS:
" - zzvim_r#text#extract()      - Extract text based on specified type
" - zzvim_r#text#navigate_chunk() - Navigate between R code chunks
" - zzvim_r#text#add_pipe()     - Add R pipe operator
" - zzvim_r#text#process()      - Process text operations (dispatcher)
"
" INTERNAL FUNCTIONS:
" - s:extract_line()            - Extract current line
" - s:extract_selection()       - Extract visual selection
" - s:extract_chunk()           - Extract current R code chunk
" - s:extract_previous()        - Extract all previous code chunks
"
" DEPENDENCIES:
" - zzvim_r#config              - For configuration settings
" - zzvim_r#engine              - For message handling
"
" ==============================================================================

" ==============================================================================
" TEXT EXTRACTION FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: s:extract_line()
"
" Extract the text from the current line
"
" Parameters:
"   ... - Optional parameters (not used but included for consistent interface)
"
" Returns:
"   Array containing the current line text
" ------------------------------------------------------------------------------
function! s:extract_line(...) abort
    return [getline('.')]
endfunction

" ------------------------------------------------------------------------------
" Function: s:extract_selection()
"
" Extract text from the current visual selection
"
" Handles both single-line and multi-line selections, preserving the exact
" selection boundaries.
"
" Parameters:
"   ... - Optional parameters (not used but included for consistent interface)
"
" Returns:
"   Array of selected lines with appropriate column boundaries applied
"   Empty array if the selection is empty after trimming whitespace
" ------------------------------------------------------------------------------
function! s:extract_selection(...) abort
    let [l:start, l:end] = [getpos("'<"), getpos("'>")]
    let l:lines = getline(l:start[1], l:end[1])
    if empty(l:lines) | return [] | endif
    
    if len(l:lines) == 1
        let l:lines[0] = l:lines[0][l:start[2]-1 : l:end[2]-1]
    else
        let [l:lines[0], l:lines[-1]] = [l:lines[0][l:start[2]-1:], l:lines[-1][:l:end[2]-1]]
    endif
    return empty(trim(join(l:lines, "\n"))) ? [] : l:lines
endfunction

" ------------------------------------------------------------------------------
" Function: s:extract_chunk()
"
" Extract text from the current R code chunk
"
" Searches for chunk delimiters (```{r} and ```) and extracts the content
" between them. Only extracts the chunk if the cursor is positioned within it.
"
" Parameters:
"   ... - Optional parameters (not used but included for consistent interface)
"
" Returns:
"   Array of lines from the current code chunk
"   Empty array if no chunk is found or cursor is not within a chunk
" ------------------------------------------------------------------------------
function! s:extract_chunk(...) abort
    let l:config = zzvim_r#config#get_all()
    let l:start = search(l:config.chunk_start, 'bcnW')
    if l:start == 0 | return [] | endif
    
    let l:pos = getpos('.')
    call setpos('.', [0, l:start, 1, 0])
    let l:end = search(l:config.chunk_end, 'nW')
    call setpos('.', l:pos)
    
    return (l:end > 0 && l:pos[1] > l:start && l:pos[1] < l:end) ? 
         \ getline(l:start + 1, l:end - 1) : []
endfunction

" ------------------------------------------------------------------------------
" Function: s:extract_previous()
"
" Extract text from all R code chunks before the current cursor position
"
" Scans the document from the beginning to the current line, collecting
" all lines within R code chunks.
"
" Parameters:
"   ... - Optional parameters (not used but included for consistent interface)
"
" Returns:
"   Array of lines from all previous code chunks
"   Empty array if no chunks are found
" ------------------------------------------------------------------------------
function! s:extract_previous(...) abort
    let l:config = zzvim_r#config#get_all()
    let [l:lines, l:in_chunk] = [[], v:false]
    for l:i in range(1, line('.'))
        let l:line = getline(l:i)
        let l:in_chunk = l:line =~# l:config.chunk_start ? v:true :
                       \ l:line =~# l:config.chunk_end ? v:false : l:in_chunk
        if l:in_chunk && !empty(trim(l:line)) | call add(l:lines, l:line) | endif
    endfor
    return l:lines
endfunction

" ==============================================================================
" EXTRACTOR REGISTRY AND PUBLIC API
" ==============================================================================

" Registry mapping extraction types to their handler functions
let s:extractors = {
    \ 'line': function('s:extract_line'),
    \ 'selection': function('s:extract_selection'),
    \ 'chunk': function('s:extract_chunk'),
    \ 'previous': function('s:extract_previous')
\ }

" ------------------------------------------------------------------------------
" Function: zzvim_r#text#extract(type, ...)
"
" Main public function for extracting text based on specified type
"
" This function serves as the primary API for retrieving text from different
" sources within the editor (current line, visual selection, code chunks).
"
" Parameters:
"   type    - The type of extraction to perform ('line', 'selection', 'chunk', 'previous')
"   ...     - Optional options to pass to the extractor function
"
" Returns:
"   Array of extracted lines
"   Empty array if extraction fails or no matching extractor is found
" ------------------------------------------------------------------------------
function! zzvim_r#text#extract(type, ...) abort
    let l:options = get(a:, 1, {})
    
    if has_key(s:extractors, a:type)
        return call(s:extractors[a:type], [l:options])
    endif
    
    return []
endfunction

" ==============================================================================
" NAVIGATION AND UTILITY FUNCTIONS
" ==============================================================================

" ------------------------------------------------------------------------------
" Function: zzvim_r#text#navigate_chunk(direction)
"
" Navigate between R code chunks in R markdown documents
"
" Searches for the next or previous R code chunk marker and positions
" the cursor at the beginning of that chunk's content.
"
" Parameters:
"   direction - Either 'next' or 'previous' to indicate search direction
"
" Returns:
"   None
"
" Side effects:
"   - Moves the cursor to the found chunk
"   - Displays a message about the navigation result
" ------------------------------------------------------------------------------
function! zzvim_r#text#navigate_chunk(direction) abort
    let l:config = zzvim_r#config#get_all()
    let l:pos = search(l:config.chunk_start, a:direction ==# 'next' ? 'W' : 'bW')
    if l:pos > 0
        normal! j
        call zzvim_r#engine#msg('Moved to ' . a:direction . ' chunk', 'info')
    else
        call zzvim_r#engine#msg('No ' . a:direction . ' chunk found', 'warn')
    endif
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#text#add_pipe()
"
" Add R pipe operator (%>%) on a new line below the current cursor position
"
" This is a convenience function for working with the magrittr/dplyr pipe
" operator in R code.
"
" Parameters:
"   None
"
" Returns:
"   None
"
" Side effects:
"   - Adds a new line with " %>%" below the current line
"   - Moves the cursor to the newly added line
" ------------------------------------------------------------------------------
function! zzvim_r#text#add_pipe() abort
    call append(line('.'), ' %>%')
    normal! j
endfunction

" ------------------------------------------------------------------------------
" Function: zzvim_r#text#process(type, options)
"
" Process text operations via the common module interface
"
" This function provides a consistent interface for the engine dispatcher
" to delegate text operations.
"
" Parameters:
"   type    - The type of text operation to perform ('line', 'selection', etc.)
"   options - Additional options for the operation
"
" Returns:
"   Array of text lines from the selected source
" ------------------------------------------------------------------------------
function! zzvim_r#text#process(type, options) abort
    return zzvim_r#text#extract(a:type, a:options)
endfunction