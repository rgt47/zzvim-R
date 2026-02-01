scriptencoding utf-8
" ===========================================================================
" zzvim-R - Advanced R Development Plugin for Vim
" ==========================================================================="
" Maintainer:  RG Thomas rgthomas@ucsd.edu
" Version:     1.0
" License:     GPL3 License
" Last Change: 2025
"
" PLUGIN OVERVIEW:
" ================
" This plugin provides integration between Vim and R. It implements:
"
" 1. Code Submission: Pattern-based detection and submission of R code blocks
"    with non-interactive execution
" 2. Multi-Terminal Management: Buffer-specific R terminal sessions with
"    isolated session management between files
" 3. Chunk Navigation: Navigation between R Markdown/Quarto code chunks
" 4. Object Inspection: Functions for examining R workspace objects
" 5. Pattern Recognition: Recognition of R language constructs including
"    functions, control structures, and nested delimiters
"
" ARCHITECTURE:
" =============
" The plugin uses a single-file architecture with clear functional 
" separation:
" - Configuration management and validation with safe defaults
" - Multi-terminal session management with buffer-specific association
" - Pattern detection for R code structures (braces/parentheses)
" - Text extraction and processing functions
" - Code submission user interface (commands and key mappings)
" - Testing infrastructure for all functionality
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
"   Example: let g:zzvim_r_default_terminal = 'R-4.1'  " Use specific R 
"            version
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
" g:zzvim_r_terminal_height     (number)
"   Terminal window height in rows when opened as horizontal split.
"   Default: 15
"   Example: let g:zzvim_r_terminal_height = 20  " Taller terminal
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
"   Key sequence for code submission in normal mode.
"   Default: '<CR>' (Enter key)
"   Example: let g:zzvim_r_map_submit = '<Leader>r'  " Use leader+r instead
"
" R Markdown/Quarto Document Configuration:
" ----------------------------------------
" g:zzvim_r_chunk_start         (string)
"   Regular expression pattern matching code chunk start lines.
"   Default: '^```{' (matches ```{r}, ```{python}, etc.)
"   Pattern explanation: ^ = start of line, ``` = literal backticks, 
"                        { = opening brace
"   Example: let g:zzvim_r_chunk_start = '^```{r'  " Only R chunks
"
" g:zzvim_r_chunk_end           (string)
"   Regular expression pattern matching code chunk end lines.
"   Default: '^```$' (matches ``` at start of line, nothing after)
"   Pattern explanation: ^ = start of line, ``` = literal backticks, 
"                        $ = end of line
"   Example: let g:zzvim_r_chunk_end = '^```\s*$'  " Allow trailing 
"            whitespace
"
" Development and Debugging:
" -------------------------
" g:zzvim_r_debug               (boolean)
"   Enables verbose logging for troubleshooting plugin issues.
"   Creates detailed logs in ~/zzvim_r.log file.
"   Default: 0 (disabled)
"   Example: let g:zzvim_r_debug = 1  " Enable for debugging
"
" For key mappings and Ex commands reference, see :help zzvim-R
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
" v:version is built-in variable containing Vim version as integer 
" (e.g., 801 = 8.01)
" has('terminal') checks if Vim was compiled with terminal emulation support
" In CI environments or headless mode, terminal support may be unavailable
" but plugin can still be tested
let s:is_ci_mode = exists('$CI') || exists('$GITHUB_ACTIONS') || has('nvim')
let s:has_terminal_support = has('terminal') || s:is_ci_mode

"------------------------------------------------------------------------------
" Terminal Compatibility Layer
" Provides unified API for terminal functions across Vim and Neovim
"------------------------------------------------------------------------------

if has('nvim')
    " Neovim terminal function implementations
    function! s:compat_term_list() abort
        " Get all terminal buffers in Neovim
        let term_bufs = []
        for buf in nvim_list_bufs()
            if getbufvar(buf, '&buftype') ==# 'terminal'
                call add(term_bufs, buf)
            endif
        endfor
        return term_bufs
    endfunction
    
    function! s:compat_term_getstatus(bufnr) abort
        " Check if terminal buffer is still running
        if !bufexists(a:bufnr) || getbufvar(a:bufnr, '&buftype') !=# 'terminal'
            return 'finished'
        endif
        let chan = getbufvar(a:bufnr, '&channel')
        return chan > 0 ? 'running' : 'finished'
    endfunction
    
    function! s:compat_term_sendkeys(bufnr, keys) abort
        " Send keys to terminal buffer via channel
        let chan = getbufvar(a:bufnr, '&channel')
        if chan > 0
            call chansend(chan, a:keys)
        endif
    endfunction
else
    " Vim terminal function implementations (use native functions)
    function! s:compat_term_list() abort
        return term_list()
    endfunction
    
    function! s:compat_term_getstatus(bufnr) abort
        return term_getstatus(a:bufnr)
    endfunction
    
    function! s:compat_term_sendkeys(bufnr, keys) abort
        return term_sendkeys(a:bufnr, a:keys)
    endfunction
endif

if v:version < 800 || (!s:has_terminal_support && !s:is_ci_mode)
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

" Efficient configuration initialization using get() with defaults
" VimScript get() pattern: get(dict, key, default) - no need for exists() 
" checks
let g:zzvim_r_default_terminal = get(g:, 'zzvim_r_default_terminal', 'R')
let g:zzvim_r_disable_mappings = get(g:, 'zzvim_r_disable_mappings', 0)
let g:zzvim_r_map_submit = get(g:, 'zzvim_r_map_submit', '<CR>')
let g:zzvim_r_terminal_width = get(g:, 'zzvim_r_terminal_width', 100)
let g:zzvim_r_terminal_height = get(g:, 'zzvim_r_terminal_height', 15)
let g:zzvim_r_command = get(g:, 'zzvim_r_command', 'R --no-save --quiet')
let g:zzvim_r_chunk_start = get(g:, 'zzvim_r_chunk_start', '^```\s*{\?\s*[rR]\>')
let g:zzvim_r_chunk_end = get(g:, 'zzvim_r_chunk_end', '^```\s*$')
let g:zzvim_r_debug = get(g:, 'zzvim_r_debug', 0)

" Docker Configuration:
" --------------------
" NOTE: ZR now runs 'make r' instead of building docker commands
" These configuration variables are no longer used by ZR
" Configure your Docker setup in your Makefile instead
"
" Example Makefile target 'r':
"   r:
"       docker run -it --rm \
"           -v $(PWD):/workspace \
"           -v ~/prj/d07/zzcollab:/zzcollab \
"           -w /workspace \
"           png1 R --no-save --quiet

"------------------------------------------------------------------------------
" Utility Functions
"------------------------------------------------------------------------------

" Generate unique terminal name for current buffer (multi-terminal support)
" Creates buffer-specific terminal names for workflow isolation
" Returns: string - terminal name based on buffer characteristics
function! s:GetTerminalName() abort
    " Use buffer name (filename) as base for terminal identification
    let buffer_name = expand('%:t:r')  " Get filename without extension
    
    if empty(buffer_name)
        " Unnamed buffer - use buffer number
        let buffer_name = 'buffer' . bufnr('%')
    endif
    
    " Create unique terminal name: R-filename
    return 'R-' . buffer_name
endfunction

" Get information about all existing terminals
" Returns: list of dicts with {bufnr, name, status} for each terminal
function! s:GetAllTerminals() abort
    let terminal_buffers = s:compat_term_list()
    let terminals = []

    for buf_id in terminal_buffers
        let buf_name = bufname(buf_id)
        let status = s:compat_term_getstatus(buf_id)

        " Get a descriptive name for the terminal
        if empty(buf_name)
            let display_name = 'Terminal #' . buf_id
        else
            let display_name = buf_name
        endif

        call add(terminals, {
            \ 'bufnr': buf_id,
            \ 'name': display_name,
            \ 'status': status
            \ })
    endfor

    return terminals
endfunction

" Prompt user to select from existing terminals or create new
" Parameters:
"   terminals - list of terminal info dicts from GetAllTerminals()
" Returns: number - selected terminal buffer number or -1 to create new
function! s:PromptTerminalSelection(terminals) abort
    " Build prompt message
    let prompt_lines = ['Select a terminal to associate with this R file:']
    call add(prompt_lines, '')

    let idx = 1
    for term in a:terminals
        let status_indicator = term.status =~# 'running' ? '[running]' : '[stopped]'
        let line = printf('%d. %s  %s (buf #%d)',
            \ idx, term.name, status_indicator, term.bufnr)
        call add(prompt_lines, line)
        let idx += 1
    endfor

    call add(prompt_lines, '')
    call add(prompt_lines, printf('%d. Create new R terminal', idx))
    call add(prompt_lines, '')
    call add(prompt_lines, 'Enter number (or 0 to cancel): ')

    " Use inputlist() for selection
    let choice = inputlist(prompt_lines)

    " Handle choice
    if choice == 0
        " User cancelled
        return -2
    elseif choice > 0 && choice <= len(a:terminals)
        " User selected an existing terminal
        return a:terminals[choice - 1].bufnr
    elseif choice == len(a:terminals) + 1
        " User wants to create new terminal
        return -1
    else
        " Invalid choice
        call s:Error('Invalid selection')
        return -2
    endif
endfunction

" Find or create buffer-specific R terminal (multi-terminal architecture)
" Implements buffer-specific terminal association for workflow isolation
" Returns: number - terminal buffer number or -1 if failed
function! s:GetBufferTerminal() abort
    " Check if buffer already has an associated terminal
    if exists('b:r_terminal_id') && b:r_terminal_id > 0
        " Verify the terminal still exists and is running
        let terminal_buffers = s:compat_term_list()
        if index(terminal_buffers, b:r_terminal_id) >= 0
            if s:compat_term_getstatus(b:r_terminal_id) =~# 'running'
                return b:r_terminal_id
            endif
        endif
        " Terminal died or doesn't exist - clear the association
        unlet b:r_terminal_id
    endif

    " No valid terminal - look for existing one with correct name before prompting
    let expected_name = s:GetTerminalName()

    " Search through all terminals for one with the expected name
    let terminal_buffers = s:compat_term_list()
    for buf_id in terminal_buffers
        let buf_name = bufname(buf_id)
        if buf_name ==# expected_name && s:compat_term_getstatus(buf_id) =~# 'running'
            " Found existing running terminal with correct name - reuse it
            let b:r_terminal_id = buf_id
            return buf_id
        endif
    endfor

    " No terminal with expected name - check if ANY terminals exist
    let all_terminals = s:GetAllTerminals()

    if !empty(all_terminals)
        " Terminals exist - prompt user to select one or create new
        let selection = s:PromptTerminalSelection(all_terminals)

        if selection == -2
            " User cancelled - don't create terminal
            call s:Error('Terminal association cancelled')
            return -1
        elseif selection > 0
            " User selected an existing terminal - associate it
            let b:r_terminal_id = selection
            echom 'Associated with terminal buffer #' . selection
            return b:r_terminal_id
        endif
        " If selection == -1, fall through to create new terminal
    endif

    " No existing terminals, or user chose to create new one
    let terminal_id = s:OpenRTerminal()

    if terminal_id != -1
        " Associate new terminal with this buffer
        let b:r_terminal_id = terminal_id
        return b:r_terminal_id
    endif

    " Failed to create terminal
    return -1
endfunction
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

" Check if line ends with an R infix operator (pipe, arithmetic, assignment, etc.)
" Used for multi-line expression detection
function! s:EndsWithInfixOperator(line) abort
    return a:line =~# '[+\-*/^&|<>=!,]\s*$' ||
                \ a:line =~# '%[^%]*%\s*$' ||
                \ a:line =~# '<-\s*$' ||
                \ a:line =~# '|>\s*$'
endfunction

" Set up buffer for HUD/viewer displays with standard options
" Note: Does not set readonly - call setlocal readonly after writing content
function! s:SetupViewerBuffer() abort
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nowrap
    setlocal nonumber
    setlocal norelativenumber
    nnoremap <buffer> <silent> q :bwipe<CR>
    nnoremap <buffer> <silent> <ESC> :bwipe<CR>
endfunction

" =============================================================================
" CORE TERMINAL MANAGEMENT FUNCTIONS
" =============================================================================

" Create and Configure R Terminal Session (local or Docker)
" Unified terminal creation function for both local R and Docker R
" Parameters:
"   a:1 (optional) - terminal name override
"   a:2 (optional) - for docker: force re-association (1 = force)
" Returns: number - terminal buffer number or -1 if failed
function! s:OpenRTerminal(...) abort
    let terminal_name = a:0 > 0 ? a:1 : s:GetTerminalName()

    " Check if inside a zzcollab workspace
    " If so, use Docker R terminal instead of local R
    let l:project_root = s:GetProjectRoot()
    if !empty(l:project_root)
        return s:OpenDockerRTerminal(terminal_name)
    endif

    if !executable('R')
        call s:Error('R is not installed or not in PATH')
        return -1
    endif

    execute 'vertical term ' . g:zzvim_r_command
    return s:ConfigureTerminal(terminal_name, 0)
endfunction

" Check if current directory is inside a zzcollab workspace
" Walks up directory tree looking for .zzcollab/ directory (unique zzcollab signature)
function! s:IsInsideZzcollab() abort
    return !empty(s:GetProjectRoot())
endfunction

" Get the project root directory (where .zzcollab/ marker exists)
" Returns empty string if not inside a zzcollab workspace
" Checks for .zzcollab/ directory (unique signature of zzcollab workspaces)
function! s:GetProjectRoot() abort
    " Check for user-configured project root first
    if exists('g:zzvim_r_project_root') && !empty(g:zzvim_r_project_root)
        return g:zzvim_r_project_root
    endif

    " Walk up directory tree looking for .zzcollab/ directory
    " Only marks a directory as zzcollab if .zzcollab/ directory exists
    let dir = getcwd()
    while dir != '/'
        " Check for .zzcollab/ directory (unique zzcollab workspace marker)
        if isdirectory(dir . '/.zzcollab')
            return dir
        endif

        let dir = fnamemodify(dir, ':h')
    endwhile

    return ''
endfunction

" Force open local/host R terminal (bypass zzcollab workspace detection)
function! s:OpenLocalRTerminal(...) abort
    let terminal_name = a:0 > 0 ? a:1 : s:GetTerminalName()

    if !executable('R')
        call s:Error('R is not installed or not in PATH')
        return -1
    endif

    " Use term_start() with exit_cb to detect when R terminal closes
    let l:term_opts = {
        \ 'vertical': 1,
        \ 'exit_cb': function('s:RTerminalExitCallback')
        \ }
    " Split the command into list for term_start()
    let l:cmd_parts = split(g:zzvim_r_command)
    call term_start(l:cmd_parts, l:term_opts)
    return s:ConfigureTerminal(terminal_name, 0)
endfunction

" Create R Terminal on Host without renv (vanilla mode)
" Uses R --vanilla which skips all startup files (.Rprofile, .Renviron)
" Useful for debugging or when you want system R without project isolation
function! s:OpenLocalRTerminalVanilla(...) abort
    let terminal_name = a:0 > 0 ? a:1 : s:GetTerminalName()

    if !executable('R')
        call s:Error('R is not installed or not in PATH')
        return -1
    endif

    " Use term_start() with exit_cb to detect when R terminal closes
    let l:term_opts = {
        \ 'vertical': 1,
        \ 'exit_cb': function('s:RTerminalExitCallback')
        \ }
    call term_start(['R', '--vanilla'], l:term_opts)
    return s:ConfigureTerminal(terminal_name, 0)
endfunction

" Check if current directory is a zzcollab project (has Makefile with r: target)
function! s:IsZzCollabProject() abort
    " Check for Makefile in current directory or parent directories
    let l:makefile = findfile('Makefile', '.;')
    if empty(l:makefile)
        return 0
    endif

    " Check if Makefile has 'r:' target (zzcollab signature)
    let l:content = join(readfile(l:makefile), "\n")
    return l:content =~# '\n\s*r\s*:'
endfunction

" Create R Terminal - auto-detects zzcollab vs standalone
" In zzcollab project: uses Docker via 'make r'
" Outside zzcollab: falls back to local R with renv
function! s:OpenDockerRTerminal(...) abort
    let terminal_name = a:0 > 0 ? a:1 : s:GetTerminalName()
    let force_associate = a:0 > 1 ? a:2 : 0

    " Force-associate with existing terminal if requested
    if force_associate
        let terminal_buffers = s:compat_term_list()
        for buf_id in terminal_buffers
            if bufname(buf_id) ==# terminal_name
                let b:r_terminal_id = buf_id
                let b:r_is_docker = 1
                echom 'Force-associated with existing Docker terminal: ' . terminal_name
                return buf_id
            endif
        endfor
    endif

    " Auto-detect: zzcollab project uses Docker, otherwise local R
    if s:IsZzCollabProject()
        if !executable('make')
            call s:Error('make is not installed or not in PATH')
            return -1
        endif
        " Use 'mr r' shell function which finds Makefile from subdirectories
        " Use term_start() with exit_cb to detect when R terminal closes
        let l:term_opts = {
            \ 'vertical': 1,
            \ 'exit_cb': function('s:RTerminalExitCallback')
            \ }
        call term_start(['zsh', '-ic', 'mr r'], l:term_opts)
        return s:ConfigureTerminal(terminal_name, 1)
    else
        " Not a zzcollab project - fall back to local R
        echom 'Not a zzcollab project, using local R'
        return s:OpenLocalRTerminal(terminal_name)
    endif
endfunction

" Configure terminal after creation (shared between local and Docker)
function! s:ConfigureTerminal(terminal_name, is_docker) abort
    " Resize terminal window
    if exists('g:zzvim_r_terminal_width') && g:zzvim_r_terminal_width > 0
        let terminal_width = g:zzvim_r_terminal_width
    else
        let terminal_width = winwidth(0) / 2
    endif
    execute 'vertical resize ' . terminal_width

    setlocal norelativenumber nonumber signcolumn=no
    let current_terminal = bufnr('%')

    " Handle terminal name collision
    let final_name = a:terminal_name
    if bufexists(final_name)
        let counter = 1
        while bufexists(final_name . '_' . counter)
            let counter += 1
        endwhile
        let final_name = final_name . '_' . counter
    endif
    execute 'file ' . final_name

    if a:is_docker
        let b:r_is_docker = 1
        " Track this as the active Docker R terminal for cleanup
        let s:docker_r_terminal_bufnr = current_terminal
    endif
    let t:is_r_term = 1
    wincmd p

    " Associate terminal with buffer
    let b:r_terminal_id = current_terminal

    " Start plot watcher if terminal supports graphics (works for both Docker and local R)
    if s:TerminalSupportsGraphics()
        " Initialize signal mtime to current file time (if exists) to avoid
        " displaying stale plots on terminal open
        let l:signal_file = s:GetSignalFile()
        if filereadable(l:signal_file)
            let s:plot_signal_mtime = getftime(l:signal_file)
        else
            " Fall back to plot file mtime if no signal file yet
            let l:plot_file = s:GetPlotFile()
            if filereadable(l:plot_file)
                let s:plot_signal_mtime = getftime(l:plot_file)
            endif
        endif
        " Start watcher - it will only display when mtime changes
        call s:StartPlotWatcher()
    endif

    return current_terminal
endfunction

" Send Commands to Buffer-Specific R Terminal with Auto-Recovery
" Core communication function between Vim and R session (silent execution)
" Parameters:
"   a:cmd (string) - R command/code to execute
"   a:stay_on_line (boolean) - whether to keep cursor on current line 
"                              (unused in current implementation)
" Returns: nothing (void) - uses silent execution, no user prompts
function! s:Send_to_r(cmd, stay_on_line) abort
    " Get buffer-specific terminal (creates if needed)
    let target_terminal = s:GetBufferTerminal()

    if target_terminal == -1
        call s:Error("Could not create or find R terminal for this buffer.")
        return
    endif

    " Command Transmission with Error Handling
    try

        " Input Validation - avoid sending empty commands to R
        " trim() removes leading/trailing whitespace
        " !empty() ensures we have actual content to send
        if !empty(trim(a:cmd))
            " Terminal Status Verification
            " compat_term_getstatus() returns terminal state ("running", "finished", etc.)
            " =~# is case-sensitive regex match operator
            if s:compat_term_getstatus(target_terminal) =~# 'running'
                " Send command with newline to execute in R
                " compat_term_sendkeys() simulates typing in terminal
                " "\n" = newline character to execute command
                call s:compat_term_sendkeys(target_terminal, a:cmd . "\n")
                
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
    let [l:line_end, l:col_end] = getpos("'>")[1:2]
    
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
" These functions provide navigation between code chunks in literate
" programming documents

" Navigate to Next Code Chunk (Forward Direction)
" Finds the next chunk boundary and positions cursor inside for editing
function! s:MoveNextChunk() abort
    " Get chunk start pattern from user configuration with safe fallback
    " get(g:, 'var', default) safely retrieves global variable
    let l:chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{')

    " Save current position for potential restoration
    let l:current_pos = getpos('.')
    let l:current_line = line('.')

    " Check if we're already on a chunk start line
    let l:current_line_content = getline('.')
    if l:current_line_content =~# l:chunk_start_pattern
        " We're on a chunk start - move inside this chunk
        if l:current_line < line('$')
            normal! j
            echom "Moved inside current chunk at line " . line('.')
            return
        else
            call s:Error("Current chunk found, but no lines inside the chunk.")
            return
        endif
    endif

    " Search for next chunk start from current position
    " search(pattern, flags): 'W' = don't wrap around file end
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
    
    " Context Handling Based on Cursor Position
    " Determines whether we're inside a chunk or between chunks
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
    
    " Navigate to next chunk after submission - simplified approach
    call s:MoveNextChunk()
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
        " Get buffer-specific terminal
        let target_terminal = s:GetBufferTerminal()
        
        if target_terminal == -1
            call s:Error("No R terminal found for this buffer.")
            return
        endif

        " Use term_sendkeys to send the control key to buffer's terminal
        call s:compat_term_sendkeys(target_terminal, a:key)
    catch
        call s:Error("Failed to send control key: " . a:key)
    endtry
endfunction

"------------------------------------------------------------------------------
" Function: Perform an R action on the word under the cursor
"------------------------------------------------------------------------------
" Function removed - s:RCommandWithArg used directly for efficiency

"------------------------------------------------------------------------------
" Function: Generalized text sending to R with pattern detection
"------------------------------------------------------------------------------
" =============================================================================
" GENERALIZED CODE SUBMISSION SYSTEM
" =============================================================================
" This is the main orchestrating function that coordinates code detection
" and submission

" Code Submission Function
" Handles all types of code submission through unified interface with
" buffer-specific terminal routing
" Parameters:
"   a:selection_type (string) - Type: '', 'line', 'function', 'chunk', 
"                               'selection'
"   ... (variadic) - Optional additional parameters for future extensibility
" Returns: nothing (void) - uses silent execution, no user prompts

function! s:SendToR(selection_type, ...) abort
    " Phase 1: Text Extraction and Pattern Detection
    let text_lines = s:GetTextByType(a:selection_type)
    
    " Input Validation - Ensure we have content to send
    if empty(text_lines)
        call s:Error("No text to send to R.")
        return
    endif
    
    " Phase 2: Consistent Code Transmission via Temp File
    " For zzcollab projects: write to project root (Docker container mounts it)
    " For standalone: write to buffer's directory and use absolute path
    let timestamp = string(localtime())[-4:]  " Last 4 digits of unix timestamp
    let temp_filename = '.zz' . timestamp . '.R'

    " Get buffer's directory (where the .R file lives)
    let buffer_dir = expand('%:p:h')
    if empty(buffer_dir)
        let buffer_dir = getcwd()
    endif

    " Check if buffer is inside a zzcollab project
    let project_root = s:GetProjectRoot()
    let is_zzcollab = !empty(project_root) && stridx(buffer_dir, project_root) == 0

    " Use project root for zzcollab, buffer directory for standalone
    let write_dir = is_zzcollab ? project_root : buffer_dir

    " Verify write directory is writable
    if !filewritable(write_dir)
        call s:Error("Cannot write to directory: " . write_dir)
        return
    endif

    let temp_file = write_dir . '/' . temp_filename
    call writefile(text_lines, temp_file)

    " For zzcollab/Docker: use relative path (R's cwd is mounted project root)
    " For standalone projects: use absolute path (R's cwd may differ)
    let source_path = is_zzcollab ? temp_filename : temp_file
    let r_cmd = 'source("' . source_path . '", echo=T); unlink("' . source_path . '")'
    call s:Send_to_r(r_cmd, 1)
    
    " Phase 3: Determine actual submission type for cursor movement
    let actual_type = a:selection_type
    " Check if we sent multiple lines with pattern detection - likely a block
    if empty(a:selection_type) && len(text_lines) > 1
        let actual_type = 'function'
    endif
    
    " Phase 4: Cursor Movement Based on Actual Submission Type
    call s:MoveCursorAfterSubmission(actual_type, len(text_lines))
endfunction

" Helper function to move cursor to next non-comment line
" Used when submitting comment lines to skip to executable code
function! s:MoveToNextNonComment() abort
    let next_line = line('.') + 1
    while next_line <= line('$') && getline(next_line) =~# '^\s*\(#\|$\)'
        let next_line += 1
    endwhile
    call cursor(min([next_line, line('$')]), 1)
endfunction

" Cursor Movement After Code Submission
" Moves cursor to appropriate position based on what was submitted
" Parameters:
"   a:selection_type (string) - Type of submission that occurred
"   a:line_count (number) - Number of lines that were submitted
function! s:MoveCursorAfterSubmission(selection_type, line_count) abort
    " Handle different submission types with appropriate cursor movement
    if a:selection_type ==# 'selection'
        " Visual selection - move cursor to line after the selection
        let [l:line_end, l:col_end] = getpos("'>")[1:2]
        call cursor(min([l:line_end + 1, line('$')]), 1)
        return
    elseif a:selection_type ==# 'chunk'
        " R Markdown chunk - cursor should move to after the chunk
        " This is handled by the chunk navigation functions
        return
    elseif a:selection_type ==# 'function'
        " Code block submission - move to line after the block
        if exists('s:last_block_end_line')
            call cursor(min([s:last_block_end_line + 1, line('$')]), 1)
            unlet s:last_block_end_line
        endif
    else
        " Single line submission - move cursor appropriately
        if getline('.') =~# '^\s*#'
            " Comment line - move to next non-comment line
            call s:MoveToNextNonComment()
        else
            " Regular line - move to next line
            call cursor(min([line('.') + 1, line('$')]), 1)
        endif
    endif
endfunction

" Send Code to R and Write Output as Comments
" Executes R code using standard SendToR logic, captures output, and writes
" output as comments in the current buffer after the original code
" Parameters:
"   a:selection_type (string) - Type: '', 'line', 'function', 'chunk', 'selection'
" Returns: nothing (void) - modifies buffer with output comments
function! s:SendToRWithComments(selection_type) abort
    " Phase 1: Get text using existing extraction logic
    let text_lines = s:GetTextByType(a:selection_type)
    
    " Input validation
    if empty(text_lines)
        call s:Error("No text to send to R.")
        return
    endif
    
    " Phase 2: Determine start and end lines for comment insertion
    let start_line = line('.')
    let end_line = start_line
    
    " Adjust end line based on selection type
    if a:selection_type ==# 'selection'
        let end_line = getpos("'>")[1]
    elseif len(text_lines) > 1
        " Multi-line code block - end line is start + number of lines - 1
        let end_line = start_line + len(text_lines) - 1
    endif
    
    " Phase 3: Create temp files with code wrapped in capture.output()
    " Use unique filenames and project root (for Docker compatibility)
    let timestamp = string(localtime())[-4:]
    let temp_filename = '.zzc' . timestamp . '.R'
    let temp_output_filename = '.zzo' . timestamp . '.txt'
    let project_root = s:GetProjectRoot()
    if empty(project_root)
        let project_root = getcwd()
    endif

    " Verify project root is writable before attempting to write temp files
    if !filewritable(project_root)
        call s:Error("Cannot write to project directory: " . project_root)
        return
    endif

    let temp_file = project_root . '/' . temp_filename
    let temp_output_file = project_root . '/' . temp_output_filename

    " Build capture.output() command
    " Use relative paths for Docker compatibility (R's cwd is project root)
    let capture_lines = ['writeLines(capture.output({']
    let capture_lines = capture_lines + text_lines
    let capture_lines = capture_lines + ['}), "' . temp_output_filename . '")']

    call writefile(capture_lines, temp_file)

    " Phase 4: Execute the wrapped code with relative path
    call s:Send_to_r('source("' . temp_filename . '")', 1)
    
    " Brief delay to ensure output file is written
    sleep 100m
    
    " Phase 5: Read captured output and insert as comments
    if filereadable(temp_output_file)
        let output_lines = readfile(temp_output_file)
        
        " Filter out empty lines and add comment prefix
        let comment_lines = []
        for output_line in output_lines
            if !empty(trim(output_line))
                call add(comment_lines, '# Output: ' . output_line)
            endif
        endfor
        
        " Insert comments after the code block
        if !empty(comment_lines)
            call append(end_line, comment_lines)
            echom "Added " . len(comment_lines) . " lines of output comments"
        else
            echom "No output to comment (code executed successfully)"
        endif
        
        " Clean up temp files
        call delete(temp_output_file)
    else
        echom "Could not capture R output"
    endif
    
    " Clean up temp file
    call delete(temp_file)
    
    " Phase 6: Move cursor using existing logic
    " Determine actual selection type for cursor movement
    let actual_type = a:selection_type
    if empty(a:selection_type) && len(text_lines) > 1
        let actual_type = 'function'
    endif
    
    call s:MoveCursorAfterSubmission(actual_type, len(text_lines))
endfunction

" Text Extraction Dispatcher
" Determines what code to extract based on context using pattern recognition
" for both brace {} and parenthesis () matching
" Parameters:
"   a:selection_type (string) - Explicit type or empty for auto-detection
" Returns: List of lines ready for R execution in buffer-specific terminal
function! s:GetTextByType(selection_type) abort
    " Auto-Detection Mode
    " When no explicit type specified, analyze current line for code patterns
    " This enables context-aware <CR> key behavior
    if empty(a:selection_type)
        " First check if we're inside a function definition
        if s:IsInsideFunction()
            " Inside function - send current line only for debugging
            return [getline('.')]
        endif
        
        " Check if we're in the middle of an incomplete statement
        if s:IsIncompleteStatement()
            " Don't send anything - this line is part of a multi-line statement
            " that was likely already sent when the first line was executed
            call s:Error("This appears to be a continuation line. Use the " .
                        \ "first line of the statement instead.")
            return []
        endif
        
        " Check if current line starts a code block
        if s:IsBlockStart(getline('.'))
            " Current line starts a code block - extract complete block
            return s:GetCodeBlock()
        endif
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
        " Default Fallback: Single Line or Automatic Detection
        " Return current line as single-element list
        " This handles simple assignments, function calls, and individual statements
        return [getline('.')]
    endif
endfunction

"------------------------------------------------------------------------------
" =============================================================================
" R CODE PATTERN DETECTION
" =============================================================================
" These functions recognize R language constructs and determine optimal
" code submission boundaries

" Check if current line is part of an incomplete multi-line statement
" Detects continuation lines that shouldn't be executed independently
" Returns: 1 if this is a continuation line, 0 otherwise  
function! s:IsIncompleteStatement() abort
    let current_line = getline('.')
    
    " Lines that clearly look like continuation/closing lines
    if current_line =~# '^\s*[)}\],]' 
        return 1
    endif
    
    " Lines that are just parameter names or values (common in multi-line calls)
    " More specific pattern to avoid false positives
    " Exclude lines that contain assignments (<- or =) as these are statement starts
    if current_line =~# '^\s*[a-zA-Z_][a-zA-Z0-9_.]*\s*[,)]\s*$' && current_line !~# '<-\|='
        " Check if previous line has an incomplete statement
        if line('.') > 1
            let prev_line = getline(line('.') - 1)
            if prev_line =~# '[\(,]\s*$'
                return 1
            endif
        endif
    endif
    
    " Check for infix operator continuation lines
    if line('.') > 1
        let prev_line = getline(line('.') - 1)
        " Previous line ends with any infix operator
        if prev_line =~# '[+\-*/^&|<>=!]\s*$' || prev_line =~# '%[^%]*%\s*$' || 
                    \ prev_line =~# '<-\s*$' || prev_line =~# '|>\s*$'
            return 1
        endif
    endif
    
    return 0
endfunction

" Check if cursor is inside a function definition
" Looks backward to find function start and forward to find function end
" Returns: 1 if inside function, 0 otherwise
function! s:IsInsideFunction() abort
    let save_pos = getpos('.')
    let current_line = line('.')
    
    " Quick check: if we're in the first few lines, unlikely to be inside a function
    if current_line < 3
        return 0
    endif
    
    " Search backward for function definition (limit search to avoid performance issues)
    let search_limit = max([1, current_line - 50])
    let function_start = search('function\s*(', 'bcnW', search_limit)
    
    if function_start == 0
        " No function definition found above within reasonable range
        return 0
    endif
    
    " Quick validation: look for opening brace near function definition
    call cursor(function_start, 1)
    let brace_line = search('{', 'W', function_start + 5)
    
    if brace_line == 0
        call setpos('.', save_pos)
        return 0
    endif
    
    " Fast brace counting with early termination
    let brace_count = 0
    let end_line = -1
    let search_end = min([line('$'), brace_line + 100])  " Limit search range
    
    for line_num in range(brace_line, search_end)
        let line_content = getline(line_num)
        let open_braces = len(substitute(line_content, '[^{]', '', 'g'))
        let close_braces = len(substitute(line_content, '[^}]', '', 'g'))
        let brace_count += open_braces - close_braces
        
        if brace_count == 0 && (open_braces > 0 || close_braces > 0)
            let end_line = line_num
            break
        endif
        
        " Early termination if we've gone too far
        if line_num > current_line + 20
            break
        endif
    endfor
    
    call setpos('.', save_pos)
    
    " Check if current line is between function start and end
    if end_line > 0 && current_line > function_start && current_line < end_line
        return 1
    endif
    
    return 0
endfunction

" Detect R Code Block Starting Patterns
" Pattern Recognition for R Language Constructs
" Analyzes a line to determine if it begins a multi-line code structure
" Supports both brace {} and parenthesis () matching with nested structures
" Parameters:
"   a:line (string) - Line of code to analyze
" Returns: 1 if line starts a block, 0 otherwise
function! s:IsBlockStart(line) abort
    " Pattern detection using multiple checks
    " Return 1 if line starts a block that needs special handling
    
    " Function definitions (most specific - contains both 'function' and parentheses)
    if a:line =~# 'function\s*('
        return 1
    endif
    
    " Control structures at line start  
    if a:line =~# '^\s*\(if\|for\|while\)\s*('
        return 1
    endif
    
    " Repeat and standalone blocks
    if a:line =~# '^\s*\(repeat\s*\)\?{'
        return 1  
    endif
    
    " Function calls that start at beginning of line (not continuation lines)
    " More specific pattern to avoid catching continuation lines
    " Exclude lines that start with closing characters or are clearly continuation lines
    if a:line =~# '^\s*[a-zA-Z_][a-zA-Z0-9_.]*\s*(' && a:line !~ '^\s*[)}\],]'
        " Additional check: make sure it's not just a parameter name with parentheses
        " like "       dplyr)" which shouldn't be treated as a function call
        if a:line !~ '^\s*[a-zA-Z_][a-zA-Z0-9_.]*\s*)\s*$'
            return 1
        endif
    endif
    
    " Assignment statements with function calls (like var <- c(...) or var = c(...))
    " Pattern: variable_name <- function_name( or variable_name = function_name(
    " But only if the line appears to be incomplete (unbalanced parens, trailing comma, etc.)
    if a:line =~# '\(<-\|=\).*[a-zA-Z_][a-zA-Z0-9_.]*\s*('
        " Check if line looks incomplete (needs block extraction)
        " Skip block extraction for simple single-line assignments
        if a:line =~# ',$' || a:line =~# '(\s*$'
            " Line ends with comma or open paren - likely multi-line
            return 1
        endif
        " Additional check: count parentheses balance
        let open_count = len(substitute(a:line, '[^(]', '', 'g'))
        let close_count = len(substitute(a:line, '[^)]', '', 'g'))
        if open_count > close_count
            " Unbalanced parentheses - likely multi-line
            return 1
        endif
        " Line looks complete - don't treat as block
    endif
    
    " Multi-line expressions - lines ending with infix operators or commas
    if s:EndsWithInfixOperator(a:line)
        return 1
    endif
    
    " Multi-line indexing - lines ending with opening bracket
    if a:line =~# '\[\s*$'
        return 1
    endif
    
    return 0
endfunction

" Extract Complete Code Block Using Brace/Parenthesis Matching
" Implements balanced character algorithm for exact boundaries
" Handles nested structures: functions within functions, nested if statements
" Supports both brace {} and parenthesis () detection with configurable types
" Returns: List of lines comprising the complete code block
function! s:GetCodeBlock() abort
    " Position State Management
    " Save current cursor position for restoration if algorithm fails
    let save_pos = getpos('.')
    let current_line_num = line('.')  " Starting line number
    let current_line = getline('.')   " Current line content
    
    " Phase 1: Check for infix expressions first (no balanced delimiters)
    " But exclude lines with unbalanced parentheses (those should use Phase 2)
    let has_infix_ending = s:EndsWithInfixOperator(current_line)
    
    if has_infix_ending
        " Check if line has unbalanced parentheses - if so, use Phase 2 instead
        let open_count = len(substitute(current_line, '[^(]', '', 'g'))
        let close_count = len(substitute(current_line, '[^)]', '', 'g'))
        if open_count > close_count
            " Unbalanced parentheses - this is a function call, not infix expression
            " Skip Phase 1, fall through to Phase 2 for balanced parentheses counting
        else
            " Balanced or no parentheses - treat as infix expression
            " Multi-line infix expression - read until we find a line that doesn't
            " end with an operator AND all parentheses are balanced
            let end_line = current_line_num
            let paren_balance = 0  " Track cumulative parenthesis balance

            " Count parens on the first line
            let paren_balance += len(substitute(current_line, '[^(]', '', 'g'))
            let paren_balance -= len(substitute(current_line, '[^)]', '', 'g'))

            while end_line < line('$')
                let end_line += 1
                let next_line = getline(end_line)

                if next_line =~# '^\s*$' || next_line =~# '^\s*#'
                    " Skip empty lines and comments, continue searching
                    continue
                endif

                " Update parenthesis balance for this line
                let paren_balance += len(substitute(next_line, '[^(]', '', 'g'))
                let paren_balance -= len(substitute(next_line, '[^)]', '', 'g'))

                " Check if this line ends with an operator or comma (pipe chain continues)
                let ends_with_operator = s:EndsWithInfixOperator(next_line)

                if ends_with_operator
                    " Line ends with operator, continue the chain
                    continue
                endif

                " Line doesn't end with operator - but check if parens are balanced
                if paren_balance > 0
                    " Still have unclosed parentheses, must continue
                    continue
                endif

                " Parens balanced and no trailing operator - this is the end
                break
            endwhile

            let s:last_block_end_line = end_line
            return getline(current_line_num, end_line)
        endif
    endif
    
    " Phase 2: Detect Block Type Based on Current Line for balanced delimiters
    " This ensures we respect the context of where the cursor is positioned
    let block_type = ''  " Will be 'brace', 'paren', or 'bracket'
    let block_line = current_line_num
    let found_opening = 0

    " Efficient Single-Pass Character Detection
    let has_paren = current_line =~ '('
    let has_brace = current_line =~ '{'
    let has_bracket = current_line =~ '\['

    " SPECIAL CASE: Multi-Line Function Definitions
    " Function definitions like: var <- function(args)
    "                              body
    "                            }
    " Have parentheses on line 1 but opening brace on a later line.
    " Must always use brace matching for function definitions, not parenthesis matching.
    if current_line =~# 'function\s*('
        let block_type = 'brace'
        if has_brace
            " Brace on current line - use normal processing
            let found_opening = 1
        else
            " Brace on a later line - search for it within reasonable distance
            let search_line = current_line_num + 1
            let search_limit = current_line_num + 10  " Allow up to 10 lines for function signature
            while search_line <= line('$') && search_line <= search_limit
                if getline(search_line) =~ '{'
                    let block_line = search_line
                    let found_opening = 1
                    break
                endif
                let search_line += 1
            endwhile
        endif
    " First Priority: Check current line for parentheses (function calls)
    " This prevents parenthesis blocks inside functions from being treated as brace blocks
    elseif has_paren && !has_brace && !has_bracket
        let block_type = 'paren'
        let found_opening = 1
        " For parentheses, the opening character is typically on the current line
    " Second Priority: Check current line for brackets (indexing)
    elseif has_bracket && !has_brace
        let block_type = 'bracket'
        let found_opening = 1
    " Third Priority: Check current line for braces (function definitions, control structures)
    elseif has_brace
        let block_type = 'brace'
        let found_opening = 1
    else
        " Fallback: Limited Forward Search for Opening Character
        " Only search forward if current line doesn't contain opening characters
        let search_limit = current_line_num + 5
        while block_line <= line('$') && block_line <= search_limit
            let line_content = getline(block_line)
            let line_has_brace = line_content =~ '{'
            let line_has_paren = line_content =~ '('
            let line_has_bracket = line_content =~ '\['

            " For forward search, prioritize parentheses, then brackets, then braces
            if line_has_paren
                let found_opening = 1
                let block_type = 'paren'
                break
            elseif line_has_bracket
                let found_opening = 1
                let block_type = 'bracket'
                break
            elseif line_has_brace
                let found_opening = 1
                let block_type = 'brace'
                break
            endif
            let block_line += 1
        endwhile
    endif
    
    " Error Handling: No Opening Character Found
    if !found_opening
        " Restore cursor position and report failure
        call setpos('.', save_pos)
        call s:Error("No opening delimiter found for code block.")
        " Return empty list to indicate failure
        return []
    endif
    
    " Phase 2: Balanced Character Counting Algorithm
    " Find matching closing character by counting balance (braces or parentheses)
    call cursor(block_line, 1)  " Position at opening character line
    let char_count = 0         " Running balance of open vs close characters
    let start_line = current_line_num  " Block starts at original cursor position
    let end_line = -1          " Will store line number of matching close character
    
    " Set Character Patterns Based on Block Type (Pre-computed for efficiency)
    if block_type == 'brace'
        let open_char = '{'
        let close_char = '}'
    elseif block_type == 'bracket'
        let open_char = '['
        let close_char = ']'
    else
        " block_type == 'paren'
        let open_char = '('
        let close_char = ')'
    endif
    
    " Iterate Through Lines Counting Characters
    for line_num in range(block_line, line('$'))
        let line_content = getline(line_num)
        
        " Efficient Character Counting Using Direct Character Matching
        " Avoids creating intermediate strings via substitute()
        let open_chars = 0
        let close_chars = 0
        let i = 0
        while i < len(line_content)
            let char = line_content[i]
            if char == open_char
                let open_chars += 1
            elseif char == close_char
                let close_chars += 1
            endif
            let i += 1
        endwhile
        
        " Update Running Character Balance
        " Positive = more opens than closes, Zero = balanced
        let char_count += open_chars - close_chars
        
        " Critical Balance Detection
        " When char_count reaches 0, we've found the matching closing character
        " Additional condition ensures we've actually processed characters on this line
        " (prevents false positive on lines with no characters)
        if char_count == 0 && (open_chars > 0 || close_chars > 0)
            let end_line = line_num
            " Exit loop - block boundary found
            break
        endif
    endfor
    
    " Restore Original Cursor Position
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
    " Note: end_line is stored in script-local variable for cursor movement
    let s:last_block_end_line = end_line
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
" Function: Code submission - uses generalized function with auto-detection
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
        " Initialize terminal graphics setup only when opening R code files
        autocmd FileType r,rmd,qmd call zzvimr#terminal_graphics#init()
        " R Terminal Launch Mappings:
        "   <localleader>r  - Container R (via make r, with renv)
        "   <localleader>rr - Host R with renv (normal startup, sources .Rprofile)
        "   <localleader>rh - Host R without renv (vanilla, skips .Rprofile)
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>r   :call <SID>OpenDockerRTerminal()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> ZR              :call <SID>OpenDockerRTerminal()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>rr  :call <SID>OpenLocalRTerminal()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>rh  :call <SID>OpenLocalRTerminalVanilla()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>R   :call <SID>OpenLocalRTerminal()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>D   :call <SID>OpenDockerRTerminal(s:GetTerminalName(), 1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>w :call <SID>ROpenSplitCommand('vertical')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>W :call <SID>ROpenSplitCommand('horizontal')<CR>
        autocmd FileType r,rmd,qmd xnoremap <buffer> <silent> <CR>    :<C-u>call <SID>SendToR('selection')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <CR>  :call <SID>SendToR('')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader><CR>  :call <SID>SendToRWithComments('')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>o   :call <SID>AddPipeAndNewLine()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>j   :call <SID>MoveNextChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>k :call <SID>MovePrevChunk()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>l :call <SID>SubmitChunk()<CR>zz
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>t :call <SID>SendToR('previous_chunks')<CR>
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
        " Simple Object Inspection  
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>' :call <SID>RWorkspaceOverview()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>i :call <SID>RInspectObject()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>m :call <SID>RMemoryHUD()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>e :call <SID>RDataFrameHUD()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>z :call <SID>RPackageHUD()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>v :call <SID>RDataViewer()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>x :call <SID>REnvironmentHUD()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>a :call <SID>ROptionsHUD()<CR>
        " Unified HUD Dashboard - Open all HUD displays in tabs
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>0 :call <SID>RHUDDashboard()<CR>

        " ---------------------------------------------------------------------
        " Plot HUD: <LocalLeader>P opens Plot HUD (consistent with other HUDs)
        " ---------------------------------------------------------------------
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>P :RPlotHUD<CR>
        " Zoom - open PDF (vector)
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>] :call <SID>ZoomPlot()<CR>
        " Quick navigation (without opening HUD)
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>< :call <SID>PlotPrev()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>> :call <SID>PlotNext()<CR>
        " Plot history and save
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>[ :call <SID>PlotHistory()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>\ :call <SID>PlotSave()<CR>

        " R Markdown rendering (rk = render knit)
        autocmd FileType rmd,qmd nnoremap <buffer> <silent> <localleader>rp :RMarkdownPreview<CR>
        autocmd FileType rmd,qmd nnoremap <buffer> <silent> <localleader>rk :RMarkdownRender<CR>

        " Chunk insertion (rmd/qmd only)
        autocmd FileType rmd,qmd nnoremap <buffer> <silent> <localleader>ci :call <SID>InsertRChunk(0)<CR>
        autocmd FileType rmd,qmd nnoremap <buffer> <silent> <localleader>cI :call <SID>InsertRChunk(1)<CR>

        " Help in buffer (K override and <localleader>?)
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> K :call <SID>RHelpBuffer('')<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>? :call <SID>RHelpBuffer('')<CR>
    augroup END

    " Clean up plot pane when R terminal closes or buffer is deleted
    " Primary cleanup: exit_cb in term_start() (see RTerminalExitCallback)
    " Fallback cleanup: BufWipeout/BufDelete for edge cases
    augroup zzvim_PlotCleanup
        autocmd!
        autocmd BufWipeout,BufDelete * call s:CleanupPlotPaneIfRTerminal()
    augroup END

    " Equalize vim window sizes when kitty pane is resized
    augroup zzvim_WindowResize
        autocmd!
        autocmd VimResized * wincmd =
    augroup END
endif

" ===========================================================================
" SIMPLIFIED PLOT MANAGEMENT
" ===========================================================================
" Architecture: Vim watches .plots/.signal, displays PNG, opens PDF for zoom
" R renders: PDF (vector master) + PNG (preview)
" Removed: adaptive polling, composite images, thumbnail gallery, config sync
"
" Terminal Support:
"   - Kitty: Full support (dedicated pane via kitty @, icat display)
"   - Ghostty/WezTerm: Inline display only (kitty graphics protocol, no remote control)
"   - iTerm2: Inline display via imgcat
"   - Other: No image display (PDF zoom still works)

" Track Docker R terminal buffer
let s:docker_r_terminal_bufnr = -1
let s:pane_title = 'zzvim-plot'
let s:poll_interval = 100
let s:plot_signal_mtime = 0

"------------------------------------------------------------------------------
" Terminal Type Detection
"------------------------------------------------------------------------------
" Detect terminal emulator for choosing display strategy
" Returns: 'kitty', 'ghostty', 'wezterm', 'iterm2', or 'none'
function! s:DetectTerminalType() abort
    " Cache the result
    if exists('s:terminal_type')
        return s:terminal_type
    endif

    " Kitty
    if !empty($KITTY_WINDOW_ID)
        let s:terminal_type = 'kitty'
        return s:terminal_type
    endif

    " Ghostty (supports Kitty graphics protocol but not kitty @ commands)
    if !empty($GHOSTTY_RESOURCES_DIR) || $TERM ==# 'xterm-ghostty'
        let s:terminal_type = 'ghostty'
        return s:terminal_type
    endif

    " WezTerm (supports Kitty graphics protocol but not kitty @ commands)
    if !empty($WEZTERM_EXECUTABLE) || $TERM_PROGRAM =~? 'WezTerm'
        let s:terminal_type = 'wezterm'
        return s:terminal_type
    endif

    " iTerm2
    if !empty($ITERM_SESSION_ID) || $TERM_PROGRAM =~? 'iTerm'
        let s:terminal_type = 'iterm2'
        return s:terminal_type
    endif

    let s:terminal_type = 'none'
    return s:terminal_type
endfunction

" Check if terminal supports graphics
function! s:TerminalSupportsGraphics() abort
    return s:DetectTerminalType() !=# 'none'
endfunction

" Check if terminal supports dedicated pane (kitty @ remote control)
function! s:TerminalSupportsPanes() abort
    return s:DetectTerminalType() ==# 'kitty'
endfunction

"------------------------------------------------------------------------------
" Path Helpers
"------------------------------------------------------------------------------
function! s:GetPlotsDir() abort
    return getcwd() . '/.plots'
endfunction

function! s:GetPlotFile() abort
    return s:GetPlotsDir() . '/current.png'
endfunction

function! s:GetPlotPdf() abort
    return s:GetPlotsDir() . '/current.pdf'
endfunction

function! s:GetSignalFile() abort
    return s:GetPlotsDir() . '/.signal'
endfunction

function! s:GetHistoryDir() abort
    return s:GetPlotsDir() . '/history'
endfunction

function! s:GetHistoryIndex() abort
    return s:GetHistoryDir() . '/index.json'
endfunction

"------------------------------------------------------------------------------
" Plot Watcher (Fixed 100ms polling)
"------------------------------------------------------------------------------
function! s:StartPlotWatcher() abort
    if exists('s:plot_watcher_timer')
        call timer_stop(s:plot_watcher_timer)
    endif
    let s:plot_watcher_timer = timer_start(s:poll_interval,
        \ function('s:CheckForNewPlot'), {'repeat': -1})
endfunction

function! s:StopPlotWatcher() abort
    if exists('s:plot_watcher_timer')
        call timer_stop(s:plot_watcher_timer)
        unlet s:plot_watcher_timer
    endif
endfunction

function! s:CheckForNewPlot(timer) abort
    let l:signal = s:GetSignalFile()
    if !filereadable(l:signal)
        return
    endif
    let l:mtime = getftime(l:signal)
    if l:mtime <= s:plot_signal_mtime
        return
    endif
    let s:plot_signal_mtime = l:mtime
    call s:DisplayPlot()
endfunction

"------------------------------------------------------------------------------
" Plot Display (Terminal-Aware)
"------------------------------------------------------------------------------
function! s:PlotPaneExists() abort
    if !s:TerminalSupportsPanes()
        return 0
    endif
    let l:result = system('kitty @ ls 2>/dev/null')
    return l:result =~# s:pane_title
endfunction

function! s:DisplayPlot() abort
    let l:plot_file = s:GetPlotFile()
    if !filereadable(l:plot_file)
        return
    endif

    let l:term_type = s:DetectTerminalType()

    if l:term_type ==# 'kitty'
        " Kitty: Use dedicated pane with remote control
        if s:PlotPaneExists()
            call system('kitty @ send-text --match title:' . s:pane_title . " r")
        else
            call s:CreatePlotPane(l:plot_file)
        endif
    elseif l:term_type ==# 'ghostty' || l:term_type ==# 'wezterm'
        " Ghostty/WezTerm: Inline display using kitty graphics protocol
        call s:DisplayPlotInline(l:plot_file)
    elseif l:term_type ==# 'iterm2'
        " iTerm2: Use imgcat
        call s:DisplayPlotITerm2(l:plot_file)
    else
        " No graphics support - just notify
        echom "Plot saved: " . l:plot_file
    endif

    " Auto-refresh any open Plot HUD buffer
    call s:RefreshPlotHUDIfOpen()
endfunction

" Inline display for Ghostty/WezTerm (kitty graphics protocol without remote control)
function! s:DisplayPlotInline(plot_file) abort
    " Display in terminal using kitty +kitten icat
    " This works because Ghostty/WezTerm support the kitty graphics protocol
    let l:cmd = 'kitty +kitten icat --clear --align=left ' . shellescape(a:plot_file)
    call system(l:cmd)
    echom "Plot displayed inline"
endfunction

" Display for iTerm2 using imgcat
function! s:DisplayPlotITerm2(plot_file) abort
    if executable('imgcat')
        call system('imgcat ' . shellescape(a:plot_file))
        echom "Plot displayed (iTerm2)"
    else
        echom "Install imgcat for iTerm2 plot display. Plot saved: " . a:plot_file
    endif
endfunction

" Refresh Plot HUD if it's open (called when new plot is displayed)
function! s:RefreshPlotHUDIfOpen() abort
    " Find buffer named [Plot HUD] or HUD_*_Plots
    for l:bufnr in range(1, bufnr('$'))
        if bufexists(l:bufnr)
            let l:name = bufname(l:bufnr)
            if l:name =~# '\[Plot HUD\]\|HUD_.*_Plots'
                " Save current window
                let l:cur_win = winnr()
                let l:cur_buf = bufnr('%')

                " Switch to HUD buffer and refresh
                let l:hud_win = bufwinnr(l:bufnr)
                if l:hud_win > 0
                    execute l:hud_win . 'wincmd w'
                    call s:PlotHUDRefresh()
                    " Return to original window
                    execute l:cur_win . 'wincmd w'
                endif
                break
            endif
        endif
    endfor
endfunction

function! s:CreatePlotPane(plot_file) abort
    let l:script = '/tmp/zzvim_plot.sh'
    call writefile([
        \ '#!/bin/bash',
        \ 'PLOT_FILE="' . a:plot_file . '"',
        \ 'show_plot() {',
        \ '    clear',
        \ '    kitty +kitten icat --clear --align=left "$PLOT_FILE"',
        \ '    echo ""',
        \ '    echo "r=refresh | q=close"',
        \ '}',
        \ 'show_plot',
        \ 'while true; do',
        \ '    read -n1 -s key',
        \ '    case "$key" in',
        \ '        r|R) show_plot ;;',
        \ '        q|Q) exit 0 ;;',
        \ '    esac',
        \ 'done'
        \ ], l:script)
    call system('chmod +x ' . l:script)
    call system('kitty @ launch --location=vsplit --keep-focus --title ' .
        \ s:pane_title . ' ' . l:script . ' 2>/dev/null')
endfunction

"------------------------------------------------------------------------------
" Zoom - Open PDF (vector, infinite zoom)
"------------------------------------------------------------------------------
function! s:ZoomPlot() abort
    let l:pdf = s:GetPlotPdf()
    if filereadable(l:pdf)
        call system('open ' . shellescape(l:pdf))
        echom "Opened PDF (vector)"
    else
        call s:Error("No plot PDF available")
    endif
endfunction

"------------------------------------------------------------------------------
" Plot Navigation (via R)
"------------------------------------------------------------------------------
function! s:PlotPrev() abort
    call s:Send_to_r('plot_prev()', 1)
endfunction

function! s:PlotNext() abort
    call s:Send_to_r('plot_next()', 1)
endfunction

function! s:PlotHistory() abort
    call s:Send_to_r('plot_history()', 1)
endfunction

function! s:PlotGoto() abort
    let l:target = input('Plot ID or name: ')
    if empty(l:target)
        return
    endif
    if l:target =~# '^\d\+$'
        call s:Send_to_r('plot_goto(' . l:target . ')', 1)
    else
        call s:Send_to_r('plot_goto("' . l:target . '")', 1)
    endif
endfunction

function! s:PlotSearch() abort
    let l:pattern = input('Search pattern: ')
    if empty(l:pattern)
        return
    endif
    call s:Send_to_r('plot_search("' . l:pattern . '")', 1)
endfunction

"------------------------------------------------------------------------------
" Plot Export (via R)
"------------------------------------------------------------------------------
function! s:PlotSave() abort
    let l:filename = input('Save plot to: ', getcwd() . '/plot.pdf')
    if empty(l:filename)
        return
    endif
    call s:Send_to_r('show_save("' . l:filename . '")', 1)
endfunction

function! s:PlotSavePdf() abort
    let l:filename = input('Save PDF to: ', getcwd() . '/plot.pdf')
    if empty(l:filename)
        return
    endif
    call s:Send_to_r('show_save("' . l:filename . '")', 1)
endfunction

function! s:PlotSavePng() abort
    let l:filename = input('Save PNG to: ', getcwd() . '/plot.png')
    if empty(l:filename)
        return
    endif
    call s:Send_to_r('show_save("' . l:filename . '")', 1)
endfunction

"------------------------------------------------------------------------------
" Plot HUD - RStudio-inspired plot history viewer
"------------------------------------------------------------------------------
" Follows the same UX patterns as other HUD functions (Memory, DataFrames, etc.)
" Opens in a Vim split with consistent key bindings

function! s:RPlotHUD() abort
    let l:index_file = s:GetHistoryIndex()
    if !filereadable(l:index_file)
        call s:Error("No plot history. Create plots with zzplot() first.")
        return
    endif

    let l:json_content = join(readfile(l:index_file), '')
    try
        let l:index = json_decode(l:json_content)
    catch
        call s:Error("Failed to parse plot history")
        return
    endtry

    if empty(get(l:index, 'plots', []))
        call s:Error("Plot history is empty")
        return
    endif

    " Create HUD buffer (consistent with other HUDs)
    vnew
    call s:SetupViewerBuffer()
    file [Plot\ HUD]

    " Store plot data for buffer-local functions
    let b:plot_index = l:index

    " Generate and display content
    call s:GeneratePlotHUDContent()

    " Set up HUD-style key mappings
    call s:SetupPlotHUDMappings()

    " Position cursor on first plot line
    normal! 5G

    echo "Plot HUD: Enter=display, z=zoom PDF, s=save, d=delete, q=close"
endfunction

" Generate Plot HUD content (also used by dashboard)
function! s:GeneratePlotHUDContent() abort
    if !exists('b:plot_index')
        return
    endif

    let l:index = b:plot_index
    let l:lines = []

    " Header (consistent with other HUDs)
    call add(l:lines, 'Plot History                                              [HUD]')
    call add(l:lines, '====================================================================')
    call add(l:lines, 'Enter=display | z=zoom PDF | s=save | d=delete | q=close | /=search')
    call add(l:lines, '')

    " Column headers
    call add(l:lines, printf('  %-3s %-20s %-20s %s', '#', 'Name', 'Created', 'Code'))
    call add(l:lines, repeat('-', 70))

    " Plot entries
    let l:current = get(l:index, 'current', 0)
    for i in range(len(l:index.plots))
        let l:p = l:index.plots[i]
        let l:marker = (l:p.id == l:current) ? '> ' : '  '
        let l:name = strpart(get(l:p, 'name', 'unnamed'), 0, 18)
        let l:created = strpart(get(l:p, 'created', ''), 0, 18)
        let l:code = strpart(get(l:p, 'code', ''), 0, 25)
        call add(l:lines, printf('%s[%d] %-18s %-18s %s', l:marker, i+1, l:name, l:created, l:code))
    endfor

    " Footer
    call add(l:lines, '')
    call add(l:lines, printf('Total: %d plots | Current: %d', len(l:index.plots), l:current))

    " Write to buffer
    setlocal modifiable noreadonly
    silent! %delete _
    call setline(1, l:lines)
    setlocal readonly nomodifiable
endfunction

" Set up Plot HUD key mappings (consistent with other HUDs)
function! s:SetupPlotHUDMappings() abort
    " Navigation and close (standard HUD)
    nnoremap <buffer> <silent> q :bwipe<CR>
    nnoremap <buffer> <silent> <Esc> :bwipe<CR>

    " Plot-specific actions
    nnoremap <buffer> <silent> <CR> :call <SID>PlotHUDSelect()<CR>
    nnoremap <buffer> <silent> z :call <SID>PlotHUDZoom()<CR>
    nnoremap <buffer> <silent> s :call <SID>PlotHUDSave()<CR>
    nnoremap <buffer> <silent> d :call <SID>PlotHUDDelete()<CR>
    nnoremap <buffer> <silent> r :call <SID>PlotHUDRefresh()<CR>

    " Quick number selection (1-9)
    for i in range(1, 9)
        execute 'nnoremap <buffer> <silent> ' . i . ' :call <SID>PlotHUDSelectNum(' . i . ')<CR>'
    endfor
endfunction

" Get plot number from current line
function! s:PlotHUDGetNum() abort
    let l:line = getline('.')
    let l:match = matchstr(l:line, '\[\zs\d\+\ze\]')
    if !empty(l:match)
        return str2nr(l:match)
    endif
    return 0
endfunction

" Get plot entry from number
function! s:PlotHUDGetEntry(num) abort
    if !exists('b:plot_index') || a:num < 1
        return {}
    endif
    if a:num > len(b:plot_index.plots)
        return {}
    endif
    return b:plot_index.plots[a:num - 1]
endfunction

" Select and display plot under cursor
function! s:PlotHUDSelect() abort
    let l:num = s:PlotHUDGetNum()
    if l:num > 0
        call s:PlotHUDSelectNum(l:num)
    endif
endfunction

" Select plot by number
function! s:PlotHUDSelectNum(num) abort
    let l:entry = s:PlotHUDGetEntry(a:num)
    if empty(l:entry)
        echom "Plot " . a:num . " not in history"
        return
    endif

    " Update current in index
    let b:plot_index.current = l:entry.id

    " Copy plot files to current for display
    let l:hist_dir = s:GetHistoryDir()
    let l:png_src = l:hist_dir . '/' . get(l:entry, 'png', '')
    let l:pdf_src = l:hist_dir . '/' . get(l:entry, 'pdf', '')

    if filereadable(l:png_src)
        call system('cp ' . shellescape(l:png_src) . ' ' . shellescape(s:GetPlotFile()))
    endif
    if filereadable(l:pdf_src)
        call system('cp ' . shellescape(l:pdf_src) . ' ' . shellescape(s:GetPlotPdf()))
    endif

    " Trigger display
    let s:plot_signal_mtime = 0
    call s:DisplayPlot()

    " Refresh HUD to show new current marker
    call s:GeneratePlotHUDContent()

    echom "Displaying: " . get(l:entry, 'name', 'plot ' . a:num)
endfunction

" Zoom: open PDF of plot under cursor
function! s:PlotHUDZoom() abort
    let l:num = s:PlotHUDGetNum()
    if l:num == 0
        call s:ZoomPlot()
        return
    endif

    let l:entry = s:PlotHUDGetEntry(l:num)
    if empty(l:entry)
        return
    endif

    let l:hist_dir = s:GetHistoryDir()
    let l:pdf_file = l:hist_dir . '/' . get(l:entry, 'pdf', '')

    if filereadable(l:pdf_file)
        call system('open ' . shellescape(l:pdf_file))
        echom "Opened PDF: " . get(l:entry, 'name', '')
    else
        call s:Error("PDF not found for this plot")
    endif
endfunction

" Save: export plot under cursor
function! s:PlotHUDSave() abort
    let l:num = s:PlotHUDGetNum()
    let l:entry = s:PlotHUDGetEntry(l:num)

    let l:default_name = get(l:entry, 'name', 'plot')
    let l:filename = input('Save as: ', getcwd() . '/' . l:default_name . '.pdf')

    if empty(l:filename)
        return
    endif

    let l:hist_dir = s:GetHistoryDir()
    if l:num > 0 && !empty(l:entry)
        " Save specific plot from history
        if l:filename =~# '\.pdf$'
            let l:src = l:hist_dir . '/' . get(l:entry, 'pdf', '')
        else
            let l:src = l:hist_dir . '/' . get(l:entry, 'png', '')
        endif
    else
        " Save current plot
        if l:filename =~# '\.pdf$'
            let l:src = s:GetPlotPdf()
        else
            let l:src = s:GetPlotFile()
        endif
    endif

    if filereadable(l:src)
        call system('cp ' . shellescape(l:src) . ' ' . shellescape(l:filename))
        echom "Saved: " . l:filename
    else
        call s:Error("Source file not found")
    endif
endfunction

" Delete: remove plot from history
function! s:PlotHUDDelete() abort
    let l:num = s:PlotHUDGetNum()
    if l:num == 0
        echom "Position cursor on a plot line"
        return
    endif

    let l:entry = s:PlotHUDGetEntry(l:num)
    if empty(l:entry)
        return
    endif

    let l:confirm = input('Delete "' . get(l:entry, 'name', 'plot') . '"? (y/n): ')
    if l:confirm !=# 'y'
        echo " Cancelled"
        return
    endif

    " Remove files
    let l:hist_dir = s:GetHistoryDir()
    let l:png_file = l:hist_dir . '/' . get(l:entry, 'png', '')
    let l:pdf_file = l:hist_dir . '/' . get(l:entry, 'pdf', '')

    if filereadable(l:png_file)
        call delete(l:png_file)
    endif
    if filereadable(l:pdf_file)
        call delete(l:pdf_file)
    endif

    " Update index
    call remove(b:plot_index.plots, l:num - 1)

    " Write updated index
    let l:index_file = s:GetHistoryIndex()
    try
        call writefile([json_encode(b:plot_index)], l:index_file)
    catch
        call s:Error("Failed to update index")
    endtry

    " Refresh display
    call s:GeneratePlotHUDContent()
    echom "Deleted plot " . l:num
endfunction

" Refresh: reload plot history from disk
function! s:PlotHUDRefresh() abort
    let l:index_file = s:GetHistoryIndex()
    if !filereadable(l:index_file)
        call s:Error("No plot history")
        return
    endif

    let l:json_content = join(readfile(l:index_file), '')
    try
        let b:plot_index = json_decode(l:json_content)
    catch
        call s:Error("Failed to parse plot history")
        return
    endtry

    call s:GeneratePlotHUDContent()
    echom "Plot HUD refreshed"
endfunction

" Generate Plot HUD for dashboard tab (wrapper for CreateHUDTab)
function! s:GeneratePlotHUD() abort
    " Read plot history
    let l:index_file = s:GetHistoryIndex()
    if filereadable(l:index_file)
        let l:json_content = join(readfile(l:index_file), '')
        try
            let b:plot_index = json_decode(l:json_content)
        catch
            let b:plot_index = {'plots': [], 'current': 0}
        endtry
    else
        let b:plot_index = {'plots': [], 'current': 0}
    endif

    call s:GeneratePlotHUDContent()
    call s:SetupPlotHUDMappings()
endfunction

" Legacy alias for backward compatibility
function! s:OpenPlotGallery() abort
    call s:RPlotHUD()
endfunction

"------------------------------------------------------------------------------
" Cleanup
"------------------------------------------------------------------------------
function! s:OnRTerminalClose() abort
    call s:StopPlotWatcher()
    call system('kitty @ close-window --match title:' . s:pane_title . ' 2>/dev/null')
    let s:docker_r_terminal_bufnr = -1
endfunction

function! s:CleanupPlotPaneIfRTerminal() abort
    let l:bufname = expand('<afile>')
    if l:bufname =~? 'R-\|r-\|R$\|!/.*R\|terminal.*R'
        call s:OnRTerminalClose()
    endif
endfunction

function! s:RTerminalExitCallback(job, exit_status) abort
    call s:OnRTerminalClose()
endfunction

"------------------------------------------------------------------------------
" Ex Commands
"------------------------------------------------------------------------------
command! -bar RPlotShow call s:DisplayPlot()
command! -bar RPlotZoom call s:ZoomPlot()
command! -bar RPlotPrev call s:PlotPrev()
command! -bar RPlotNext call s:PlotNext()
command! -bar RPlotHistory call s:PlotHistory()
command! -bar RPlotHUD call s:RPlotHUD()
command! -bar RPlotGallery call s:RPlotHUD()
command! -bar RPlotSavePdf call s:PlotSavePdf()
command! -bar RPlotSavePng call s:PlotSavePng()
command! -bar RPlotWatchStart call s:StartPlotWatcher()
command! -bar RPlotWatchStop call s:StopPlotWatcher()

" Debug command
command! -bar RPlotDebug echo "Signal: " . s:GetSignalFile() . " mtime=" . getftime(s:GetSignalFile()) . " cached=" . s:plot_signal_mtime . " | Pane exists: " . s:PlotPaneExists()

"------------------------------------------------------------------------------
" Key Mappings (to be added to autocmd section)
"------------------------------------------------------------------------------
" Plot commands:
"   <LocalLeader>]    Zoom plot (open PDF)
"   <LocalLeader>pp   Previous plot
"   <LocalLeader>pn   Next plot
"   <LocalLeader>ph   Plot history
"   <LocalLeader>pG   Plot gallery
"   <LocalLeader>ps   Save as PDF
"   <LocalLeader>pS   Save as PNG
" Simple Object Inspection Commands
command! -bar RWorkspace call s:RWorkspaceOverview()  
command! -bar -nargs=? RInspect call s:RInspectObject(<q-args>)
command! -bar RMemoryHUD call s:RMemoryHUD()
command! -bar RDataFrameHUD call s:RDataFrameHUD()  
command! -bar RPackageHUD call s:RPackageHUD()
command! -bar RDataViewer call s:RDataViewer()
command! -bar REnvironmentHUD call s:REnvironmentHUD()
command! -bar ROptionsHUD call s:ROptionsHUD()
command! -bar RHUDDashboard call s:RHUDDashboard()
command! -bar RInstallDplyr call s:Send_to_r('install.packages("dplyr")', 1)

"------------------------------------------------------------------------------
" Helper Functions for Commands
"------------------------------------------------------------------------------

" Generic function for R commands that can take optional arguments
function! s:RCommandWithArg(action, arg, ...) abort
    " Use argument or word under cursor, with validation
    let target = empty(a:arg) ? expand('<cword>') : a:arg
    if empty(target)
        call s:Error("No argument provided and no word under cursor for " . a:action . "()")
        return
    endif
    
    let stay_on_line = a:0 > 0 ? a:1 : 1
    call s:Send_to_r(a:action . '(' . target . ')', stay_on_line)
    echom "Executed " . a:action . "(" . target . ")"
endfunction

" Object inspection wrapper function - maintains backward compatibility
" Parameters:
"   a:action (string) - R function name (dim, head, str, etc.)  
"   a:stay_on_line (boolean) - whether to keep cursor on current line
function! s:RAction(action, stay_on_line) abort
    call s:RCommandWithArg(a:action, '', a:stay_on_line)
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
" Terminal Association Utility Functions
"------------------------------------------------------------------------------

" Show which terminal is associated with current R buffer
function! s:RShowTerminalCommand() abort
    if &filetype != 'r' && &filetype != 'rmd' && &filetype != 'quarto'
        call s:Error("This command only works in R/Rmd/Quarto files")
        return
    endif
    
    let buffer_name = expand('%:t')
    let terminal_name = s:GetTerminalName()
    
    if exists('b:r_terminal_id') && b:r_terminal_id > 0
        let terminal_buffers = s:compat_term_list()
        if index(terminal_buffers, b:r_terminal_id) >= 0
            echohl Title
            echo "Terminal Association for: " . buffer_name
            echohl None
            echo "  ├─ Terminal Name: " . terminal_name
            echo "  ├─ Terminal Buffer ID: " . b:r_terminal_id
            echo "  └─ Status: Active"
        else
            echohl WarningMsg
            echo "Terminal Association for: " . buffer_name
            echohl None
            echo "  ├─ Terminal Name: " . terminal_name
            echo "  ├─ Terminal Buffer ID: " . b:r_terminal_id . " (INVALID)"
            echo "  └─ Status: Terminal no longer exists"
        endif
    else
        echohl Comment
        echo "Terminal Association for: " . buffer_name
        echohl None
        echo "  ├─ Terminal Name: " . terminal_name . " (would be created)"
        echo "  └─ Status: No terminal associated yet"
    endif
endfunction

" List all R file-terminal associations
function! s:RListTerminalsCommand() abort
    let associations = []
    let terminal_buffers = s:compat_term_list()
    
    " Scan all buffers for R files with terminal associations
    for bufnr in range(1, bufnr('$'))
        if buflisted(bufnr)
            let bufname = bufname(bufnr)
            let filetype = getbufvar(bufnr, '&filetype')
            
            if filetype == 'r' || filetype == 'rmd' || filetype == 'quarto'
                let terminal_id = getbufvar(bufnr, 'r_terminal_id')
                let buffer_display = empty(bufname) ? '[No Name]' : fnamemodify(bufname, ':t')
                
                if terminal_id > 0
                    let status = index(terminal_buffers, terminal_id) >= 0 ? 'Active' : 'Dead'
                    call add(associations, {
                        \ 'buffer': buffer_display,
                        \ 'bufnr': bufnr,
                        \ 'terminal_id': terminal_id,
                        \ 'status': status
                        \ })
                else
                    call add(associations, {
                        \ 'buffer': buffer_display,
                        \ 'bufnr': bufnr,
                        \ 'terminal_id': 0,
                        \ 'status': 'None'
                        \ })
                endif
            endif
        endif
    endfor
    
    " Display results
    if empty(associations)
        echohl Comment
        echo "No R files currently open"
        echohl None
        return
    endif
    
    echohl Title
    echo "R File ↔ Terminal Associations:"
    echohl None
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for assoc in associations
        let status_color = assoc.status == 'Active' ? 'DiffAdd' : 
                         \ assoc.status == 'Dead' ? 'ErrorMsg' : 'Comment'
        
        echo printf("  %-20s", assoc.buffer)
        echohl Operator | echo " ↔ " | echohl None
        
        if assoc.terminal_id > 0
            echo "Terminal " . assoc.terminal_id . " "
            execute 'echohl ' . status_color
            echo "(" . assoc.status . ")"
            echohl None
        else
            echohl Comment
            echo "(No terminal)"
            echohl None
        endif
    endfor
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Use :RSwitchToTerminal to jump to your buffer's terminal"
endfunction

" Switch to the terminal associated with current R buffer
function! s:RSwitchToTerminalCommand() abort
    if &filetype != 'r' && &filetype != 'rmd' && &filetype != 'quarto'
        call s:Error("This command only works in R/Rmd/Quarto files")
        return
    endif
    
    let terminal_id = s:GetBufferTerminal()
    
    if terminal_id == -1
        call s:Error("No terminal associated with this buffer. Use <LocalLeader>r to create one.")
        return
    endif
    
    " Find window containing the terminal
    let terminal_winnr = bufwinnr(terminal_id)
    
    if terminal_winnr != -1
        " Terminal is visible, jump to it
        execute terminal_winnr . 'wincmd w'
        echom "Switched to terminal for " . expand('%:t')
    else
        " Terminal exists but not visible, open it
        execute 'vertical sbuffer ' . terminal_id
        echom "Opened terminal for " . expand('%:t')
    endif
endfunction

" Open buffer-specific R terminal in new split window
" Parameters:
"   a:split_type (string) - 'horizontal', 'vertical', or 'h'/'v' for short
" Creates or opens the buffer-specific terminal in a new split
function! s:ROpenSplitCommand(split_type) abort
    if &filetype != 'r' && &filetype != 'rmd' && &filetype != 'quarto'
        call s:Error("This command only works in R/Rmd/Quarto files")
        return
    endif
    
    " Validate and normalize split type
    let split_cmd = ''
    if a:split_type == 'vertical' || a:split_type == 'v' || a:split_type == ''
        let split_cmd = 'vertical split'
        let split_desc = 'vertical'
    elseif a:split_type == 'horizontal' || a:split_type == 'h'
        let split_cmd = 'split'
        let split_desc = 'horizontal'
    else
        call s:Error("Invalid split type. Use 'vertical', 'horizontal', 'v', or 'h'")
        return
    endif
    
    " Get or create the buffer-specific terminal
    let terminal_id = s:GetBufferTerminal()
    
    if terminal_id == -1
        call s:Error("Failed to create terminal for this buffer")
        return
    endif
    
    " Check if terminal is already visible in a window
    let terminal_winnr = bufwinnr(terminal_id)
    
    if terminal_winnr != -1
        " Terminal is already visible, just switch to it
        execute terminal_winnr . 'wincmd w'
        echom "Terminal for " . expand('%:t') . " is already open (switched to it)"
        return
    endif
    
    " Save current window and buffer info
    let current_buffer = bufnr('%')
    let buffer_name = expand('%:t')
    
    " Create new split window and open the terminal buffer
    try
        execute split_cmd
        execute 'buffer ' . terminal_id
        
        " Resize the terminal window using configured or dynamic width
        if split_desc == 'vertical'
            " Check if user configured width, otherwise use dynamic sizing
            if exists('g:zzvim_r_terminal_width') && g:zzvim_r_terminal_width > 0
                let terminal_width = g:zzvim_r_terminal_width
            else
                " Use half of current window width for dynamic sizing
                let terminal_width = winwidth(0) / 2
            endif
            execute 'vertical resize ' . terminal_width
        else
            " For horizontal splits, use a reasonable height
            let terminal_height = get(g:, 'zzvim_r_terminal_height', 15)
            execute 'resize ' . terminal_height
        endif
        
        echom "Opened " . split_desc . " split with R terminal for " . buffer_name
        
    catch /^Vim\%((\a\+)\)\=:E/
        call s:Error("Failed to open terminal in split: " . v:exception)
        return
    endtry
endfunction

"------------------------------------------------------------------------------
" Public API Functions for Modular Components
"------------------------------------------------------------------------------

" Test wrapper functions - expose script-local functions for testing
function! ZzvimRTestIsBlockStart(line) abort
    return s:IsBlockStart(a:line)
endfunction

function! ZzvimRTestGetTextByType(selection_type) abort
    return s:GetTextByType(a:selection_type)
endfunction

"------------------------------------------------------------------------------
" Simple Object Inspection Functions
"------------------------------------------------------------------------------

" Show workspace overview - replaces complex object browser
function! s:RWorkspaceOverview() abort
    call s:Send_to_r('{cat("\n=== Workspace ===\n");' .
                \ 'for(o in ls())cat(o,":",class(get(o))[1],"\n");' .
                \ 'cat("=================\n")}', 1)
endfunction

" Inspect object at cursor or by name  
function! s:RInspectObject(...) abort
    let obj = a:0 > 0 ? a:1 : expand('<cword>')
    if empty(obj) | echom "No object specified" | return | endif
    call s:Send_to_r('{cat("\n=== ' . obj . ' ===\n");' .
                \ 'if(exists("' . obj . '")){' .
                \ 'if(is.data.frame(' . obj . ')&&require(dplyr,quietly=T))' .
                \ 'glimpse(' . obj . ') else str(' . obj . ')}' .
                \ 'else cat("Not found: ' . obj . '\n")}', 1)
endfunction

" HUD Function 1: Memory Usage Display - Show memory usage of workspace objects
function! s:RMemoryHUD() abort
    call s:Send_to_r('{cat("\n=== Memory Usage ===\n");' .
                \ 'objs <- ls(); if(length(objs) > 0) {' .
                \ 'mem_data <- sapply(objs, function(x) object.size(get(x)));' .
                \ 'mem_mb <- round(mem_data / 1024^2, 2);' .
                \ 'total_mb <- round(sum(mem_data) / 1024^2, 2);' .
                \ 'for(i in order(mem_data, decreasing=T)) ' .
                \ 'cat(sprintf("%-15s: %8.2f MB\n", objs[i], mem_mb[i]));' .
                \ 'cat(sprintf("%-15s: %8.2f MB\n", "TOTAL", total_mb))' .
                \ '} else cat("No objects in workspace\n");' .
                \ 'cat("==================\n")}', 1)
endfunction

" HUD Function 2: Data Frame Summary - Quick overview of all data frames
function! s:RDataFrameHUD() abort
    call s:Send_to_r('{cat("\n=== Data Frames ===\n");' .
                \ 'objs <- ls(); dfs <- character(0);' .
                \ 'for(obj in objs) if(is.data.frame(get(obj))) dfs <- c(dfs, obj);' .
                \ 'if(length(dfs) > 0) {' .
                \ 'for(df in dfs) {' .
                \ 'dims <- dim(get(df));' .
                \ 'cat(sprintf("%-15s: %d rows × %d cols\n", df, dims[1], dims[2]))' .
                \ '}} else cat("No data frames found\n");' .
                \ 'cat("=================\n")}', 1)
endfunction

" HUD Function 3: Package Status - Show loaded packages and search path
function! s:RPackageHUD() abort
    call s:Send_to_r('{cat("\n=== Package Status ===\n");' .
                \ 'loaded <- search()[grep("package:", search())];' .
                \ 'loaded <- sub("package:", "", loaded);' .
                \ 'cat("Loaded packages:\n");' .
                \ 'for(pkg in loaded) cat(sprintf("  %s\n", pkg));' .
                \ 'cat(sprintf("Total loaded: %d packages\n", length(loaded)));' .
                \ 'cat("====================\n")}', 1)
endfunction

" HUD Function 4: Data Viewer - RStudio-style data frame viewer with tabulate
function! s:RDataViewer() abort
    " Get object name under cursor
    let obj_name = expand('<cword>')
    if empty(obj_name)
        call s:Error("No object under cursor")
        return
    endif
    
    " Create temp space-separated file path  
    let data_file = tempname() . '.txt'
    let data_file_escaped = substitute(data_file, '\', '/', 'g')  " Fix Windows paths
    
    " Phase 1: Check if object exists and is a data frame
    let check_cmd = 'if(exists("' . obj_name . '") && is.data.frame(' . obj_name . ')) {' .
                \ 'write.table(' . obj_name . ', "' . data_file_escaped . '", ' .
                \ 'sep=" ", row.names=FALSE, col.names=TRUE, quote=FALSE); ' .
                \ 'cat("Data viewer: Exported ' . obj_name . ' with space delimiter\n")' .
                \ '} else {' .
                \ 'cat("Error: ' . obj_name . ' is not a data frame or does not exist\n")' .
                \ '}'
    
    call s:Send_to_r(check_cmd, 1)
    
    " Brief delay to ensure file is written
    sleep 200m
    
    " Phase 2: Check if data file was created successfully
    if !filereadable(data_file)
        call s:Error("Failed to export data frame: " . obj_name)
        return
    endif
    
    " Phase 3: Open data in new buffer with appropriate settings
    " Create a unique buffer name for the data viewer
    let viewer_buffer = obj_name . '_viewer.txt'
    
    try
        " Open new split window with the space-delimited data
        execute 'split ' . fnameescape(data_file)
        call s:SetupViewerBuffer()
        setlocal filetype=
        execute 'file ' . fnameescape(viewer_buffer)

        " Apply tabulate plugin if available
        call s:ApplyTabulation()
        setlocal readonly

        " Move to top of data (skip header)
        normal! gg
        if line('$') > 1
            normal! j
        endif
        echom "Data viewer: Press 'q' or <ESC> to close (" . obj_name . ")"

    catch
        call s:Error("Failed to open data viewer: " . v:exception)
    finally
        " Clean up temp file
        if filereadable(data_file)
            call delete(data_file)
        endif
    endtry
endfunction

" HUD Function 5: Environment Variables Viewer - System environment variables in tabulated format
function! s:REnvironmentHUD() abort
    " Create temp space-separated file for environment variables
    let env_file = tempname() . '.txt'
    let env_file_escaped = substitute(env_file, '\', '/', 'g')  " Fix Windows paths
    
    " Phase 1: Export environment variables as a data frame with R_ variables prioritized
    let env_cmd = '{' .
                \ 'env_vars <- Sys.getenv(); ' .
                \ 'env_df <- data.frame(' .
                \ 'Variable = names(env_vars), ' .
                \ 'Value = as.character(env_vars), ' .
                \ 'stringsAsFactors = FALSE); ' .
                \ 'env_df$R_priority <- ifelse(grepl("^R_", env_df$Variable), 1, 2); ' .
                \ 'env_df <- env_df[order(env_df$R_priority, env_df$Variable), ]; ' .
                \ 'env_df$R_priority <- NULL; ' .
                \ 'write.table(env_df, "' . env_file_escaped . '", ' .
                \ 'sep=" ", row.names=FALSE, col.names=TRUE, quote=FALSE); ' .
                \ 'cat("Environment HUD: Exported", nrow(env_df), "environment variables\n")' .
                \ '}'
    
    call s:Send_to_r(env_cmd, 1)
    
    " Brief delay to ensure file is written
    sleep 200m
    
    " Phase 2: Check if environment file was created successfully
    if !filereadable(env_file)
        call s:Error("Failed to export environment variables")
        return
    endif
    
    " Phase 3: Open environment data in new buffer
    try
        execute 'split ' . fnameescape(env_file)
        call s:SetupViewerBuffer()
        setlocal filetype=
        execute 'file environment_variables.txt'
        call s:ApplyTabulation()
        setlocal readonly
        normal! gg
        if line('$') > 1
            normal! j
        endif
        echo "Environment HUD: Press 'q' or <ESC> to close, '/' to search"

    catch
        call s:Error("Failed to open environment variables viewer: " . v:exception)
    finally
        " Clean up temp file
        if filereadable(env_file)
            call delete(env_file)
        endif
    endtry
endfunction

" HUD Function 6: R Options Viewer - Current R options in tabulated format
function! s:ROptionsHUD() abort
    " Create temp space-separated file for R options
    let options_file = tempname() . '.txt'
    let options_file_escaped = substitute(options_file, '\', '/', 'g')  " Fix Windows paths
    
    " Phase 1: Export R options as a data frame
    let options_cmd = '{' .
                \ 'r_options <- options(); ' .
                \ 'opt_df <- data.frame(' .
                \ 'Option = names(r_options), ' .
                \ 'Value = sapply(r_options, function(x) {' .
                \ 'if(is.null(x)) "NULL" ' .
                \ 'else if(is.function(x)) "[function]" ' .
                \ 'else if(length(x) > 1) paste0("[", length(x), " values]") ' .
                \ 'else if(is.logical(x)) as.character(x) ' .
                \ 'else if(is.numeric(x)) as.character(x) ' .
                \ 'else tryCatch(as.character(x), error = function(e) "[complex object]")' .
                \ '}), ' .
                \ 'stringsAsFactors = FALSE); ' .
                \ 'opt_df <- opt_df[order(opt_df$Option), ]; ' .
                \ 'write.table(opt_df, "' . options_file_escaped . '", ' .
                \ 'sep=" ", row.names=FALSE, col.names=TRUE, quote=FALSE); ' .
                \ 'cat("R Options HUD: Exported", nrow(opt_df), "R options\n")' .
                \ '}'
    
    call s:Send_to_r(options_cmd, 1)
    
    " Brief delay to ensure file is written
    sleep 200m
    
    " Phase 2: Check if options file was created successfully
    if !filereadable(options_file)
        call s:Error("Failed to export R options")
        return
    endif
    
    " Phase 3: Open R options data in new buffer
    try
        execute 'split ' . fnameescape(options_file)
        call s:SetupViewerBuffer()
        setlocal filetype=
        execute 'file r_options.txt'
        call s:ApplyTabulation()
        setlocal readonly
        normal! gg
        if line('$') > 1
            normal! j
        endif
        echo "R Options HUD: Press 'q' or <ESC> to close, '/' to search"

    catch
        call s:Error("Failed to open R options viewer: " . v:exception)
    finally
        " Clean up temp file
        if filereadable(options_file)
            call delete(options_file)
        endif
    endtry
endfunction

" =============================================================================
" Unified HUD Dashboard - All workspace information in separate tabs
" =============================================================================

" HUD Dashboard: Open all HUD displays in separate tabs for quick overview
function! s:RHUDDashboard() abort
    " Check if R terminal is already running for current buffer
    if !exists('b:r_terminal_id') || b:r_terminal_id <= 0
        echo "HUD Dashboard: Start R session first with <LocalLeader>r"
        return
    endif
    
    " Verify the existing terminal is still running
    let terminal_buffers = s:compat_term_list()
    if index(terminal_buffers, b:r_terminal_id) < 0 || s:compat_term_getstatus(b:r_terminal_id) !~# 'running'
        echo "HUD Dashboard: R session not running. Start with <LocalLeader>r"
        return
    endif
    
    echo "HUD Dashboard: Opening workspace overview..."
    
    " Capture source file name and R terminal ID before creating tabs
    let l:source_file = fnamemodify(bufname('%'), ':t:r')  " Get filename without extension
    if empty(l:source_file)
        let l:source_file = 'unnamed'
    endif
    let l:r_terminal_id = b:r_terminal_id  " Capture the R terminal ID
    
    " Store current tab for restoration if needed
    let l:original_tab = tabpagenr()
    
    " Close any existing HUD tabs first (cleanup)
    call s:CloseHUDTabs()
    
    " Create tabs for each HUD display
    " Tab 1: Memory Usage
    call s:CreateHUDTab('Memory', 'memory_usage', function('s:GenerateMemoryHUD'), l:source_file, l:r_terminal_id)
    
    " Tab 2: Data Frames  
    call s:CreateHUDTab('DataFrames', 'data_frames', function('s:GenerateDataFrameHUD'), l:source_file, l:r_terminal_id)
    
    " Tab 3: Packages
    call s:CreateHUDTab('Packages', 'packages', function('s:GeneratePackageHUD'), l:source_file, l:r_terminal_id)
    
    " Tab 4: Environment Variables
    call s:CreateHUDTab('Environment', 'environment', function('s:GenerateEnvironmentHUD'), l:source_file, l:r_terminal_id)
    
    " Tab 5: R Options
    call s:CreateHUDTab('Options', 'options', function('s:GenerateOptionsHUD'), l:source_file, l:r_terminal_id)

    " Tab 6: Plot History
    call s:CreateHUDTab('Plots', 'plots', function('s:GeneratePlotHUD'), l:source_file, l:r_terminal_id)

    " Go to first HUD tab
    1tabnext

    echo "HUD Dashboard: 6 tabs created. Use gt/gT to navigate, <LocalLeader>0 to refresh"
endfunction

" Helper: Close existing HUD tabs to prevent accumulation
function! s:CloseHUDTabs() abort
    " Close all tabs that start with 'HUD_' (any file, any HUD type)
    " Iterate through tabs from last to first (to avoid index shifting)
    for l:tabnr in range(tabpagenr('$'), 1, -1)
        let l:bufname = bufname(tabpagebuflist(l:tabnr)[0])
        
        " Match any buffer name starting with 'HUD_'
        if l:bufname =~# '^HUD_'
            execute l:tabnr . 'tabclose'
        endif
    endfor
endfunction

" Helper: Create individual HUD tab with data
function! s:CreateHUDTab(tab_name, file_suffix, data_generator, source_file, r_terminal_id) abort
    tabnew
    let l:buffer_name = 'HUD_' . a:source_file . '_' . a:tab_name
    execute 'file ' . l:buffer_name
    let b:r_terminal_id = a:r_terminal_id
    call s:SetupViewerBuffer()
    call a:data_generator()
    setlocal readonly

    " Standard HUD mappings
    nnoremap <buffer> <silent> <LocalLeader>0 :call <SID>RHUDDashboard()<CR>
    nnoremap <buffer> <silent> q :bwipeout<CR>

    " Interactive HUD mappings for drill-down
    nnoremap <buffer> <silent> <CR> :call <SID>HUDInspectLine()<CR>
    nnoremap <buffer> <silent> o :call <SID>HUDOpenViewer()<CR>
    nnoremap <buffer> <silent> h :call <SID>HUDHead()<CR>
    nnoremap <buffer> <silent> s :call <SID>HUDStr()<CR>
    nnoremap <buffer> <silent> r :call <SID>RHUDDashboard()<CR>

    normal! gg
    if exists('+showtabline')
        execute 'set showtabline=2'
    endif
endfunction

" HUD Interactive Helper Functions
" Extract object name from current HUD line
function! s:HUDGetObjectName() abort
    let l:line = getline('.')
    " Try to extract first word (object name) from various HUD formats
    " Memory HUD: "object_name     1.23"
    " DataFrame HUD: "df_name       100    50"
    " Workspace: "obj : class"
    let l:obj = matchstr(l:line, '^\s*\zs[a-zA-Z_.][a-zA-Z0-9_.]*')
    return l:obj
endfunction

" Inspect object on current line with str()/glimpse()
function! s:HUDInspectLine() abort
    let l:obj = s:HUDGetObjectName()
    if empty(l:obj)
        echom "No object found on this line"
        return
    endif
    call s:RInspectObject(l:obj)
endfunction

" Open data viewer for object on current line
function! s:HUDOpenViewer() abort
    let l:obj = s:HUDGetObjectName()
    if empty(l:obj)
        echom "No object found on this line"
        return
    endif
    " Check if it's a data frame before opening viewer
    call s:Send_to_r('if(is.data.frame(' . l:obj . ')) print(head(' . l:obj . ', 20)) else str(' . l:obj . ')', 1)
endfunction

" Show head() for object on current line
function! s:HUDHead() abort
    let l:obj = s:HUDGetObjectName()
    if empty(l:obj)
        echom "No object found on this line"
        return
    endif
    call s:Send_to_r('head(' . l:obj . ')', 1)
endfunction

" Show str() for object on current line
function! s:HUDStr() abort
    let l:obj = s:HUDGetObjectName()
    if empty(l:obj)
        echom "No object found on this line"
        return
    endif
    call s:Send_to_r('str(' . l:obj . ')', 1)
endfunction

" HUD Data Generators - Generate content for each tab
function! s:GenerateMemoryHUD() abort
    " Create temp file for memory data
    let l:temp_file = tempname()
    
    let l:mem_cmd = '{' .
                \ 'output <- c();' .
                \ 'output <- c(output, "MEMORY USAGE OVERVIEW");' .
                \ 'output <- c(output, "====================", "");' .
                \ 'objs <- ls(); if(length(objs) > 0) {' .
                \ 'mem_data <- sapply(objs, function(x) object.size(get(x)));' .
                \ 'mem_mb <- round(mem_data / 1024^2, 2);' .
                \ 'total_mb <- round(sum(mem_data) / 1024^2, 2);' .
                \ 'output <- c(output, sprintf("%-20s %10s", "Object", "Memory (MB)"));' .
                \ 'output <- c(output, sprintf("%-20s %10s", "------", "----------"));' .
                \ 'for(i in order(mem_data, decreasing=T)) ' .
                \ 'output <- c(output, sprintf("%-20s %10.2f", objs[i], mem_mb[i]));' .
                \ 'output <- c(output, sprintf("%-20s %10.2f", "TOTAL WORKSPACE", total_mb))' .
                \ '} else output <- c(output, "No objects in workspace");' .
                \ 'output <- c(output, "", "Press <LocalLeader>0 to refresh all HUD tabs");' .
                \ 'writeLines(output, "' . l:temp_file . '")' .
                \ '}'
    
    call s:Send_to_r(l:mem_cmd, 1)
    
    " Wait and read file content
    sleep 500m
    if filereadable(l:temp_file)
        let l:content = readfile(l:temp_file)
        if len(l:content) > 0
            call setline(1, l:content)
        else
            call setline(1, ['Error: Memory data file is empty'])
        endif
        call delete(l:temp_file)
    else
        call setline(1, ['Error: Could not generate memory data - file not found'])
    endif
endfunction

function! s:GenerateDataFrameHUD() abort
    let l:temp_file = tempname()
    
    let l:df_cmd = '{' .
                \ 'output <- c();' .
                \ 'output <- c(output, "DATA FRAMES OVERVIEW");' .
                \ 'output <- c(output, "===================", "");' .
                \ 'objs <- ls(); dfs <- character(0);' .
                \ 'for(obj in objs) if(is.data.frame(get(obj))) dfs <- c(dfs, obj);' .
                \ 'if(length(dfs) > 0) {' .
                \ 'output <- c(output, sprintf("%-20s %8s %8s", "Data Frame", "Rows", "Columns"));' .
                \ 'output <- c(output, sprintf("%-20s %8s %8s", "----------", "----", "-------"));' .
                \ 'for(df in dfs) {' .
                \ 'dims <- dim(get(df));' .
                \ 'output <- c(output, sprintf("%-20s %8d %8d", df, dims[1], dims[2]))' .
                \ '}} else output <- c(output, "No data frames found");' .
                \ 'output <- c(output, "", "Press <LocalLeader>0 to refresh all HUD tabs");' .
                \ 'writeLines(output, "' . l:temp_file . '")' .
                \ '}'
    
    call s:Send_to_r(l:df_cmd, 1)
    
    sleep 500m
    if filereadable(l:temp_file)
        let l:content = readfile(l:temp_file)
        if len(l:content) > 0
            call setline(1, l:content)
        else
            call setline(1, ['Error: Data frame data file is empty'])
        endif
        call delete(l:temp_file)
    else
        call setline(1, ['Error: Could not generate data frame data - file not found'])
    endif
endfunction

function! s:GeneratePackageHUD() abort
    let l:temp_file = tempname()
    
    let l:pkg_cmd = '{' .
                \ 'output <- c();' .
                \ 'output <- c(output, "LOADED PACKAGES");' .
                \ 'output <- c(output, "===============", "");' .
                \ 'loaded <- search()[grep("package:", search())];' .
                \ 'loaded <- sub("package:", "", loaded);' .
                \ 'output <- c(output, sprintf("Total loaded packages: %d", length(loaded)), "");' .
                \ 'for(pkg in loaded) output <- c(output, sprintf("  %-30s", pkg));' .
                \ 'output <- c(output, "", "Press <LocalLeader>0 to refresh all HUD tabs");' .
                \ 'writeLines(output, "' . l:temp_file . '")' .
                \ '}'
    
    call s:Send_to_r(l:pkg_cmd, 1)
    
    sleep 500m
    if filereadable(l:temp_file)
        let l:content = readfile(l:temp_file)
        if len(l:content) > 0
            call setline(1, l:content)
        else
            call setline(1, ['Error: Package data file is empty'])
        endif
        call delete(l:temp_file)
    else
        call setline(1, ['Error: Could not generate package data - file not found'])
    endif
endfunction

function! s:GenerateEnvironmentHUD() abort
    " Create temp space-separated file for environment variables  
    let l:env_file = tempname() . '.txt'
    let l:env_file_escaped = substitute(l:env_file, '\', '/', 'g')  " Fix Windows paths
    
    let l:env_cmd = '{' .
                \ 'env_vars <- Sys.getenv(); ' .
                \ 'env_df <- data.frame(' .
                \ 'Variable = names(env_vars), ' .
                \ 'Value = as.character(env_vars), ' .
                \ 'stringsAsFactors = FALSE); ' .
                \ 'env_df <- env_df[order(env_df$Variable), ]; ' .
                \ 'write.table(env_df, "' . l:env_file_escaped . '", ' .
                \ 'sep="  ", row.names=FALSE, col.names=TRUE, quote=FALSE)' .
                \ '}'
    
    call s:Send_to_r(l:env_cmd, 1)
    
    sleep 300m
    if filereadable(l:env_file)
        let l:content = ['ENVIRONMENT VARIABLES', '====================', ''] + readfile(l:env_file) + ['', 'Press <LocalLeader>0 to refresh all HUD tabs']
        call setline(1, l:content)
        call delete(l:env_file)
        
        " Apply tabulation if available
        call s:ApplyTabulation()
    else
        call setline(1, ['Error: Could not generate environment data'])
    endif
endfunction

function! s:GenerateOptionsHUD() abort
    " Create temp space-separated file for R options
    let l:options_file = tempname() . '.txt' 
    let l:options_file_escaped = substitute(l:options_file, '\', '/', 'g')  " Fix Windows paths
    
    let l:options_cmd = '{' .
                \ 'r_options <- options(); ' .
                \ 'opt_df <- data.frame(' .
                \ 'Option = names(r_options), ' .
                \ 'Value = sapply(r_options, function(x) {' .
                \ 'if(is.null(x)) "NULL" ' .
                \ 'else if(is.function(x)) "[function]" ' .
                \ 'else if(length(x) > 1) paste0("[", length(x), " values]") ' .
                \ 'else if(is.logical(x)) as.character(x) ' .
                \ 'else if(is.numeric(x)) as.character(x) ' .
                \ 'else {val <- tryCatch(as.character(x), error = function(e) "[complex]"); ' .
                \ 'if(nchar(val) > 50) paste0(substr(val, 1, 47), "...") else val}' .
                \ '}), ' .
                \ 'stringsAsFactors = FALSE); ' .
                \ 'opt_df <- opt_df[order(opt_df$Option), ]; ' .
                \ 'write.table(opt_df, "' . l:options_file_escaped . '", ' .
                \ 'sep="  ", row.names=FALSE, col.names=TRUE, quote=FALSE)' .
                \ '}'
    
    call s:Send_to_r(l:options_cmd, 1)
    
    sleep 300m  
    if filereadable(l:options_file)
        let l:content = ['R SESSION OPTIONS', '==================', ''] + readfile(l:options_file) + ['', 'Press <LocalLeader>0 to refresh all HUD tabs']
        call setline(1, l:content)
        call delete(l:options_file)
        
        " Apply tabulation if available
        call s:ApplyTabulation()
    else
        call setline(1, ['Error: Could not generate options data'])
    endif
endfunction

" Helper: Apply tabulation formatting if plugins are available
function! s:ApplyTabulation() abort
    " Check for Tabularize plugin (most common)
    if exists(':Tabularize')
        try
            silent! execute '%Tabularize /  /'
        catch
            " Silently fail if tabularize has issues
        endtry
    " Check for EasyAlign plugin (alternative)
    elseif exists(':EasyAlign')
        try
            silent! execute '%EasyAlign *\ '
        catch
            " Silently fail if EasyAlign has issues
        endtry
    endif
endfunction

" ============================================================================
" R Markdown Rendering Functions
" ============================================================================

" Configuration for help buffer display
let g:zzvim_r_help_position = get(g:, 'zzvim_r_help_position', 'vsplit')
let g:zzvim_r_help_width = get(g:, 'zzvim_r_help_width', 80)

" Render R Markdown/Quarto document
" Parameters:
"   format (string) - output format (html_document, pdf_document, word_document)
"                     defaults to html_document if empty
function! s:RMarkdownRender(format) abort
    let l:format = empty(a:format) ? 'html_document' : a:format
    let l:file = expand('%:p')
    let l:file_escaped = substitute(l:file, '\', '/', 'g')

    " Save current buffer before rendering
    if &modified
        write
    endif

    " Build and send render command
    let l:cmd = printf('rmarkdown::render("%s", output_format = "%s")',
        \ l:file_escaped, l:format)
    call s:Send_to_r(l:cmd, 0)
    echom "Rendering " . expand('%:t') . " to " . l:format
endfunction

" Render R Markdown to HTML and open in browser
function! s:RMarkdownPreview() abort
    call s:RMarkdownRender('html_document')
    let l:output = expand('%:p:r') . '.html'

    " Platform-specific browser open (with delay for rendering)
    if has('mac')
        call system('(sleep 2 && open "' . l:output . '") &')
    elseif has('unix')
        call system('(sleep 2 && xdg-open "' . l:output . '") &')
    elseif has('win32')
        call system('start "" "' . l:output . '"')
    endif
endfunction

" Insert a new R code chunk
" Parameters:
"   above (boolean) - if true, insert above current line; otherwise below
function! s:InsertRChunk(above) abort
    let l:chunk = ['```{r}', '', '```']
    if a:above
        call append(line('.') - 1, l:chunk)
        normal! k
    else
        call append(line('.'), l:chunk)
        normal! j
    endif
    " Move into the chunk content area
    normal! j
    startinsert
endfunction

" ============================================================================
" Help in Buffer Functions
" ============================================================================

" Script-local variable to track help buffer
let s:help_bufnr = -1

" Display R help in a Vim buffer instead of terminal
" Parameters:
"   topic (string) - help topic; uses word under cursor if empty
function! s:RHelpBuffer(topic) abort
    let l:topic = empty(a:topic) ? expand('<cword>') : a:topic
    if empty(l:topic)
        call s:Error("No topic specified")
        return
    endif

    " Create temp file for help output
    let l:help_file = tempname() . '.Rhelp'
    let l:help_file_escaped = substitute(l:help_file, '\', '/', 'g')

    " R command to capture help text
    let l:cmd = printf(
        \ 'tryCatch({h <- help("%s"); ' .
        \ 'if(length(h) > 0) {' .
        \ 'writeLines(capture.output(tools:::Rd2txt(' .
        \ 'utils:::.getHelpFile(h))), "%s")} ' .
        \ 'else cat("No help found for: %s\n")}, ' .
        \ 'error = function(e) cat("Error:", e$message, "\n"))',
        \ l:topic, l:help_file_escaped, l:topic)

    call s:Send_to_r(l:cmd, 1)

    " Wait for file with timeout (3 seconds max)
    let l:tries = 30
    while !filereadable(l:help_file) && l:tries > 0
        sleep 100m
        let l:tries -= 1
    endwhile

    if !filereadable(l:help_file)
        call s:Error("Help not found: " . l:topic)
        return
    endif

    " Close existing help buffer if any
    if s:help_bufnr > 0 && bufexists(s:help_bufnr)
        execute 'bwipeout' s:help_bufnr
    endif

    " Open help buffer based on position setting
    let l:pos = g:zzvim_r_help_position
    if l:pos ==# 'vsplit'
        execute 'vertical' g:zzvim_r_help_width . 'split' fnameescape(l:help_file)
    elseif l:pos ==# 'tab'
        execute 'tabnew' fnameescape(l:help_file)
    else
        execute 'split' fnameescape(l:help_file)
    endif

    " Configure buffer as scratch
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nomodifiable
    setlocal readonly
    execute 'file R:' . l:topic

    " Save buffer number for tracking
    let s:help_bufnr = bufnr('%')

    " Buffer-local mappings for quick close
    nnoremap <buffer> q :bwipeout<CR>
    nnoremap <buffer> <Esc> :bwipeout<CR>

    " Go to top of help
    normal! gg

    " Clean up temp file
    call delete(l:help_file)
endfunction

" ============================================================================
" Terminal Graphics Setup (Kitty/iTerm2 Plot Display)
" ============================================================================
" Terminal graphics initialization is now handled by FileType autocmd above
" Only runs when opening R, Rmd, or Qmd files, not on plugin load
