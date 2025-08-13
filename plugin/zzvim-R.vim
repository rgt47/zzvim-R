" =============================================================================
" zzvim-R - Advanced R Development Plugin for Vim
" =============================================================================
" Maintainer:  RG Thomas rgthomas@ucsd.edu
" Version:     1.0
" License:     GPL3 License
" Last Change: 2025
"
" PLUGIN OVERVIEW:
" ================
" This plugin creates a seamless integration between Vim and R, transforming
" Vim into a powerful R development environment. It provides:
" 
" 1. Smart Code Submission: Intelligently detects and sends R code blocks
" 2. Terminal Management: Creates and manages persistent R terminal sessions
" 3. Chunk Navigation: Navigate between R Markdown/Quarto code chunks
" 4. Object Inspection: Quick access to R's data examination functions
" 5. Pattern Recognition: Automatically detects R language constructs
"
" ARCHITECTURE:
" =============
" The plugin uses a single-file architecture with clear functional separation:
" - Configuration management and validation
" - Core terminal communication functions
" - Intelligent pattern detection for R code structures
" - Text extraction and processing functions
" - User interface (commands and key mappings)
" - Testing infrastructure
"
" CONFIGURATION VARIABLES:
" ========================
" These global variables can be set in your vimrc to customize behavior.
" VimScript Convention: 'g:' prefix indicates global scope variables.
" These are checked using get(g:, 'variable_name', default_value) pattern.
"
" Core Terminal Configuration:
" ---------------------------
" g:zzvim_r_default_terminal    (string) 
"   Identifier for R terminal sessions. Useful for multiple R versions.
"   Default: 'R'
"   Example: let g:zzvim_r_default_terminal = 'R-4.1'  " Use specific R version
"
" g:zzvim_r_command             (string)
"   Shell command executed to start R. Arguments customize R behavior.
"   Default: 'R --no-save --quiet'
"   --no-save: Don't prompt to save workspace on exit
"   --quiet: Suppress R startup messages
"   Example: let g:zzvim_r_command = 'R --vanilla'  " Clean R session
"
" g:zzvim_r_terminal_width      (number)
"   Terminal window width in columns when opened as vertical split.
"   Default: 100
"   Example: let g:zzvim_r_terminal_width = 120  " Wider terminal
"
" User Interface Configuration:
" ----------------------------
" g:zzvim_r_disable_mappings    (boolean)
"   Master switch to disable all default key mappings.
"   Set to 1 if you want to define your own custom mappings.
"   Default: 0 (mappings enabled)
"   Example: let g:zzvim_r_disable_mappings = 1
"
" g:zzvim_r_map_submit         (string)
"   Key sequence for smart code submission in normal mode.
"   Default: '<CR>' (Enter key)
"   Example: let g:zzvim_r_map_submit = '<Leader>r'  " Use leader+r instead
"
" R Markdown/Quarto Document Configuration:
" ----------------------------------------
" g:zzvim_r_chunk_start         (string)
"   Regular expression pattern matching code chunk start lines.
"   Default: '^```{' (matches ```{r}, ```{python}, etc.)
"   Pattern explanation: ^ = start of line, ``` = literal backticks, { = opening brace
"   Example: let g:zzvim_r_chunk_start = '^```{r'  " Only R chunks
"
" g:zzvim_r_chunk_end           (string)
"   Regular expression pattern matching code chunk end lines.
"   Default: '^```$' (matches ``` at start of line, nothing after)
"   Pattern explanation: ^ = start of line, ``` = literal backticks, $ = end of line
"   Example: let g:zzvim_r_chunk_end = '^```\s*$'  " Allow trailing whitespace
"
" Development and Debugging:
" -------------------------
" g:zzvim_r_debug               (boolean)
"   Enables verbose logging for troubleshooting plugin issues.
"   Creates detailed logs in ~/zzvim_r.log file.
"   Default: 0 (disabled)
"   Example: let g:zzvim_r_debug = 1  " Enable for debugging
"
" KEY MAPPINGS REFERENCE:
" ======================
" VimScript Mapping Convention: <LocalLeader> is typically backslash (\) by default
" Users can customize by setting: let maplocalleader = ","  (use comma instead)
" Mappings are buffer-local and only active in R/Rmd files (controlled by autocmd)
"
" Smart Code Submission (Context-Aware):
" -------------------------------------
"   <CR> (Enter)      - Intelligent code submission based on cursor position
"                      * On function definition: sends entire function
"                      * On control structure (if/for/while): sends entire block  
"                      * On regular line: sends current line only
"                      * Inside function: sends individual line for debugging
"
" Terminal Management:
" -------------------
"   <LocalLeader>r    - Create new R terminal session (vertical split)
"   <LocalLeader>q    - Send 'Q' command to R (quit R session)
"   <LocalLeader>c    - Send Ctrl-C interrupt signal (stop running commands)
"
" Code Enhancement:
" ----------------
"   <LocalLeader>o    - Insert R pipe operator (%>%) and create new line
"                      Positions cursor for chaining operations
"
" R Markdown/Quarto Navigation:
" ----------------------------
"   <LocalLeader>j    - Jump to next code chunk (forward navigation)
"   <LocalLeader>k    - Jump to previous code chunk (backward navigation)
"   <LocalLeader>l    - Execute current chunk (submit all code in current chunk)
"   <LocalLeader>t    - Execute all previous chunks (reproducing analysis up to cursor)
"
" Object Inspection (Data Analysis):
" ---------------------------------
" These mappings execute R functions on the word under cursor
" (place cursor on variable name, press mapping)
"   <LocalLeader>h    - head() - Preview first few rows/elements
"   <LocalLeader>u    - tail() - Preview last few rows/elements  
"   <LocalLeader>s    - str() - Display object structure and data types
"   <LocalLeader>d    - dim() - Show dimensions (rows, columns) of data
"   <LocalLeader>p    - print() - Display complete object contents
"   <LocalLeader>n    - names() - Show column/element names
"   <LocalLeader>f    - length() - Count elements/observations
"   <LocalLeader>g    - glimpse() - Modern tibble structure view (dplyr)
"   <LocalLeader>b    - dt() - data.table print method
"   <LocalLeader>y    - help() - Open R help documentation
"
" EX COMMANDS REFERENCE:
" =====================
" These commands can be executed from Vim's command line (type : to enter command mode)
" Commands with [optional] arguments use word under cursor if no argument provided
" All commands support tab completion for discoverability
"
" Session Management:
" ------------------
"     :ROpenTerminal           - Create new R terminal in vertical split
"                               Uses g:zzvim_r_terminal_width for window size
"                               Executes g:zzvim_r_command to start R
"
" Code Submission (Multiple Methods):
" -----------------------------------
"     :RSendLine               - Send current line to R terminal
"                               Simple line-by-line execution
"     :RSendSmart              - Intelligent context-aware submission
"                               Auto-detects functions, control structures, or lines
"     :RSendFunction           - Force submission of complete function block
"                               Uses brace-matching algorithm to find function boundaries
"     :RSendSelection          - Send visual selection to R (use in visual mode)
"                               Allows precise control over code boundaries
"
" Document Navigation (R Markdown/Quarto):
" ----------------------------------------
"     :RNextChunk              - Navigate to next code chunk
"                               Uses g:zzvim_r_chunk_start pattern for detection
"     :RPrevChunk              - Navigate to previous code chunk  
"                               Handles cursor context to find correct chunk
"     :RSendChunk              - Execute all code in current chunk
"                               Automatically extracts chunk content
"     :RSendPreviousChunks     - Execute all chunks from start to current position
"                               Ensures reproducible analysis workflow
"
" Data Inspection (R Object Analysis):
" ------------------------------------
" Pattern: Commands accept optional argument, use word under cursor if none provided
" Usage: :RHead mydata  OR  position cursor on variable and type :RHead
"     :RHead [object]          - head(object) - Preview first rows/elements
"     :RTail [object]          - tail(object) - Preview last rows/elements
"     :RStr [object]           - str(object) - Examine object structure
"     :RDim [object]           - dim(object) - Get dimensions (rows × columns)
"     :RPrint [object]         - print(object) - Display complete object
"     :RNames [object]         - names(object) - Show variable/column names
"     :RLength [object]        - length(object) - Count elements
"     :RGlimpse [object]       - glimpse(object) - dplyr-style structure view
"     :RSummary [object]       - summary(object) - Statistical summary
"     :RHelp [topic]           - help(topic) - Open R documentation
"
" Session Control:
" ---------------
"     :RQuit                   - Send 'Q' to R (graceful session termination)
"     :RInterrupt              - Send Ctrl-C (interrupt running computation)
"                               Useful for stopping infinite loops or long calculations
"   
" Advanced Workflow Commands:
" --------------------------
"     :RSend {code}            - Execute arbitrary R code string
"                               Example: :RSend library(ggplot2)
"     :RSource {file}          - Source (execute) external R script file
"                               Example: :RSource ~/analysis/helper_functions.R
"     :RLibrary {package}      - Load R package into session
"                               Example: :RLibrary dplyr
"     :RInstall {package}      - Install package from CRAN
"                               Example: :RInstall tidyverse
"
" Data Management Commands:
" ------------------------
"     :RLoad {file}            - Load RDS file (prompts for variable name)
"                               Reads saved R objects from disk
"     :RSave {object} {file}   - Save R object to RDS file
"                               Preserves object for later sessions
"
" Workspace Utilities:
" -------------------
"     :RSetwd [directory]      - Set R working directory
"                               Defaults to Vim's current working directory if no arg
"     :RGetwd                  - Display current R working directory
"     :RLs                     - List all objects in R workspace (ls())
"     :RRm                     - Remove all objects from workspace (rm(list=ls()))
"
" =============================================================================
" PLUGIN IMPLEMENTATION BEGINS
" =============================================================================

" =============================================================================
" PLUGIN INITIALIZATION AND GUARDS
" =============================================================================

" VimScript Best Practice: Prevent multiple loading of same plugin
" This guard checks if plugin was already loaded in current Vim session
if exists('g:loaded_zzvim_r')
    " finish command stops script execution immediately
    " Prevents duplicate function definitions and key mappings
    finish
endif

" Compatibility Check: Ensure Vim version and feature requirements
" v:version is built-in variable containing Vim version as integer (e.g., 801 = 8.01)
" has('terminal') checks if Vim was compiled with terminal emulation support
if v:version < 800 || !has('terminal')
    " echohl sets highlight group for subsequent echo commands
    " ErrorMsg is built-in highlight group (typically red text)
    echohl ErrorMsg
    " echom (echo message) displays message and saves to message history (:messages)
    echom "zzvim-R requires Vim 8.0+ with terminal support"
    " echohl None resets highlighting to normal
    echohl None
    " Stop plugin loading if requirements not met
    finish
endif

" Set plugin loaded flag to prevent re-loading
" Convention: g:loaded_{plugin_name} = 1 indicates successful loading
let g:loaded_zzvim_r = 1
" Plugin version for compatibility checking and debugging
let g:zzvim_r_version = '1.0'

" =============================================================================
" CONFIGURATION INITIALIZATION WITH SAFE DEFAULTS
" =============================================================================
" VimScript Pattern: Use exists() to check if user set custom values
" If user didn't set variable, provide sensible default
" This allows customization while ensuring plugin always has valid values

" Terminal identification string for R session management
if !exists('g:zzvim_r_default_terminal')
    " Default terminal name - simple identifier for session tracking
    let g:zzvim_r_default_terminal = 'R'
endif

" Master switch for all key mappings - allows complete customization
if !exists('g:zzvim_r_disable_mappings')
    " 0 = enable default mappings, 1 = disable (user defines own)
    let g:zzvim_r_disable_mappings = 0
endif

" Key sequence for smart code submission in normal mode
if !exists('g:zzvim_r_map_submit')
    " <CR> = Enter key, most intuitive for "send this code"
    let g:zzvim_r_map_submit = '<CR>'
endif

" Terminal window dimensions (columns)
if !exists('g:zzvim_r_terminal_width')
    " 100 columns provides good balance between terminal and editor space
    let g:zzvim_r_terminal_width = 100
endif

" R startup command with command-line arguments
if !exists('g:zzvim_r_command')
    " --no-save: Don't prompt to save workspace on exit (faster workflow)
    " --quiet: Suppress R startup messages (cleaner terminal)
    let g:zzvim_r_command = 'R --no-save --quiet'
endif

" Regular expression patterns for R Markdown chunk detection
" These patterns are used by search() function to find chunk boundaries
if !exists('g:zzvim_r_chunk_start')
    " Pattern breakdown: ^ = line start, ``` = literal backticks, { = opening brace
    " Matches: ```{r}, ```{python}, ```{sql}, etc.
    let g:zzvim_r_chunk_start = '^```{'
endif

if !exists('g:zzvim_r_chunk_end')
    " Pattern breakdown: ^ = line start, ``` = literal backticks, $ = line end
    " Matches: ``` at start of line with nothing after (chunk closing)
    let g:zzvim_r_chunk_end = '^```$'
endif

" Debug logging level (0=off, 1=basic, 2=verbose)
if !exists('g:zzvim_r_debug')
    " Disabled by default for performance - enable for troubleshooting
    let g:zzvim_r_debug = 0
endif

"------------------------------------------------------------------------------
" Utility Functions
"------------------------------------------------------------------------------
function! s:Log(msg, level) abort
    if get(g:, 'zzvim_r_debug', 0) >= a:level
        call writefile([strftime('%c') . ' - ' . a:msg], expand('~/zzvim_r.log'), 'a')
        " Also display debug message in Vim (when debug enabled)
        echom "Debug: " . a:msg
    endif
endfunction

" Standardized Error Display Function
" Shows error message with consistent formatting and plugin identification
" Parameters:
"   a:msg (string) - Error message to display
function! s:Error(msg) abort
    " echohl ErrorMsg = set text highlighting to error style (usually red)
    echohl ErrorMsg
    " echom = echo message and add to message history (:messages to view)
    " Prefix with plugin name for clear error source identification
    echom "zzvim-R: " . a:msg
    " echohl None = reset highlighting to normal
    echohl None
    " Also log error to debug file for troubleshooting
    call s:Log(a:msg, 1)
endfunction

" =============================================================================
" CORE TERMINAL MANAGEMENT FUNCTIONS
" =============================================================================

" Create and Configure R Terminal Session
" This function creates a persistent R terminal in a vertical split
" Returns: Nothing (void function)
function! s:OpenRTerminal() abort
    " executable('R') checks if R command is available in system PATH
    " Returns 1 if found, 0 if not found
    if !executable('R')
        call s:Error('R is not installed or not in PATH')
        " Early return pattern - exit function if prerequisite not met
        return
    endif

    " Create vertical terminal split and execute R startup command
    " execute = run Ex command from string variable
    " 'vertical term' = create vertical split with terminal
    " g:zzvim_r_command contains full R startup command with arguments
    execute 'vertical term ' . g:zzvim_r_command
    
    " Resize terminal window to configured width
    " 'vertical resize' = adjust vertical split width
    execute 'vertical resize ' . g:zzvim_r_terminal_width

    " Configure terminal buffer display options for better R interaction
    " setlocal = buffer-local settings (only affect current buffer)
    " norelativenumber/nonumber = hide line numbers (distracting in terminal)
    " signcolumn=no = hide sign column (used for diagnostics, not needed in terminal)
    setlocal norelativenumber nonumber signcolumn=no

    " Set tab-local variable to track R terminal existence
    " t: prefix = tab-scoped variable (persists for this tab)
    " Used by other functions to detect if R session is available
    let t:is_r_term = 1

    " Return cursor focus to previous window (usually the editor)
    " wincmd p = window command 'previous' (Ctrl-W p equivalent)
    " Allows immediate code editing without manual window switching
    wincmd p
endfunction

" Send Commands to R Terminal with Auto-Recovery
" Core communication function between Vim and R session
" Parameters:
"   a:cmd (string) - R command/code to execute
"   a:stay_on_line (boolean) - whether to keep cursor on current line (unused in current implementation)
function! s:Send_to_r(cmd, stay_on_line) abort
    " Terminal Session Validation and Auto-Recovery
    " exists('t:is_r_term') checks if tab-local R terminal flag exists
    " This defensive programming pattern handles edge cases gracefully
    if !exists('t:is_r_term') || t:is_r_term != 1
        " User-friendly warning with automatic recovery
        echohl WarningMsg
        echo "No R terminal open - creating new terminal and submitting line..."
        echohl None
        
        " Attempt automatic terminal creation for seamless workflow
        call s:OpenRTerminal()
        
        " Verify recovery was successful before proceeding
        " Double-check prevents errors if R installation has issues
        if !exists('t:is_r_term') || t:is_r_term != 1
            call s:Error("Could not create R terminal. Please check R installation.")
            " Fail gracefully rather than causing Vim errors
            return
        endif
        
        " Brief pause to allow terminal initialization
        " sleep 100m = sleep 100 milliseconds
        " Prevents race condition where terminal isn't fully ready for input
        sleep 100m
    endif

    " Terminal Discovery and Validation
    " term_list() returns list of all terminal buffer numbers in current session
    let l:terms = term_list()
    if empty(l:terms)
        " No terminals found - this shouldn't happen after auto-creation above
        call s:Error("No active terminals found")
        return
    endif

    " Command Transmission with Error Handling
    try
        " Use first terminal in list (most recently created)
        " In practice, this will be our R terminal since we just created it
        let l:target_terminal = l:terms[0]
        
        " Input Validation - avoid sending empty commands to R
        " trim() removes leading/trailing whitespace
        " !empty() ensures we have actual content to send
        if !empty(trim(a:cmd))
            " Terminal Status Verification
            " term_getstatus() returns terminal state ("running", "finished", etc.)
            " =~# is case-sensitive regex match operator
            if term_getstatus(l:target_terminal) =~# 'running'
                " Send command with newline to execute in R
                " term_sendkeys() simulates typing in terminal
                " "\n" = newline character to execute command
                call term_sendkeys(l:target_terminal, a:cmd . "\n")
                
                " Brief delay for terminal command processing
                " Allows R to begin processing before next command
                sleep 10m
            else
                " Terminal exists but isn't running - likely crashed or closed
                call s:Error("Terminal is not active")
                return
            endif
        endif
    catch
        " Exception Handling for Terminal Communication Errors
        " v:exception contains error message from failed operation
        " This catches Vim errors like terminal not responding, etc.
        call s:Error("Failed to send to R terminal: " . v:exception)
        return
    endtry

    " Optional Cursor Movement (Legacy Feature)
    " a:stay_on_line parameter allows controlling cursor behavior
    " Currently unused but maintained for backward compatibility
    if !a:stay_on_line
        " normal! j = move cursor down one line (! = don't use mappings)
        " Useful for rapid line-by-line execution workflow
        normal! j
    endif
endfunction

" Extract Text from Visual Selection with Precise Boundaries
" Handles partial line selections and multi-line visual blocks
" Returns: String containing selected text with proper line breaks
function! s:GetVisualSelection() abort
    " Get Visual Selection Boundaries
    " getpos("'<") = start of visual selection (mark '<)
    " getpos("'>") = end of visual selection (mark '>)
    " [1:2] extracts line and column numbers from position list
    " Position format: [bufnum, line, col, off] - we need line and col
    let [l:line_start, l:col_start] = getpos("'<")[1:2]
    let [l:line_end, l:col_end] = getpos("'>')[1:2]
    
    " Extract All Lines in Selection Range
    " getline(start, end) returns list of complete lines
    let l:lines = getline(l:line_start, l:line_end)

    " Trim Selection Boundaries for Partial Line Selections
    " Handle case where selection doesn't include entire first/last lines
    " VimScript array indexing: [-1] = last element, [0] = first element
    " String slicing: [start:end] where end is exclusive
    let l:lines[-1] = l:lines[-1][: l:col_end - 1]  " Trim end of last line
    let l:lines[0] = l:lines[0][l:col_start - 1:]    " Trim start of first line

    " Reconstruct Multi-line String
    " join(list, separator) combines list elements with separator
    " "\n" preserves original line breaks for R execution
    return join(l:lines, "\n")
endfunction

" Insert R Pipe Operator for Functional Programming Workflows
" Adds %>% operator on new line and positions cursor for chaining
" Used extensively in tidyverse/dplyr data manipulation pipelines
function! s:AddPipeAndNewLine() abort
    " Insert pipe operator on new line after current line
    " line('.') = current line number
    " append(line, text) = insert text after specified line
    " ' %>%' includes leading space for proper formatting
    call append(line('.'), ' %>%')
    
    " Move cursor to the newly created line
    " normal! j = move down one line (! prevents mapping interference)
    " Positions cursor at end of pipe operator for immediate typing
    normal! j
endfunction

" =============================================================================
" R MARKDOWN/QUARTO CHUNK NAVIGATION SYSTEM
" =============================================================================
" These functions enable seamless navigation between code chunks in literate
" programming documents, essential for interactive data analysis workflows

" Navigate to Next Code Chunk (Forward Direction)
" Finds the next chunk boundary and positions cursor inside for editing
function! s:MoveNextChunk() abort
    " Get chunk start pattern from user configuration with safe fallback
    " get(g:, 'var', default) safely retrieves global variable
    let l:chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{')
    
    " Search for next chunk start from current position
    " search(pattern, flags): 'W' = wrap around file end, don't wrap
    " Returns line number if found, 0 if not found
    let l:chunk_start = search(l:chunk_start_pattern, 'W')

    " Process Search Results and Position Cursor
    if l:chunk_start
        " Chunk found - move cursor inside chunk for immediate editing
        " line('.') = current line number, line('$') = last line in file
        if line('.') < line('$')
            " Move one line down to enter chunk content area
            normal! j
            " Provide user feedback about navigation success
            echom "Moved inside the next chunk at line " . line('.')
        else
            " Edge case: chunk header is last line (malformed document)
            call s:Error("Next chunk found, but no lines inside the chunk.")
        endif
    else
        " No more chunks found in forward direction
        call s:Error("No more chunks found.")
    endif
endfunction


" Navigate to Previous Code Chunk (Backward Direction)
" Complex algorithm handling cursor context and chunk boundaries
" More sophisticated than forward navigation due to context awareness
function! s:MovePrevChunk() abort
    " Get chunk detection pattern from configuration
    let chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{')
    
    " Position State Management
    " Save current position for potential restoration on failure
    " getpos('.') returns [bufnum, line, col, off] - full cursor position
    let current_pos = getpos('.')
    " line('.') gets just the line number for simpler arithmetic
    let current_line_num = line('.')
    
    " Context Detection: Find Current Chunk Relationship
    " search(pattern, flags): 
    " 'b' = backward search, 'c' = accept cursor position, 
    " 'n' = don't move cursor, 'W' = don't wrap
    " This finds the chunk start we're currently in or just passed
    let current_chunk_start = search(chunk_start_pattern, 'bcnW')
    
    " Smart Context Handling Based on Cursor Position
    " Algorithm determines whether we're inside a chunk or between chunks
    if current_chunk_start > 0
        " Case 1: We're inside a chunk - need to exit before finding previous
        if current_line_num > current_chunk_start
            " Position cursor at current chunk start for reference
            " cursor(line, col) moves cursor without changing view
            call cursor(current_chunk_start, 1)
        endif
        
        " Navigate to Search Starting Position
        " Move one line above current chunk to avoid finding same chunk
        " Boundary check prevents going above file start
        if current_chunk_start > 1
            call cursor(current_chunk_start - 1, 1)
        endif
    endif
    
    " Execute Previous Chunk Search
    " search() with 'bW' = backward search without wrapping
    " Starting from position above current chunk (or cursor position)
    let prev_chunk_start = search(chunk_start_pattern, 'bW')
    
    " Process Search Results and Navigate
    if prev_chunk_start > 0
        " Success: Previous chunk found
        " Position cursor inside chunk content area (after header line)
        call cursor(prev_chunk_start + 1, 1)
        " normal! zz centers current line in window for better visibility
        normal! zz
        " Provide success feedback with line number
        echom "Moved to previous chunk at line " . line('.')
        " Return success indicator (used by calling functions)
        return 1
    else
        " Failure: No previous chunk exists
        " Restore original cursor position (undo any movement)
        " setpos('.', pos) restores complete cursor position
        call setpos('.', current_pos)
        " Inform user of navigation boundary
        echom "No previous chunk found"
        " Return failure indicator
        return 0
    endif
endfunction


function! s:SubmitChunk() abort
    " Use the generalized function for chunk submission
    call s:SendToR('chunk')
    
    " Navigate to next chunk after submission (preserve original behavior)
    let save_pos = getpos('.')
    let chunk_end_pattern = get(g:, 'zzvim_r_chunk_end', '^```$')
    let chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{')
    
    let chunk_end = search(chunk_end_pattern, 'W')
    if chunk_end > 0
        call setpos('.', [0, chunk_end, 1, 0])
        let next_chunk_start = search(chunk_start_pattern, 'W')
        if next_chunk_start > 0
            let line_num = next_chunk_start
            let line_count = line('$')
            while line_num <= line_count
                let current_line = getline(line_num)
                if current_line !~# '^\s*$' && current_line !~# chunk_start_pattern 
                    \ && current_line !~# chunk_end_pattern
                    break
                endif
                let line_num += 1
            endwhile
            if line_num <= line_count
                call setpos('.', [0, line_num, 1, 0])
            endif
        endif
    else
        call setpos('.', save_pos)
    endif
endfunction

"------------------------------------------------------------------------------
" Mapping to Collect and Submit All Previous Chunks
"------------------------------------------------------------------------------

" Collect and submit all previous chunks to R
function! s:CollectAndSubmitPreviousChunks() abort
    " Use the generalized SendToR system for previous chunks
    call s:SendToR('previous_chunks')
endfunction

"------------------------------------------------------------------------------
" Function: Send control keys (e.g., 'Q' or Ctrl-C)
"------------------------------------------------------------------------------
function! s:SendControlKeys(key) abort
    try
        let terms = term_list()
        if empty(terms)
            call s:Error("No active terminals found.")
            return
        endif

        " Assume the first terminal in the list is the target
        let target_terminal = terms[0]
        " Use term_sendkeys to send the control key
        call term_sendkeys(target_terminal, a:key)
        echom "Sent control key: " . a:key
    catch
        call s:Error("Failed to send control key: " . a:key)
    endtry
endfunction

"------------------------------------------------------------------------------
" Function: Perform an R action on the word under the cursor
"------------------------------------------------------------------------------
function! s:RAction(action, stay_on_line) abort
    call s:RCommandWithArg(a:action, '', a:stay_on_line)
endfunction

"------------------------------------------------------------------------------
" Function: Generalized text sending to R with smart detection
"------------------------------------------------------------------------------
" =============================================================================
" GENERALIZED INTELLIGENT CODE SUBMISSION SYSTEM
" =============================================================================
" This is the main orchestrating function that coordinates smart code detection
" and submission. It represents the core innovation of the plugin.

" Universal Code Submission Function with Smart Detection
" Handles all types of code submission through unified interface
" Parameters:
"   a:selection_type (string) - Type of selection: '', 'line', 'function', 'chunk', 'selection'
"   ... (variadic) - Optional additional parameters for future extensibility
function! s:SendToR(selection_type, ...) abort
    " Phase 1: Text Extraction with Intelligent Detection
    " Delegate to specialized function that handles pattern recognition
    let text_lines = s:GetTextByType(a:selection_type)
    
    " Input Validation - Ensure we have content to send
    if empty(text_lines)
        call s:Error("No text to send to R.")
        return  " Fail gracefully without causing Vim errors
    endif
    
    " Phase 2: Reliable Code Transmission via Temporary File
    " Use temp file approach to handle any code size and avoid terminal limits
    " tempname() generates unique temporary file path
    let temp_file = tempname()
    " writefile(list, filename) writes list of lines to file
    call writefile(text_lines, temp_file)
    
    " Construct R source() command with echo for visibility
    " source() executes R script file, echo=T shows code as it runs
    " Single quotes prevent shell interpretation of special characters
    let cmd = "source('" . temp_file . "', echo=T)\n"
    
    " Phase 3: Submit to R Terminal
    " Use existing terminal communication infrastructure
    call s:Send_to_r(cmd, 0)
    
    " Phase 4: User Feedback
    " Provide clear information about what was submitted
    let line_count = len(text_lines)
    " Smart pluralization for grammatically correct feedback
    echom "Sent " . line_count . " line" . (line_count == 1 ? "" : "s") . " to R."
endfunction

" Smart Text Extraction Dispatcher with Pattern Recognition
" Central intelligence function that determines what code to extract based on context
" This function embodies the plugin's smart detection capabilities
" Parameters:
"   a:selection_type (string) - Explicit type or empty for auto-detection
" Returns: List of lines ready for R execution
function! s:GetTextByType(selection_type) abort
    " Intelligent Auto-Detection Mode
    " When no explicit type specified, analyze current line for code patterns
    " This enables the smart <CR> key behavior
    if empty(a:selection_type) && s:IsBlockStart(getline('.'))
        " Current line starts a code block - extract complete block
        " getline('.') gets content of current line for pattern analysis
        return s:GetCodeBlock()
    endif
    
    " Explicit Selection Type Dispatch
    " Route to appropriate extraction function based on user's explicit choice
    " Using ==# for exact string comparison (case-sensitive)
    if a:selection_type ==# 'selection'
        " Visual selection mode - extract user-highlighted text
        return s:GetVisualSelectionLines()
    elseif a:selection_type ==# 'chunk'
        " R Markdown chunk mode - extract current chunk content
        return s:GetCurrentChunk()
    elseif a:selection_type ==# 'previous_chunks'
        " Cumulative execution - extract all previous chunks for reproducibility
        return s:GetPreviousChunks()
    elseif a:selection_type ==# 'function'
        " Force function extraction even if pattern detection fails
        return s:GetCodeBlock()
    else
        " Default Fallback: Single Line or Smart Detection
        " Return current line as single-element list
        " This handles simple assignments, function calls, and individual statements
        return [getline('.')]
    endif
endfunction

"------------------------------------------------------------------------------
" =============================================================================
" INTELLIGENT R CODE PATTERN DETECTION ENGINE
" =============================================================================
" These functions implement the core intelligence for recognizing R language
" constructs and determining optimal code submission boundaries

" Detect R Code Block Starting Patterns
" Analyzes a line to determine if it begins a multi-line code structure
" This is the heart of the smart submission system
" Parameters:
"   a:line (string) - Line of code to analyze
" Returns: 1 if line starts a block, 0 otherwise
function! s:IsBlockStart(line) abort
    " Advanced Regex Pattern for R Language Constructs
    " Using very-magic mode (\v) for cleaner regex syntax
    " Pattern breakdown:
    " 1. '.*function\s*\(' - Function definitions (any position on line)
    "    Matches: 'my_func <- function(x)', '  f <- function()'
    " 2. '^\s*(if|for|while)\s*\(' - Control structures at line start
    "    Matches: 'if (x > 0)', '  for (i in 1:10)', 'while (TRUE)'
    " 3. '^\s*(repeat\s*)?\{' - Repeat loops and standalone blocks
    "    Matches: 'repeat {', '  {' (standalone code blocks)
    " 4. '^\s*[a-zA-Z_][a-zA-Z0-9_.]*\s*\(' - Function calls with opening parenthesis
    "    Matches: 'p_load(', 'data.frame(', 'ggplot('
    "    This detects multi-line function calls that need parenthesis matching
    " 
    " =~# operator: case-sensitive regular expression match
    " Returns 1 (true) if pattern matches, 0 (false) otherwise
    return a:line =~# '\v(.*function\s*\(|^\s*(if|for|while)\s*\(|^\s*(repeat\s*)?\{|^\s*[a-zA-Z_][a-zA-Z0-9_.]*\s*\()'
endfunction

" Extract Complete Code Block Using Sophisticated Brace Matching
" Implements balanced brace algorithm to find exact code block boundaries
" Handles nested structures like functions within functions, nested if statements
" Returns: List of lines comprising the complete code block
function! s:GetCodeBlock() abort
    " Position State Management
    " Save current cursor position for restoration if algorithm fails
    let save_pos = getpos('.')
    let current_line_num = line('.')  " Starting line number
    let current_line = getline('.')   " Current line content
    
    " Phase 1: Detect Block Type and Locate Opening Character
    " Search for either opening brace { or opening parenthesis (
    let block_line = current_line_num
    let found_opening = 0
    let block_type = ''  " Will be 'brace' or 'paren'
    
    " Limited Forward Search for Opening Character
    " Prevents infinite search in malformed code
    while block_line <= line('$')  " line('$') = last line in file
        let line_content = getline(block_line)
        " Check for opening brace first (original behavior)
        if line_content =~ '{'
            let found_opening = 1
            let block_type = 'brace'
            break  " Exit loop when brace found
        endif
        " Check for opening parenthesis (new functionality)
        if line_content =~ '('
            let found_opening = 1
            let block_type = 'paren'
            break  " Exit loop when parenthesis found
        endif
        let block_line += 1
        " Safety limit: don't search beyond 5 lines for braces, 1 line for parens
        " Parentheses are typically on same line as function call
        if block_line > current_line_num + 5
            break
        endif
    endwhile
    
    " Error Handling: No Opening Character Found
    if !found_opening
        " Restore cursor position and report failure
        call setpos('.', save_pos)
        call s:Error("No opening brace or parenthesis found for code block.")
        " Return empty list to indicate failure
        return []
    endif
    
    " Phase 2: Balanced Character Counting Algorithm
    " Find matching closing character by counting balance (braces or parentheses)
    call cursor(block_line, 1)  " Position at opening character line
    let char_count = 0         " Running balance of open vs close characters
    let start_line = current_line_num  " Block starts at original cursor position
    let end_line = -1          " Will store line number of matching close character
    
    " Set Character Patterns Based on Block Type
    if block_type == 'brace'
        let open_pattern = '[^{]'   " Match everything except opening braces
        let close_pattern = '[^}]'  " Match everything except closing braces
    else  " block_type == 'paren'
        let open_pattern = '[^(]'   " Match everything except opening parentheses
        let close_pattern = '[^)]'  " Match everything except closing parentheses
    endif
    
    " Iterate Through Lines Counting Characters
    for line_num in range(block_line, line('$'))
        let line_content = getline(line_num)
        
        " Advanced Character Counting Using String Substitution
        " substitute(string, pattern, replacement, flags)
        " Result: string length = number of opening/closing characters
        let open_chars = len(substitute(line_content, open_pattern, '', 'g'))
        let close_chars = len(substitute(line_content, close_pattern, '', 'g'))
        
        " Update Running Character Balance
        " Positive = more opens than closes, Zero = balanced
        let char_count += open_chars - close_chars
        
        " Critical Balance Detection
        " When char_count reaches 0, we've found the matching closing character
        " Additional condition ensures we've actually processed characters on this line
        " (prevents false positive on lines with no characters)
        if char_count == 0 && (open_chars > 0 || close_chars > 0)
            let end_line = line_num
            break  " Exit loop - block boundary found
        endif
    endfor
    
    " Restore Original Cursor Position
    " Always restore position regardless of success/failure
    call setpos('.', save_pos)
    
    " Validate Algorithm Success
    if end_line == -1
        " No matching character found - malformed code or infinite loop
        let error_msg = block_type == 'brace' ? "No matching closing brace found." : "No matching closing parenthesis found."
        call s:Error(error_msg)
        return []  " Return empty list to indicate failure
    endif
    
    " Extract Complete Code Block
    " getline(start, end) returns list of lines from start to end (inclusive)
    " This is the complete, balanced code block ready for R execution
    return getline(start_line, end_line)
endfunction

"------------------------------------------------------------------------------
" Function: Get visual selection as lines
"------------------------------------------------------------------------------
function! s:GetVisualSelectionLines() abort
    " Reuse existing GetVisualSelection function and split into lines
    return split(s:GetVisualSelection(), '\n')
endfunction

"------------------------------------------------------------------------------
" Function: Get current chunk (reuse existing logic)
"------------------------------------------------------------------------------
function! s:GetCurrentChunk() abort
    let save_pos = getpos('.')
    let chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{')
    let chunk_end_pattern = get(g:, 'zzvim_r_chunk_end', '^```$')
    
    let chunk_start = search(chunk_start_pattern, 'bW')
    if chunk_start == 0
        call setpos('.', save_pos)
        return []
    endif
    let chunk_end = search(chunk_end_pattern, 'W')
    if chunk_end == 0
        call setpos('.', save_pos)
        return []
    endif
    
    call setpos('.', save_pos)
    return getline(chunk_start + 1, chunk_end - 1)
endfunction

"------------------------------------------------------------------------------
" Function: Get all previous chunks (reuse existing logic)
"------------------------------------------------------------------------------
function! s:GetPreviousChunks() abort
    " Get patterns for R code chunks from plugin config
    let l:chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{')
    let l:chunk_end_pattern = get(g:, 'zzvim_r_chunk_end', '^```$')
    
    " Get the current line number
    let l:current_line = line('.')
    
    " Initialize variables
    let l:all_chunk_lines = []
    let l:inside_chunk = 0
    
    " Loop through lines up to the current line (exclusive)
    for l:line_num in range(1, l:current_line - 1)
        let l:line_content = getline(l:line_num)
        
        " Check if the line is a chunk start
        if l:line_content =~ l:chunk_start_pattern
            let l:inside_chunk = 1
            continue
        endif
        
        " Check if the line is a chunk end
        if l:line_content =~ l:chunk_end_pattern
            let l:inside_chunk = 0
            continue
        endif
        
        " If inside a chunk, collect the line
        if l:inside_chunk
            call add(l:all_chunk_lines, l:line_content)
        endif
    endfor
    
    " Return the collected lines as array (for consistency with other GetText functions)
    return l:all_chunk_lines
endfunction

"------------------------------------------------------------------------------
" Function: Smart submission - uses generalized function with auto-detection
"------------------------------------------------------------------------------


"------------------------------------------------------------------------------
" Mappings
"------------------------------------------------------------------------------
"
"
"
if !g:zzvim_r_disable_mappings
    augroup zzvim_RMarkdown
        autocmd!
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>r  :call <SID>OpenRTerminal()<CR>
        autocmd FileType r,rmd,qmd xnoremap <buffer> <silent> <CR>    :<C-u>call <SID>SendToR('selection')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <CR>  :call <SID>SendToR('')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>o   :call <SID>AddPipeAndNewLine()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>j   :call <SID>MoveNextChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>k :call <SID>MovePrevChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>l :call <SID>SubmitChunk()<CR>zz
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>t :call <SID>CollectAndSubmitPreviousChunks()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>q :call <SID>SendControlKeys("Q")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>c :call <SID>SendControlKeys("\<C-c>")<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>d :call <SID>RAction("dim", 1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>h :call <SID>RAction("head",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>u :call <SID>RAction("tail",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>s :call <SID>RAction("str",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p :call <SID>RAction("print",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>n :call <SID>RAction("names",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>f :call <SID>RAction("length",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>g :call <SID>RAction("glimpse",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>b :call <SID>RAction("dt",1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>y :call <SID>RAction("help", 1)<CR>
        " Additional generalized send mappings
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>sf :call <SID>SendToR('function')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>sl :call <SID>SendToR('line')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>sa :call <SID>SendToR('')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>sp :call <SID>SendToR('previous_chunks')<CR>
    augroup END
endif

"------------------------------------------------------------------------------
" Ex Commands
"------------------------------------------------------------------------------

" Core Operations
command! -bar ROpenTerminal call s:OpenRTerminal()
command! -bar RSendLine call s:SendToR('line')
command! -bar RSendSelection call s:SendToR('selection')
command! -bar RSendFunction call s:SendToR('function')
command! -bar RSendSmart call s:SendToR('')
command! -bar RAddPipe call s:AddPipeAndNewLine()

" Chunk Navigation and Execution
command! -bar RNextChunk call s:MoveNextChunk()
command! -bar RPrevChunk call s:MovePrevChunk()
command! -bar RSendChunk call s:SendToR('chunk')
command! -bar RSendPreviousChunks call s:SendToR('previous_chunks')

" Object Inspection Commands (with optional arguments)
command! -bar -nargs=? RHead call s:RCommandWithArg('head', <q-args>)
command! -bar -nargs=? RStr call s:RCommandWithArg('str', <q-args>)
command! -bar -nargs=? RDim call s:RCommandWithArg('dim', <q-args>)
command! -bar -nargs=? RPrint call s:RCommandWithArg('print', <q-args>)
command! -bar -nargs=? RNames call s:RCommandWithArg('names', <q-args>)
command! -bar -nargs=? RLength call s:RCommandWithArg('length', <q-args>)
command! -bar -nargs=? RGlimpse call s:RCommandWithArg('glimpse', <q-args>)
command! -bar -nargs=? RTail call s:RCommandWithArg('tail', <q-args>)
command! -bar -nargs=? RHelp call s:RCommandWithArg('help', <q-args>)
command! -bar -nargs=? RSummary call s:RCommandWithArg('summary', <q-args>)

" Control Commands
command! -bar RQuit call s:SendControlKeys("Q")
command! -bar RInterrupt call s:SendControlKeys("\<C-c>")

" Advanced Commands with Argument Handling
command! -bar -nargs=1 RSend call s:RSendCommand(<q-args>)
command! -bar -nargs=1 RSource call s:RSourceCommand(<q-args>)
command! -bar -nargs=1 RLibrary call s:RLibraryCommand(<q-args>)
command! -bar -nargs=1 RInstall call s:RInstallCommand(<q-args>)
command! -bar -nargs=1 RLoad call s:RLoadCommand(<q-args>)
command! -bar -nargs=1 RSave call s:RSaveCommand(<q-args>)

" Utility Commands
command! -bar -nargs=? RSetwd call s:RSetwdCommand(<q-args>)
command! -bar RGetwd call s:Send_to_r('getwd()', 1)
command! -bar RLs call s:Send_to_r('ls()', 1)
command! -bar RRm call s:Send_to_r('rm(list=ls())', 1)

"------------------------------------------------------------------------------
" Helper Functions for Commands
"------------------------------------------------------------------------------

" Generic function for R commands that can take optional arguments
function! s:RCommandWithArg(action, arg, ...) abort
    let stay_on_line = a:0 > 0 ? a:1 : 1
    
    if empty(a:arg)
        " Use word under cursor if no argument provided
        let word = expand('<cword>')
        if empty(word)
            call s:Error("No argument provided and no word under cursor for " . a:action . "()")
            return
        endif
        let target = word
    else
        let target = a:arg
    endif
    
    call s:Send_to_r(a:action . '(' . target . ')', stay_on_line)
    echom "Executed " . a:action . "(" . target . ")"
endfunction

" Helper for simple R commands with validation
function! s:SimpleRCommand(arg, error_msg, cmd_template, success_msg) abort
    if empty(a:arg)
        call s:Error(a:error_msg)
        return
    endif
    let expanded_arg = expand(a:arg)
    call s:Send_to_r(printf(a:cmd_template, expanded_arg), 0)
    echom printf(a:success_msg, expanded_arg)
endfunction

" Send arbitrary R code
function! s:RSendCommand(code) abort
    call s:SimpleRCommand(a:code, "No R code provided", "%s", "Sent: %s")
endfunction

" Source an R file
function! s:RSourceCommand(file) abort
    call s:SimpleRCommand(a:file, "No file path provided", "source('%s')", "Sourced: %s")
endfunction

" Load a library/package
function! s:RLibraryCommand(package) abort
    call s:SimpleRCommand(a:package, "No package name provided", "library(%s)", "Loaded library: %s")
endfunction

" Install a package
function! s:RInstallCommand(package) abort
    call s:SimpleRCommand(a:package, "No package name provided", "install.packages('%s')", "Installing package: %s")
endfunction

" Load RDS file
function! s:RLoadCommand(file) abort
    if empty(a:file)
        call s:Error("No file path provided")
        return
    endif
    
    let expanded_file = expand(a:file)
    let var_name = input("Variable name (or press Enter for auto): ")
    
    if empty(var_name)
        " Generate variable name from filename
        let var_name = fnamemodify(expanded_file, ':t:r')
        let var_name = substitute(var_name, '[^a-zA-Z0-9_]', '_', 'g')
    endif
    
    call s:Send_to_r(var_name . " <- readRDS('" . expanded_file . "')", 0)
    echom "Loaded " . expanded_file . " into " . var_name
endfunction

" Save to RDS file
function! s:RSaveCommand(args) abort
    if empty(a:args)
        call s:Error("Usage: RSave object filename")
        return
    endif
    
    let parts = split(a:args)
    if len(parts) < 2
        call s:Error("Usage: RSave object filename")
        return
    endif
    
    let object = parts[0]
    let filename = join(parts[1:])
    let expanded_file = expand(filename)
    
    call s:Send_to_r("saveRDS(" . object . ", '" . expanded_file . "')", 0)
    echom "Saved " . object . " to " . expanded_file
endfunction

" Set working directory
function! s:RSetwdCommand(dir) abort
    let target_dir = empty(a:dir) ? getcwd() : expand(a:dir)
    call s:Send_to_r("setwd('" . target_dir . "')", 0)
    echom "Set R working directory to: " . target_dir
endfunction

"------------------------------------------------------------------------------
" Testing Functions (Public wrappers for script-local functions)
"------------------------------------------------------------------------------

" Public wrapper for testing s:IsBlockStart()
function! ZzvimRTestIsBlockStart(line) abort
    return s:IsBlockStart(a:line)
endfunction

" Public wrapper for testing s:GetTextByType()
function! ZzvimRTestGetTextByType(selection_type) abort
    return s:GetTextByType(a:selection_type)
endfunction
