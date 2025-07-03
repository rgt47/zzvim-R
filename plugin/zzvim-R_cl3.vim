" ==============================================================================
" zzvim-R - R development plugin for Vim
" ==============================================================================
" Maintainer:  RG Thomas rgthomas@ucsd.edu
" Version:     2.0
" License:     GPL3 License
"
" DESCRIPTION:
" This plugin provides seamless integration between Vim and R, enabling users
" to send R code from Vim buffers to an R terminal session. It supports both
" plain R files and R Markdown documents with chunk-based navigation and
" execution.
"
" KEY FEATURES:
" - Send individual lines or visual selections to R terminal
" - Navigate and execute R Markdown chunks
" - Object inspection shortcuts (head, str, dim, etc.)
" - Persistent terminal session management
" - Customizable key mappings and behavior
" - Debug logging and error handling
"
" WORKFLOW:
" 1. Open an R file (.r, .rmd, .qmd)
" 2. Press <LocalLeader>r to open R terminal (or it opens automatically)
" 3. Use <CR> to send current line or visual selection to R
" 4. Navigate chunks with <LocalLeader>j/k, execute with <LocalLeader>l
" 5. Use inspection shortcuts like <LocalLeader>h for head(), etc.
"
" ARCHITECTURE:
" The plugin maintains a persistent link between each Vim tab and its R
" terminal by storing both the terminal buffer ID and job ID. This ensures
" commands are sent to the correct R session even when multiple terminals are
" open.
" ==============================================================================

" Prevent loading twice and check Vim version compatibility
if exists('g:loaded_zzvim_r') || v:version < 800
    finish
endif
let g:loaded_zzvim_r = 1

" Save user's cpoptions and set to Vim defaults for script processing
let s:save_cpo = &cpoptions
set cpoptions&vim

"==============================================================================
" CONFIGURATION VARIABLES
"==============================================================================
" These variables control plugin behavior and can be customized in vimrc.
" All variables use the get() function for safe initialization with defaults.

let g:zzvim_r_default_terminal = get(g:, 'zzvim_r_default_terminal', 'R')
let g:zzvim_r_disable_mappings = get(g:, 'zzvim_r_disable_mappings', 0)
let g:zzvim_r_map_submit = get(g:, 'zzvim_r_map_submit', '<CR>')
let g:zzvim_r_terminal_width = get(g:, 'zzvim_r_terminal_width', 100)
let g:zzvim_r_command = get(g:, 'zzvim_r_command', 'R --no-save --quiet')
let g:zzvim_r_chunk_start = get(g:, 'zzvim_r_chunk_start', '^```{')
let g:zzvim_r_chunk_end = get(g:, 'zzvim_r_chunk_end', '^```$')
let g:zzvim_r_debug = get(g:, 'zzvim_r_debug', 0)

" Validate configuration values to prevent errors
if g:zzvim_r_terminal_width < 20 || g:zzvim_r_terminal_width > 200
    let g:zzvim_r_terminal_width = 100
endif

"==============================================================================
" UTILITY FUNCTIONS
"==============================================================================
" These functions provide logging, messaging, and error handling capabilities
" used throughout the plugin. They ensure consistent user feedback and enable
" debugging when issues occur.

" ==============================================================================
" s:log(msg, level) - Centralized logging system
" ==============================================================================
" PURPOSE: Provides structured logging with different verbosity levels
" PARAMETERS:
"   msg   - String message to log
"   level - Integer log level (1=error/warn, 2=info, 3=debug)
" LOGIC:
"   - Only logs if g:zzvim_r_debug >= level
"   - Writes to ~/zzvim_r.log with timestamps
"   - Optionally echoes to command line for level 2+
" ==============================================================================
function! s:log(msg, level) abort
    if g:zzvim_r_debug >= a:level
        let l:timestamp = strftime('%Y-%m-%d %H:%M:%S')
        let l:log_msg = printf('[%s] %s', l:timestamp, a:msg)
        call writefile([l:log_msg], expand('~/zzvim_r.log'), 'a')
        
        if g:zzvim_r_debug >= 2
            echom 'zzvim-R Debug: ' . a:msg
        endif
    endif
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:error(msg) - Display error messages
" ==============================================================================
" PURPOSE: Shows error messages to user with consistent formatting
" PARAMETERS:
"   msg - Error message string
" LOGIC:
"   - Uses ErrorMsg highlight group for visibility
"   - Prefixes message with plugin name
"   - Logs error for debugging purposes
" ==============================================================================
function! s:error(msg) abort
    echohl ErrorMsg
    echom 'zzvim-R: ' . a:msg
    echohl None
    call s:log('ERROR: ' . a:msg, 1)
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:info(msg) - Display informational messages
" ==============================================================================
" PURPOSE: Shows informational messages to user
" PARAMETERS:
"   msg - Information message string
" LOGIC:
"   - Uses normal highlighting for non-intrusive display
"   - Logs message for debugging
" ==============================================================================
function! s:info(msg) abort
    echom 'zzvim-R: ' . a:msg
    call s:log('INFO: ' . a:msg, 2)
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:warn(msg) - Display warning messages
" ==============================================================================
" PURPOSE: Shows warning messages to user with distinctive formatting
" PARAMETERS:
"   msg - Warning message string
" LOGIC:
"   - Uses WarningMsg highlight group for visibility
"   - Logs warning for debugging
" ==============================================================================
function! s:warn(msg) abort
    echohl WarningMsg
    echom 'zzvim-R: ' . a:msg
    echohl None
    call s:log('WARN: ' . a:msg, 1)
endfunction
" ------------------------------------------------------------------------------

"==============================================================================
" TERMINAL MANAGEMENT
"==============================================================================
" This section handles the creation, validation, and management of R terminal
" sessions. The key innovation is tracking both buffer ID and job ID to ensure
" robust terminal state detection across different scenarios.

" ==============================================================================
" s:is_r_terminal_active() - Check if R terminal is running
" ==============================================================================
" PURPOSE: Determines if the current tab has an active R terminal session
" RETURNS: v:true if terminal is active, v:false otherwise
" LOGIC:
"   1. Check if terminal variables exist (quick exit if not)
"   2. Verify the terminal buffer still exists in Vim
"   3. Check if the underlying job/process is still running
"   4. Clean up stale variables if terminal is no longer valid
" VARIABLES USED:
"   t:zzvim_r_terminal_id - Buffer number of the R terminal
"   t:zzvim_r_job_id      - Job ID of the R process
" ==============================================================================
function! s:is_r_terminal_active() abort
    " Check if we have stored terminal info
    if !exists('t:zzvim_r_terminal_id') || !exists('t:zzvim_r_job_id')
        call s:log('No stored terminal info found', 3)
        return v:false
    endif
    
    " Verify terminal buffer still exists
    if !bufexists(t:zzvim_r_terminal_id)
        call s:log('Terminal buffer no longer exists', 2)
        call s:cleanup_terminal_vars()
        return v:false
    endif
    
    " Check if job is still running
    let l:job_status = job_status(t:zzvim_r_job_id)
    if l:job_status !=# 'run'
        call s:log('Terminal job not running: ' . l:job_status, 2)
        call s:cleanup_terminal_vars()
        return v:false
    endif
    
    call s:log('R terminal is active', 3)
    return v:true
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:cleanup_terminal_vars() - Clean up terminal tracking variables
" ==============================================================================
" PURPOSE: Removes stale terminal tracking variables when terminal is closed
" LOGIC:
"   - Safely removes tab-scoped variables if they exist
"   - Prevents errors from undefined variables
"   - Logs cleanup action for debugging
" CALLED BY: s:is_r_terminal_active() when terminal becomes invalid
" ==============================================================================
function! s:cleanup_terminal_vars() abort
    if exists('t:zzvim_r_terminal_id')
        unlet t:zzvim_r_terminal_id
    endif
    if exists('t:zzvim_r_job_id')
        unlet t:zzvim_r_job_id
    endif
    call s:log('Cleaned up terminal variables', 3)
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:open_r_terminal() - Create new R terminal session
" ==============================================================================
" PURPOSE: Opens a new R terminal in a vertical split and tracks it
" RETURNS: v:true if successful, v:false if failed
" LOGIC:
"   1. Verify R executable is available
"   2. Check if terminal already exists (avoid duplicates)
"   3. Save current window for restoration
"   4. Open vertical terminal with configured R command
"   5. Store terminal and job IDs for tracking
"   6. Configure terminal window settings
"   7. Return to original window
" ERROR HANDLING:
"   - Cleans up variables if terminal creation fails
"   - Uses try/catch for Vim exceptions
" ==============================================================================
function! s:open_r_terminal() abort
    " Check if R is available
    if !executable('R')
        call s:error('R is not installed or not in PATH')
        return v:false
    endif

    " Check if terminal already exists
    if s:is_r_terminal_active()
        call s:info('R terminal already active')
        return v:true
    endif

    let l:current_window = winnr()
    
    try
        " Open vertical split and start R terminal
        execute 'vertical terminal ' . g:zzvim_r_command
        
        " Store terminal and job information
        let t:zzvim_r_terminal_id = bufnr('%')
        let t:zzvim_r_job_id = term_getjob(t:zzvim_r_terminal_id)
        
        " Configure terminal window
        call s:configure_terminal_window()
        
        " Return to original window
        execute l:current_window . 'wincmd w'
        
        call s:info('R terminal opened successfully')
        call s:log(printf('Terminal ID: %d, Job ID: %s', 
                    \ t:zzvim_r_terminal_id, string(t:zzvim_r_job_id)), 2)
        return v:true
        
    catch /^Vim\%((\a\+)\)\=:E/
        call s:error('Failed to open R terminal: ' . v:exception)
        call s:cleanup_terminal_vars()
        return v:false
    endtry
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:configure_terminal_window() - Set up terminal window properties
" ==============================================================================
" PURPOSE: Configures the R terminal window with appropriate settings
" LOGIC:
"   - Resizes terminal to configured width
"   - Disables line numbers and related UI elements
"   - Sets buffer options for terminal behavior
"   - Names buffer for easy identification
" CALLED BY: s:open_r_terminal() after terminal creation
" ==============================================================================
function! s:configure_terminal_window() abort
    " Resize terminal
    execute 'vertical resize ' . g:zzvim_r_terminal_width
    
    " Set terminal-specific options
    setlocal norelativenumber
    setlocal nonumber
    setlocal signcolumn=no
    setlocal nobuflisted
    setlocal bufhidden=wipe
    
    " Set buffer name for easier identification
    silent! file [R-Terminal]
endfunction
" ------------------------------------------------------------------------------

"==============================================================================
" CORE SENDING FUNCTIONS
"==============================================================================
" These functions handle the actual communication with the R terminal,
" including command sending, control key handling, and error management.

" ==============================================================================
" s:send_to_r(cmd, stay_on_line) - Send command to R terminal
" ==============================================================================
" PURPOSE: Sends R code to the terminal and optionally moves cursor
" PARAMETERS:
"   cmd           - String command to send to R
"   stay_on_line  - Boolean, if v:true cursor stays on current line
" RETURNS: v:true if successful, v:false if failed
" LOGIC:
"   1. Ensure R terminal exists (create if needed)
"   2. Validate and trim command string
"   3. Send command with newline to terminal
"   4. Move cursor to next line unless stay_on_line is true
" ERROR HANDLING:
"   - Creates terminal if none exists
"   - Skips empty commands but still moves cursor
"   - Catches and reports terminal sending errors
" ==============================================================================
function! s:send_to_r(cmd, stay_on_line) abort
    " Ensure R terminal is available
    if !s:is_r_terminal_active()
        call s:info('No R terminal open - creating new terminal...')
        
        if !s:open_r_terminal()
            call s:error('Could not create R terminal')
            return v:false
        endif
        
        " Brief pause to ensure terminal is ready
        sleep 50m
    endif

    " Process and validate command
    let l:cmd = trim(a:cmd)
    if empty(l:cmd)
        call s:log('Empty command, moving cursor only', 3)
        if !a:stay_on_line
            normal! j
        endif
        return v:true
    endif

    " Send command to terminal
    try
        call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
        call s:log('Sent to R: ' . l:cmd, 2)
        
        " Brief pause for terminal processing
        sleep 10m
        
        " Move cursor if requested
        if !a:stay_on_line
            normal! j
        endif
        
        return v:true
        
    catch /^Vim\%((\a\+)\)\=:E/
        call s:error('Failed to send to R terminal: ' . v:exception)
        return v:false
    endtry
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:send_control_keys(key) - Send control characters to R terminal
" ==============================================================================
" PURPOSE: Sends control characters (like Ctrl-C) to interrupt or control R
" PARAMETERS:
"   key - String representing the control key to send
" RETURNS: v:true if successful, v:false if failed
" LOGIC:
"   1. Verify R terminal is active
"   2. Send the control key directly to terminal
"   3. Create readable description for user feedback
" SPECIAL HANDLING:
"   - Ctrl-C for interrupting running R commands
"   - Other control sequences as needed
" ==============================================================================
function! s:send_control_keys(key) abort
    if !s:is_r_terminal_active()
        call s:error('No R terminal found')
        return v:false
    endif

    try
        call term_sendkeys(t:zzvim_r_terminal_id, a:key)
        
        " Create readable key description for logging
        let l:key_desc = substitute(a:key, "\<C-c>", 'Ctrl-C', '')
        let l:key_desc = substitute(l:key_desc, "\n", 'Enter', 'g')
        
        call s:info('Sent control key: ' . l:key_desc)
        call s:log('Control key sent: ' . l:key_desc, 2)
        return v:true
        
    catch /^Vim\%((\a\+)\)\=:E/
        call s:error('Failed to send control key: ' . v:exception)
        return v:false
    endtry
endfunction
" ------------------------------------------------------------------------------

"==============================================================================
" VISUAL SELECTION FUNCTIONS
"==============================================================================
" These functions handle visual mode selections, extracting the selected text
" and sending it to the R terminal with proper formatting and error handling.

" ==============================================================================
" s:get_visual_selection() - Extract text from visual selection
" ==============================================================================
" PURPOSE: Gets the currently selected text in visual mode
" RETURNS: String containing the selected text with newlines preserved
" LOGIC:
"   1. Get start and end positions of visual selection
"   2. Extract lines within the selection range
"   3. Handle single-line vs multi-line selections differently
"   4. Trim to exact column boundaries for partial line selections
" EDGE CASES:
"   - Single character selections
"   - Multi-line selections with partial first/last lines
"   - Selections spanning entire lines
" ==============================================================================
function! s:get_visual_selection() abort
    let l:pos_start = getpos("'<")
    let l:pos_end = getpos("'>")
    let l:line_start = l:pos_start[1]
    let l:col_start = l:pos_start[2]
    let l:line_end = l:pos_end[1]
    let l:col_end = l:pos_end[2]
    
    let l:lines = getline(l:line_start, l:line_end)
    
    " Handle single vs multi-line selections
    if len(l:lines) == 1
        let l:lines[0] = l:lines[0][l:col_start - 1 : l:col_end - 1]
    else
        let l:lines[-1] = l:lines[-1][: l:col_end - 1]
        let l:lines[0] = l:lines[0][l:col_start - 1:]
    endif
    
    return join(l:lines, "\n")
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:send_visual_to_r() - Send visual selection to R terminal
" 
" ==============================================================================
" PURPOSE: Sends the currently selected text to R and manages cursor position
" RETURNS: v:true if successful, v:false if failed
" LOGIC:
"   1. Store selection positions for cursor management
"   2. Extract selected text using s:get_visual_selection()
"   3. Validate selection is not empty
"   4. Ensure R terminal is available
"   5. Split multi-line selections and send line by line
"   6. Exit visual mode and position cursor after selection
" ERROR HANDLING:
"   - Ensures visual mode is exited even on errors
"   - Creates terminal if needed
"   - Provides user feedback on number of lines sent
" ==============================================================================
function! s:send_visual_to_r() abort
    " Store selection positions
    let l:pos_start = getpos("'<")
    let l:pos_end = getpos("'>")
    
    " Get selected text
    let l:selection = s:get_visual_selection()
    
    if empty(trim(l:selection))
        call s:error('No text selected')
        return v:false
    endif

    " Ensure R terminal is available
    if !s:is_r_terminal_active()
        if !s:open_r_terminal()
            call s:error('Could not create R terminal')
            return v:false
        endif
        sleep 50m
    endif

    " Send selection line by line for better handling
    try
        let l:lines = split(l:selection, "\n")
        let l:sent_count = 0
        
        for l:line in l:lines
            let l:trimmed_line = trim(l:line)
            if !empty(l:trimmed_line)
                call term_sendkeys(t:zzvim_r_terminal_id, 
                                  \ l:trimmed_line . "\n")
                let l:sent_count += 1
                sleep 10m
            endif
        endfor
        
        " Provide user feedback
        let l:line_word = l:sent_count == 1 ? 'line' : 'lines'
        call s:info(printf('Sent %d %s to R', l:sent_count, l:line_word))
        
        " Exit visual mode and position cursor
        execute "normal! \<Esc>"
        call cursor(l:pos_end[1] + 1, 1)
        
        return v:true
        
    catch /^Vim\%((\a\+)\)\=:E/
        call s:error('Failed to send visual selection: ' . v:exception)
        execute "normal! \<Esc>"
        return v:false
    endtry
endfunction
" ------------------------------------------------------------------------------

"==============================================================================
" R MARKDOWN CHUNK FUNCTIONS
"==============================================================================
" This section provides navigation and execution capabilities for R Markdown
" chunks. It uses configurable regex patterns to identify chunk boundaries
" and provides intelligent cursor positioning and code execution.

" ==============================================================================
" s:move_next_chunk() - Navigate to next R Markdown chunk
" ==============================================================================
" PURPOSE: Moves cursor to the beginning of the next R code chunk
" LOGIC:
"   1. Search forward for chunk start pattern
"   2. Move cursor inside the chunk (skip the ```{ line)
"   3. Provide user feedback on navigation result
" BEHAVIOR:
"   - If chunk found: moves to first line inside chunk
"   - If no chunk found: shows warning message
"   - If at last chunk: warns about no content inside
" ==============================================================================
function! s:move_next_chunk() abort
    let l:chunk_start = search(g:zzvim_r_chunk_start, 'W')
    
    if l:chunk_start > 0
        " Move inside the chunk if possible
        if line('.') < line('$')
            normal! j
            call s:info('Moved to next chunk at line ' . line('.'))
        else
            call s:warn('Next chunk found but no content inside')
        endif
    else
        call s:warn('No more chunks found')
    endif
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:move_prev_chunk() - Navigate to previous R Markdown chunk
" ==============================================================================
" PURPOSE: Moves cursor to the beginning of the previous R code chunk
" RETURNS: None (moves cursor as side effect)
" LOGIC:
"   1. Save current position for potential restoration
"   2. Find current chunk start by searching backward
"   3. Find previous chunk end, then its start
"   4. Handle edge case of being in first chunk
"   5. Position cursor inside the target chunk
" EDGE CASES:
"   - First chunk: moves to beginning of current chunk
"   - No chunks: shows warning and stays in place
"   - Invalid chunk structure: restores original position
" ==============================================================================
function! s:move_prev_chunk() abort
    let l:current_pos = getpos('.')
    
    " Find current chunk start
    let l:chunk_start = search(g:zzvim_r_chunk_start, 'bW')
    if l:chunk_start == 0
        call s:warn('No chunks found')
        return
    endif
    
    " Find the chunk end before current chunk
    let l:chunk_end = search(g:zzvim_r_chunk_end, 'bW')
    if l:chunk_end == 0
        " We're in the first chunk, move to its beginning
        call setpos('.', [0, l:chunk_start + 1, 1, 0])
        call s:info('Moved to first chunk at line ' . line('.'))
        return
    endif
    
    " Find the previous chunk start
    let l:prev_chunk_start = search(g:zzvim_r_chunk_start, 'bW')
    if l:prev_chunk_start > 0
        call setpos('.', [0, l:prev_chunk_start + 1, 1, 0])
        call s:info('Moved to previous chunk at line ' . line('.'))
    else
        call s:warn('No previous chunk found')
        call setpos('.', l:current_pos)
    endif
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:submit_chunk() - Execute current R Markdown chunk
" ==============================================================================
" PURPOSE: Finds, extracts, and executes the current R code chunk
" RETURNS: v:true if successful, v:false if failed
" LOGIC:
"   1. Save current position for restoration on error
"   2. Find chunk boundaries using configured patterns
"   3. Extract chunk content between boundaries
"   4. Filter out empty lines and validate content
"   5. Create temporary R file and source it
"   6. Move to next chunk after successful execution
" ERROR HANDLING:
"   - Restores cursor position if chunk boundaries not found
"   - Warns if chunk is empty
"   - Reports sourcing errors
" TEMP FILE MANAGEMENT:
"   - Creates temporary .R file for proper syntax highlighting in R
"   - File is automatically cleaned up by system
" ==============================================================================
function! s:submit_chunk() abort
    let l:save_pos = getpos('.')
    
    " Find chunk boundaries
    let l:chunk_start = search(g:zzvim_r_chunk_start, 'bW')
    if l:chunk_start == 0
        call s:error('No chunk start found')
        return v:false
    endif
    
    let l:chunk_end = search(g:zzvim_r_chunk_end, 'W')
    if l:chunk_end == 0
        call s:error('No chunk end found')
        call setpos('.', l:save_pos)
        return v:false
    endif
    
    " Get chunk content
    let l:chunk_lines = getline(l:chunk_start + 1, l:chunk_end - 1)
    let l:filtered_lines = filter(copy(l:chunk_lines), 
                                 \ '!empty(trim(v:val))')
    
    if empty(l:filtered_lines)
        call s:warn('Current chunk is empty')
        call setpos('.', l:save_pos)
        return v:false
    endif
    
    " Create temporary file and source it
    let l:temp_file = tempname() . '.R'
    call writefile(l:chunk_lines, l:temp_file)
    
    let l:cmd = printf("source('%s', echo=TRUE)", l:temp_file)
    if s:send_to_r(l:cmd, v:true)
        call s:info('Submitted current chunk to R')
        
        " Move to next chunk if available
        call setpos('.', [0, l:chunk_end, 1, 0])
        let l:next_chunk = search(g:zzvim_r_chunk_start, 'W')
        if l:next_chunk > 0
            call setpos('.', [0, l:next_chunk + 1, 1, 0])
        endif
        
        return v:true
    endif
    
    call setpos('.', l:save_pos)
    return v:false
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:collect_previous_chunks() - Gather all chunks before cursor
" ==============================================================================
" PURPOSE: Collects R code from all chunks preceding the current cursor
"          position
" RETURNS: String containing all previous chunk code joined with newlines
" LOGIC:
"   1. Define chunk boundary patterns
"   2. Iterate through all lines from start to current position
"   3. Track when inside/outside chunks using state variable
"   4. Collect non-empty lines when inside chunks
"   5. Join collected lines into single string
" STATE MANAGEMENT:
"   - inside_chunk boolean tracks current parsing state
"   - Transitions on chunk start/end pattern matches
" FILTERING:
"   - Only collects non-empty, non-whitespace lines
"   - Preserves original formatting and indentation
" ==============================================================================
function! s:collect_previous_chunks() abort
    let l:chunk_start_pattern = '^\s*```{.*'
    let l:chunk_end_pattern = '^\s*```$'
    let l:current_line = line('.')
    let l:all_chunk_lines = []
    let l:inside_chunk = v:false

    for l:line_num in range(1, l:current_line)
        let l:line_content = getline(l:line_num)
        
        if l:line_content =~# l:chunk_start_pattern
            let l:inside_chunk = v:true
            continue
        endif
        
        if l:line_content =~# l:chunk_end_pattern
            let l:inside_chunk = v:false
            continue
        endif

        if l:inside_chunk && !empty(trim(l:line_content))
            call add(l:all_chunk_lines, l:line_content)
        endif
    endfor

    return join(l:all_chunk_lines, "\n")
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:submit_previous_chunks() - Execute all chunks before cursor
" ==============================================================================
" PURPOSE: Collects and executes all R code chunks preceding current position
" RETURNS: v:true if successful, v:false if no chunks or execution failed
" LOGIC:
"   1. Use s:collect_previous_chunks() to gather code
"   2. Validate that chunks contain executable code
"   3. Send collected code to R terminal
"   4. Provide user feedback on operation result
" USE CASE:
"   - Useful for re-running analysis up to current point
"   - Helpful when jumping into middle of document
"   - Ensures all dependencies are loaded before current chunk
" ==============================================================================
function! s:submit_previous_chunks() abort
    let l:previous_chunks = s:collect_previous_chunks()

    if empty(trim(l:previous_chunks))
        call s:info('No previous chunks to submit')
        return v:false
    endif

    if s:send_to_r(l:previous_chunks, v:true)
        call s:info('Submitted all previous chunks to R')
        return v:true
    endif
    
    return v:false
endfunction
" ------------------------------------------------------------------------------

"==============================================================================
" R OBJECT INSPECTION FUNCTIONS
"==============================================================================
" These functions provide quick access to common R inspection and utility
" operations, enabling rapid data exploration and analysis.

" ==============================================================================
" s:add_pipe_and_newline() - Insert pipe operator
" ==============================================================================
" PURPOSE: Adds R pipe operator (%>%) on new line for fluent programming
" LOGIC:
"   1. Insert new line after current line with pipe operator
"   2. Move cursor to the new line for continued typing
" R WORKFLOW INTEGRATION:
"   - Supports magrittr/dplyr pipe-based programming style
"   - Enables fluent data manipulation workflows
"   - Maintains proper indentation and formatting
" ==============================================================================
function! s:add_pipe_and_newline() abort
    call append(line('.'), ' %>%')
    normal! j
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:r_action(action, stay_on_line) - Perform R function on current word
" ==============================================================================
" PURPOSE: Applies R function to word under cursor for quick object inspection
" PARAMETERS:
"   action        - String name of R function to apply (e.g., 'head', 'str')
"   stay_on_line  - Boolean, whether to keep cursor on current line
" RETURNS: v:true if successful, v:false if failed
" LOGIC:
"   1. Get word under cursor using expand('<cword>')
"   2. Validate that a word was found
"   3. Construct R command: function(object)
"   4. Send command to R terminal
"   5. Provide user feedback on operation
" COMMON USAGE:
"   - head(df) to see first rows
"   - str(obj) to see structure
"   - dim(matrix) to get dimensions
"   - names(list) to see element names
" ==============================================================================
function! s:r_action(action, stay_on_line) abort
    let l:word = expand('<cword>')
    if empty(l:word)
        call s:error('No word under cursor')
        return v:false
    endif
    
    let l:cmd = printf('%s(%s)', a:action, l:word)
    if s:send_to_r(l:cmd, a:stay_on_line)
        call s:info(printf('Ran %s on %s', a:action, l:word))
        return v:true
    endif
    
    return v:false
endfunction
" ------------------------------------------------------------------------------

"==============================================================================
" PUBLIC INTERFACE FUNCTIONS
"==============================================================================
" These functions provide a clean public API for the plugin, allowing external
" scripts and user commands to interact with the plugin functionality without
" accessing internal implementation details.

" ==============================================================================
" zzvim_r#open_terminal() - Public interface to open R terminal
" ==============================================================================
" PURPOSE: Provides external access to R terminal creation functionality
" RETURNS: v:true if terminal opened successfully, v:false otherwise
" USAGE: Can be called from user commands, other plugins, or vimrc
" DESIGN: Acts as a thin wrapper around internal s:open_r_terminal()
" ==============================================================================
function! s:open_terminal() abort
    return s:open_r_terminal()
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" zzvim_r#submit_line() - Public interface to submit current line
" ==============================================================================
" PURPOSE: Provides external access to line submission functionality
" RETURNS: v:true if line sent successfully, v:false otherwise
" BEHAVIOR: Sends current line to R and moves cursor to next line
" USAGE: Useful for custom mappings or command-line usage
" ==============================================================================
function! s:submit_line() abort
    return s:send_to_r(getline('.'), v:false)
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" zzvim_r#terminal_status() - Display current terminal status
" ==============================================================================
" PURPOSE: Shows user whether R terminal is currently active
" BEHAVIOR: Echoes status message to command line
" USAGE: Useful for debugging connection issues or checking plugin state
" OUTPUT: Either "R terminal is active" or "No R terminal found"
" ==============================================================================
function! s:terminal_status() abort
    if s:is_r_terminal_active()
        echo 'R terminal is active'
    else
        echo 'No R terminal found'
    endif
endfunction
" ------------------------------------------------------------------------------

"==============================================================================
" COMMANDS
"==============================================================================
" User commands provide convenient access to plugin functionality from Vim's
" command-line interface. All commands use the public API functions to
" maintain proper encapsulation.

command! -nargs=0 ROpenTerminal call s:open_terminal()
command! -nargs=0 RSubmitLine call s:submit_line()
command! -nargs=0 RTerminalStatus call s:terminal_status()

"==============================================================================
" MAPPINGS
"==============================================================================
" Key mappings provide the primary user interface for the plugin. All mappings
" are buffer-local and only active for R-related file types. The mappings can
" be disabled by setting g:zzvim_r_disable_mappings = 1.
"
" MAPPING DESIGN PRINCIPLES:
" - Use <LocalLeader> prefix for all plugin-specific mappings
" - <CR> (Enter) for most common action (send line/selection)
" - Logical grouping: j/k for navigation, action letters for inspection
" - Buffer-local to avoid conflicts in non-R files
" - Silent execution to avoid command-line noise
" - Use :<C-u> to clear any range before function calls
"
" MAPPING CATEGORIES:
" - Core: <CR> for sending, <LocalLeader>r for terminal
" - Navigation: j/k for chunk movement
" - Execution: l for chunk, t for previous chunks
" - Control: q for quit, c for interrupt
" - Inspection: d,h,s,p,n,f,g,b,y for various R functions

if !g:zzvim_r_disable_mappings
    augroup zzvim_r_mappings
        autocmd!
        " ==============================================================
        " CORE MAPPINGS - Essential functionality
        " ==============================================================
        " <LocalLeader>r - Open R terminal
        " <CR> - Send current line (normal) or selection (visual) to R
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>r  :<C-u>call <SID>open_r_terminal()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <CR> :<C-u>call <SID>send_to_r(getline('.'), v:false)<CR>
        autocmd FileType r,rmd,qmd xnoremap <buffer> <silent> 
                    \ <CR> :<C-u>call <SID>send_visual_to_r()<CR>
        
        " ==============================================================
        " WORKFLOW HELPERS - Code editing assistance
        " ==============================================================
        " <LocalLeader>o - Add pipe operator (%>%) and new line
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>o :<C-u>call <SID>add_pipe_and_newline()<CR>
        
        " ==============================================================
        " CHUNK NAVIGATION - R Markdown chunk movement
        " ==============================================================
        " <LocalLeader>j - Move to next chunk
        " <LocalLeader>k - Move to previous chunk
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>j :<C-u>call <SID>move_next_chunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>k :<C-u>call <SID>move_prev_chunk()<CR>
        
        " ==============================================================
        " CHUNK EXECUTION - R Markdown chunk running
        " ==============================================================
        " <LocalLeader>l - Submit current chunk and move to next
        " <LocalLeader>t - Submit all previous chunks (setup/dependencies)
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>l :<C-u>call <SID>submit_chunk()<CR>zz
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>t :<C-u>call <SID>submit_previous_chunks()<CR>
        
        " ==============================================================
        " TERMINAL CONTROL - R session management
        " ==============================================================
        " <LocalLeader>q - Send 'Q' to quit R browser/debugger mode
        " <LocalLeader>c - Send Ctrl-C to interrupt running R command
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>q :<C-u>call <SID>send_to_r('Q', v:true)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>c :<C-u>call <SID>send_control_keys("\<C-c>")<CR>
        
        " ==============================================================
        " OBJECT INSPECTION - Quick R object exploration
        " ==============================================================
        " These mappings apply R functions to the word under cursor:
        " <LocalLeader>d - dim()     - dimensions of matrices/data frames
        " <LocalLeader>h - head()    - first few rows/elements
        " <LocalLeader>u - tail()    - last few rows/elements  
        " <LocalLeader>s - str()     - structure of object
        " <LocalLeader>p - print()   - print object to console
        " <LocalLeader>n - names()   - column/element names
        " <LocalLeader>f - length()  - number of elements
        " <LocalLeader>g - glimpse() - dplyr glimpse (tibble structure)
        " <LocalLeader>b - dt()      - data.table print method
        " <LocalLeader>y - help()    - R help documentation
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>d :<C-u>call <SID>r_action('dim', v:true)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>h :<C-u>call <SID>r_action('head', v:true)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>u :<C-u>call <SID>r_action('tail', v:true)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>s :<C-u>call <SID>r_action('str', v:true)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>p :<C-u>call <SID>r_action('print', v:true)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>n :<C-u>call <SID>r_action('names', v:true)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>f :<C-u>call <SID>r_action('length', v:true)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>g :<C-u>call <SID>r_action('glimpse', v:true)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>b :<C-u>call <SID>r_action('dt', v:true)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> 
                    \ <LocalLeader>y :<C-u>call <SID>r_action('help', v:true)<CR>
    augroup END
endif

"==============================================================================
" PLUGIN CLEANUP AND FINALIZATION
"==============================================================================
" Restore user's original cpoptions setting to maintain compatibility with
" their Vim configuration. This is considered best practice for Vim plugins.

" Restore user's cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

" ==============================================================================
" END OF PLUGIN
" ==============================================================================
" This plugin provides comprehensive R integration for Vim with the following
" key capabilities:
"
" 1. TERMINAL MANAGEMENT: Robust R terminal creation and persistence
" 2. CODE EXECUTION: Send lines, selections, and chunks to R
" 3. CHUNK NAVIGATION: Move between R Markdown code chunks
" 4. OBJECT INSPECTION: Quick access to common R inspection functions
" 5. ERROR HANDLING: Comprehensive error detection and user feedback
" 6. CONFIGURABILITY: Extensive customization options
" 7. DEBUGGING: Optional logging for troubleshooting
"
" The plugin maintains a persistent connection between Vim tabs and their
" corresponding R terminals, ensuring commands are sent to the correct R
" session even when multiple terminals are open.
"
" For full documentation and configuration options, see the header comments
" and configuration variable definitions at the top of this file.
" =============================================================================="
