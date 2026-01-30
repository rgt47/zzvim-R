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

    if a:is_docker
        let b:r_terminal_id = current_terminal
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
    " Track R activity for adaptive polling
    call s:OnRActivity()

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
        " Plot Family: <LocalLeader>p + action
        " ---------------------------------------------------------------------
        " Zoom/View
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pz :call <SID>OpenDockerPlotInPreview()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pk :call <SID>ZoomPlotPane()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pv :call <SID>PlotSplit()<CR>
        " Navigation
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pp :call <SID>PlotPrev()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pn :call <SID>PlotNext()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pg :call <SID>PlotGoto()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p/ :call <SID>PlotSearch()<CR>
        " History
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>ph :call <SID>PlotHistory()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pH :call <SID>PlotHistoryPersistent()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pG :RPlotGallery<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pt :RPlotThumbs<CR>
        " Save/Export
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>ps :call <SID>PlotSavePng()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pS :call <SID>PlotSavePdf()<CR>
        " Configuration
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pm :call <SID>PlotSetMode()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pa :call <SID>PlotSetAlign()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pd :call <SID>PlotSetSize()<CR>
        " Control
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pc :call <SID>PlotClose()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pr :call <SID>PlotRedisplay()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p? :call <SID>ShowPlotConfig()<CR>
        " Plot Window (composite: main + 2x4 grid) - uses host ImageMagick
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>pw :call <SID>PlotWindowToggleVim()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p1 :call <SID>PlotWindowSelectVim(1)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p2 :call <SID>PlotWindowSelectVim(2)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p3 :call <SID>PlotWindowSelectVim(3)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p4 :call <SID>PlotWindowSelectVim(4)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p5 :call <SID>PlotWindowSelectVim(5)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p6 :call <SID>PlotWindowSelectVim(6)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p7 :call <SID>PlotWindowSelectVim(7)<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>p8 :call <SID>PlotWindowSelectVim(8)<CR>

        " Legacy/shortcut mappings (kept for convenience)
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>[ :call <SID>OpenDockerPlotInPreview()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>] :call <SID>ZoomPlotPane()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>G :RPlotGallery<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>T :RPlotThumbs<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>< :call <SID>PlotPrev()<CR>
        autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <localleader>> :call <SID>PlotNext()<CR>

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

" Track active Docker R terminal buffer number
let s:docker_r_terminal_bufnr = -1

" Called when Docker R terminal job ends (R exits via q() or otherwise)
function! s:OnDockerRTerminalClose() abort
    " Stop the plot watcher
    call s:StopPlotWatcher()
    " Close the plot pane
    call system('kitty @ close-window --match title:zzvim-plot 2>/dev/null')
    " Clear the tracked terminal
    let s:docker_r_terminal_bufnr = -1
endfunction

function! s:CleanupPlotPaneIfRTerminal() abort
    " Check if the closed buffer was an R terminal
    let l:bufname = expand('<afile>')
    " Match various R terminal naming patterns
    if l:bufname =~? 'R-\|r-\|R$\|!/.*R\|terminal.*R'
        call s:OnDockerRTerminalClose()
    endif
endfunction

" Exit callback for term_start() - called when terminal job ends
" This is the primary mechanism for detecting R terminal close (TermClose
" event is not available in all Vim builds)
function! s:RTerminalExitCallback(job, exit_status) abort
    call s:OnDockerRTerminalClose()
endfunction

"------------------------------------------------------------------------------
" Docker Plot Watcher (Dual Resolution)
"------------------------------------------------------------------------------
" Watches .plots/.signal for changes and displays .plots/current.png via kitty
" Dual resolution: current.png (600x450) for pane, current_hires.png for zoom
" This enables inline plot display when R runs inside Docker container

let s:plot_signal_mtime = 0
let s:plots_dir_cache = ''
let s:plots_dir_cwd = ''
let s:plot_window_mode = 0

" Centralized path helper for .plots/ directory and subpaths
" Caches result to avoid repeated filesystem lookups in hot polling path
function! s:GetPlotsDir() abort
    " Cache invalidation: if cwd changed, recalculate
    let l:current_cwd = getcwd()
    if s:plots_dir_cache != '' && s:plots_dir_cwd == l:current_cwd
        return s:plots_dir_cache
    endif

    let l:project_root = s:GetProjectRoot()
    if empty(l:project_root)
        let l:project_root = l:current_cwd
    endif

    let s:plots_dir_cache = l:project_root . '/.plots'
    let s:plots_dir_cwd = l:current_cwd
    return s:plots_dir_cache
endfunction

" Get path within .plots/ directory
function! s:GetPlotsPath(subpath) abort
    return s:GetPlotsDir() . '/' . a:subpath
endfunction

" Convenience accessors using centralized helper
function! s:GetPlotFile() abort
    return s:GetPlotsPath('current.png')
endfunction

function! s:GetPlotFileHires() abort
    return s:GetPlotsPath('current_hires.png')
endfunction

function! s:GetSignalFile() abort
    return s:GetPlotsPath('.signal')
endfunction

function! s:GetConfigFile() abort
    return s:GetPlotsPath('.config.json')
endfunction

function! s:GetHistoryIndexFile() abort
    return s:GetPlotsPath('history/index.json')
endfunction

function! s:GetCompositeFile() abort
    return s:GetPlotsPath('composite.png')
endfunction

function! s:GetHistoryDir() abort
    return s:GetPlotsPath('history')
endfunction

"------------------------------------------------------------------------------
" Host-side Thumbnail Generation
"------------------------------------------------------------------------------
" Generates missing thumbnails using host ImageMagick (for Docker R workflow)

function! s:GenerateMissingThumbnails() abort
    if !executable('magick') && !executable('convert')
        return
    endif

    let l:convert_cmd = executable('magick') ? 'magick' : 'convert'
    let l:history_dir = s:GetHistoryDir()
    let l:index_file = s:GetHistoryIndexFile()

    if !filereadable(l:index_file)
        return
    endif

    let l:json_content = join(readfile(l:index_file), '')
    try
        let l:index = json_decode(l:json_content)
    catch
        return
    endtry

    if !has_key(l:index, 'plots')
        return
    endif

    let l:updated = 0
    for l:plot in l:index.plots
        let l:plot_file = l:history_dir . '/' . get(l:plot, 'file', '')
        let l:thumb_file = l:history_dir . '/' . get(l:plot, 'thumb', '')

        " Generate thumbnail if plot exists but thumb doesn't
        if filereadable(l:plot_file) && !filereadable(l:thumb_file) && l:thumb_file != l:history_dir . '/'
            let l:cmd = l:convert_cmd . ' ' . shellescape(l:plot_file) .
                \ ' -resize 200x ' . shellescape(l:thumb_file)
            call system(l:cmd)
            let l:updated = 1
        endif
    endfor

    return l:updated
endfunction

"------------------------------------------------------------------------------
" Plot Window Mode (Composite: Main + 2x4 Grid)
"------------------------------------------------------------------------------
" Generates composite on host side using ImageMagick (works with Docker R)
" Grid layout: 2 columns x 4 rows, numbered 1-4 (left col), 5-8 (right col)
" Position 1 = oldest, position 8 = newest

function! s:GenerateCompositeImage() abort
    if !executable('magick') && !executable('convert')
        echom "ImageMagick required for plot window mode"
        return ''
    endif

    let l:convert_cmd = executable('magick') ? 'magick' : 'convert'
    let l:montage_cmd = executable('magick') ? 'magick montage' : 'montage'

    let l:plots_dir = s:GetPlotsDir()
    let l:history_dir = s:GetHistoryDir()
    let l:composite_file = s:GetCompositeFile()
    let l:current_file = s:GetPlotFile()
    let l:grid_file = s:GetPlotsPath('.thumb_grid.png')

    if !filereadable(l:current_file)
        return ''
    endif

    " Read history index
    let l:index_file = s:GetHistoryIndexFile()
    if !filereadable(l:index_file)
        " No history - just copy current
        call system('cp ' . shellescape(l:current_file) . ' ' . shellescape(l:composite_file))
        return l:composite_file
    endif

    let l:json_content = join(readfile(l:index_file), '')
    try
        let l:index = json_decode(l:json_content)
    catch
        call system('cp ' . shellescape(l:current_file) . ' ' . shellescape(l:composite_file))
        return l:composite_file
    endtry

    if !has_key(l:index, 'plots') || len(l:index.plots) == 0
        call system('cp ' . shellescape(l:current_file) . ' ' . shellescape(l:composite_file))
        return l:composite_file
    endif

    " Get last 8 plots
    let l:all_plots = l:index.plots
    let l:start_idx = max([0, len(l:all_plots) - 8])
    let l:recent_8 = l:all_plots[l:start_idx:]

    " Build list of thumbnail files
    let l:thumb_files = []
    for l:p in l:recent_8
        let l:f = l:history_dir . '/' . l:p.file
        if filereadable(l:f)
            call add(l:thumb_files, l:f)
        endif
    endfor

    if len(l:thumb_files) == 0
        call system('cp ' . shellescape(l:current_file) . ' ' . shellescape(l:composite_file))
        return l:composite_file
    endif

    " Use last 8 thumbnails (1=oldest at top-left, 8=newest at bottom-right)
    " Montage fills row by row, so we need to reorder for column-first numbering:
    " Display positions:  1 5    Montage order: 1 2
    "                     2 6                   3 4
    "                     3 7                   5 6
    "                     4 8                   7 8
    " So thumb_files[0,1,2,3,4,5,6,7] -> montage[0,4,1,5,2,6,3,7]
    let l:n_thumbs = len(l:thumb_files)
    let l:inputs = []
    for l:row in range(4)
        " Left column (positions 1-4)
        if l:row < l:n_thumbs
            call add(l:inputs, l:thumb_files[l:row])
        else
            call add(l:inputs, 'null:')
        endif
        " Right column (positions 5-8)
        if l:row + 4 < l:n_thumbs
            call add(l:inputs, l:thumb_files[l:row + 4])
        else
            call add(l:inputs, 'null:')
        endif
    endfor

    " Create header image for thumbnail strip
    let l:header_file = s:GetPlotsPath('.thumb_header.png')
    let l:header_cmd = l:convert_cmd . ' -size 288x20 xc:"#333333" ' .
        \ '-font Helvetica-Bold -pointsize 11 -fill "#CCCCCC" ' .
        \ '-gravity center -annotate +0+0 "Plot History (1-' . l:n_thumbs . ')" ' .
        \ shellescape(l:header_file)
    call system(l:header_cmd)

    " Create 2x4 grid with montage (2 columns, 4 rows)
    let l:montage_args = join(map(copy(l:inputs), 'shellescape(v:val)'), ' ')
    let l:montage_full = l:montage_cmd . ' ' . l:montage_args .
        \ ' -tile 2x4 -geometry 140x105+2+2 -background "#333333" ' .
        \ shellescape(l:grid_file)
    call system(l:montage_full)

    if !filereadable(l:grid_file)
        call system('cp ' . shellescape(l:current_file) . ' ' . shellescape(l:composite_file))
        return l:composite_file
    endif

    " Add number labels to grid (1-4 left column, 5-8 right column)
    let l:label_args = ''
    let l:thumb_w = 144
    let l:thumb_h = 109
    for l:i in range(1, l:n_thumbs)
        if l:i <= 4
            " Left column: positions 1-4
            let l:col = 0
            let l:row = l:i - 1
        else
            " Right column: positions 5-8
            let l:col = 1
            let l:row = l:i - 5
        endif
        let l:x = l:col * l:thumb_w + 6
        let l:y = l:row * l:thumb_h + 18
        let l:label_args .= ' -annotate +' . l:x . '+' . l:y . " '" . l:i . "'"
    endfor

    if l:label_args != ''
        let l:label_cmd = l:convert_cmd . ' ' . shellescape(l:grid_file) .
            \ ' -font Helvetica-Bold -pointsize 16 -fill "#CC0000"' . l:label_args .
            \ ' ' . shellescape(l:grid_file)
        call system(l:label_cmd)
    endif

    " Stack header on top of grid
    let l:grid_with_header = s:GetPlotsPath('.thumb_grid_header.png')
    let l:stack_header_cmd = l:convert_cmd . ' ' . shellescape(l:header_file) . ' ' .
        \ shellescape(l:grid_file) . ' -append ' . shellescape(l:grid_with_header)
    call system(l:stack_header_cmd)
    let l:grid_file = l:grid_with_header

    " Resize main plot 20% larger
    let l:resized_file = s:GetPlotsPath('.main_resized.png')
    let l:resize_cmd = l:convert_cmd . ' ' . shellescape(l:current_file) .
        \ ' -resize 120% ' . shellescape(l:resized_file)
    call system(l:resize_cmd)

    " Join grid to right side of resized plot (+append = horizontal)
    let l:stack_cmd = l:convert_cmd . ' ' . shellescape(l:resized_file) . ' ' .
        \ shellescape(l:grid_file) . ' +append ' . shellescape(l:composite_file)
    call system(l:stack_cmd)

    if filereadable(l:composite_file)
        return l:composite_file
    endif
    return ''
endfunction

function! s:PlotWindowToggleVim() abort
    let s:plot_window_mode = !s:plot_window_mode
    if s:plot_window_mode
        echo "Plot window mode: ON (main + 8 thumbnails)"
        " Generate and display composite immediately
        let l:composite = s:GenerateCompositeImage()
        if l:composite != '' && filereadable(l:composite)
            call s:ForceDisplayDockerPlotFile(l:composite)
        endif
    else
        echo "Plot window mode: OFF"
        " Display normal plot
        let l:plot_file = s:GetPlotFile()
        if filereadable(l:plot_file)
            call s:ForceDisplayDockerPlotFile(l:plot_file)
        endif
    endif
endfunction

function! s:PlotWindowSelectVim(n) abort
    if a:n < 1 || a:n > 8
        echo "Select 1-8"
        return
    endif

    let l:index_file = s:GetHistoryIndexFile()
    if !filereadable(l:index_file)
        echo "No plot history"
        return
    endif

    let l:json_content = join(readfile(l:index_file), '')
    try
        let l:index = json_decode(l:json_content)
    catch
        echo "Error reading history"
        return
    endtry

    if !has_key(l:index, 'plots') || len(l:index.plots) == 0
        echo "No plots in history"
        return
    endif

    let l:all_plots = l:index.plots
    let l:start_idx = max([0, len(l:all_plots) - 8])
    let l:recent_8 = l:all_plots[l:start_idx:]

    if a:n > len(l:recent_8)
        echo "Only " . len(l:recent_8) . " plots available"
        return
    endif

    let l:selected = l:recent_8[a:n - 1]
    let l:history_dir = s:GetHistoryDir()
    let l:plot_file = l:history_dir . '/' . l:selected.file

    if !filereadable(l:plot_file)
        echo "Plot file not found"
        return
    endif

    " Copy selected to current.png
    let l:current_file = s:GetPlotFile()
    call system('cp ' . shellescape(l:plot_file) . ' ' . shellescape(l:current_file))

    echo "Selected plot " . a:n . ": " . l:selected.name

    " Display (composite if window mode, otherwise plain)
    if s:plot_window_mode
        let l:composite = s:GenerateCompositeImage()
        if l:composite != '' && filereadable(l:composite)
            call s:ForceDisplayDockerPlotFile(l:composite)
        endif
    else
        call s:ForceDisplayDockerPlotFile(l:current_file)
    endif

    " Touch signal file to sync state
    let l:signal_file = s:GetSignalFile()
    call writefile([localtime()], l:signal_file)
endfunction

" Helper to display a specific file (used by window mode)
" Always creates/updates pane with the specified file (doesn't just refresh)
" In window mode, watches composite.png for changes and auto-refreshes
function! s:ForceDisplayDockerPlotFile(plot_file) abort
    if !filereadable(a:plot_file)
        return
    endif

    " Close existing pane first (we need to show a different file)
    call system('kitty @ close-window --match title:' . s:pane_title . ' 2>/dev/null')
    sleep 100m

    " Create new pane with the specified file
    let l:script = '/tmp/zzvim_plot_show.sh'
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
        \ 'done',
        \ ], l:script)
    call system('chmod +x ' . l:script)
    call system('kitty @ launch --location=' . g:zzvim_r_plot_location . ' --keep-focus --title=' . s:pane_title . ' ' . l:script . ' &')
endfunction

"------------------------------------------------------------------------------
" Unified Configuration System
"------------------------------------------------------------------------------
" Single source of truth for plot settings - Vim writes, R reads

" Default plot configuration
let g:zzvim_r_plot_width_small = get(g:, 'zzvim_r_plot_width_small', 600)
let g:zzvim_r_plot_height_small = get(g:, 'zzvim_r_plot_height_small', 450)
let g:zzvim_r_plot_width_large = get(g:, 'zzvim_r_plot_width_large', 1800)
let g:zzvim_r_plot_height_large = get(g:, 'zzvim_r_plot_height_large', 1350)
let g:zzvim_r_plot_dpi = get(g:, 'zzvim_r_plot_dpi', 96)
let g:zzvim_r_plot_align = get(g:, 'zzvim_r_plot_align', 'center')
let g:zzvim_r_plot_mode = get(g:, 'zzvim_r_plot_mode', 'pane')
let g:zzvim_r_plot_location = get(g:, 'zzvim_r_plot_location', 'vsplit')
let g:zzvim_r_plot_history_limit = get(g:, 'zzvim_r_plot_history_limit', 50)

" Write current config to .plots/.config.json for R to read
function! s:WriteConfigForR() abort
    let l:plots_dir = s:GetPlotsDir()
    if !isdirectory(l:plots_dir)
        call mkdir(l:plots_dir, 'p')
    endif

    let l:config = {
        \ 'width_small': g:zzvim_r_plot_width_small,
        \ 'height_small': g:zzvim_r_plot_height_small,
        \ 'width_large': g:zzvim_r_plot_width_large,
        \ 'height_large': g:zzvim_r_plot_height_large,
        \ 'dpi': g:zzvim_r_plot_dpi,
        \ 'align': g:zzvim_r_plot_align,
        \ 'mode': g:zzvim_r_plot_mode,
        \ 'location': g:zzvim_r_plot_location,
        \ 'history_limit': g:zzvim_r_plot_history_limit
    \ }

    let l:json = json_encode(l:config)
    let l:config_file = s:GetConfigFile()
    call writefile([l:json], l:config_file)
endfunction

" Show current plot configuration
function! s:ShowPlotConfig() abort
    echo "=== zzvim-R Plot Configuration ==="
    echo "Small size:    " . g:zzvim_r_plot_width_small . "x" . g:zzvim_r_plot_height_small
    echo "Large size:    " . g:zzvim_r_plot_width_large . "x" . g:zzvim_r_plot_height_large
    echo "DPI:           " . g:zzvim_r_plot_dpi
    echo "Align:         " . g:zzvim_r_plot_align
    echo "Mode:          " . g:zzvim_r_plot_mode
    echo "Location:      " . g:zzvim_r_plot_location . " (vsplit, hsplit, tab)"
    echo "History limit: " . g:zzvim_r_plot_history_limit
    echo ""
    echo "Config file: " . s:GetConfigFile()
    echo "  Exists: " . filereadable(s:GetConfigFile())
endfunction

" Set plot size and write config
function! s:SetPlotSize(small_w, small_h, ...) abort
    let g:zzvim_r_plot_width_small = a:small_w
    let g:zzvim_r_plot_height_small = a:small_h

    " Optional large dimensions (default 3x small)
    if a:0 >= 2
        let g:zzvim_r_plot_width_large = a:1
        let g:zzvim_r_plot_height_large = a:2
    else
        let g:zzvim_r_plot_width_large = a:small_w * 3
        let g:zzvim_r_plot_height_large = a:small_h * 3
    endif

    call s:WriteConfigForR()
    echo "Plot size set: " . g:zzvim_r_plot_width_small . "x" . g:zzvim_r_plot_height_small .
        \ " (zoom: " . g:zzvim_r_plot_width_large . "x" . g:zzvim_r_plot_height_large . ")"
    echo "Run set_plot_size() in R to apply, or restart R session"
endfunction

command! -bar RPlotConfig call s:ShowPlotConfig()
command! -bar RPlotConfigWrite call s:WriteConfigForR()
command! -nargs=+ RPlotSize call s:SetPlotSize(<f-args>)

let s:plot_display_in_progress = 0
let s:pane_title = 'zzvim-plot'

" Check if plot pane already exists
function! s:PlotPaneExists() abort
    let l:result = system('kitty @ ls 2>/dev/null')
    return l:result =~# s:pane_title
endfunction

" Refresh plot in existing pane (no flicker) or create new pane
function! s:RefreshPlotInPane(plot_file) abort
    if s:PlotPaneExists()
        " Pane exists - send 'r' to trigger refresh in the running script
        " The script uses 'read -n1 -s' which accepts single char immediately
        call system('kitty @ send-text --match title:' . s:pane_title . " r 2>/dev/null")
        return 1
    endif
    return 0
endfunction

function! s:DisplayDockerPlot() abort
    " Prevent duplicate pane creation
    if s:plot_display_in_progress
        return
    endif

    " Check signal file instead of plot file (faster, more reliable)
    let l:signal_file = s:GetSignalFile()
    if filereadable(l:signal_file)
        let l:mtime = getftime(l:signal_file)
        if l:mtime <= s:plot_signal_mtime
            return
        endif
        let s:plot_signal_mtime = l:mtime
    else
        " Fallback to checking plot file directly
        let l:plot_file = s:GetPlotFile()
        if !filereadable(l:plot_file)
            return
        endif
        let l:mtime = getftime(l:plot_file)
        if l:mtime <= s:plot_signal_mtime
            return
        endif
        let s:plot_signal_mtime = l:mtime
    endif

    let l:plot_file = s:GetPlotFile()
    if !filereadable(l:plot_file)
        return
    endif

    " Generate any missing thumbnails (host-side, for Docker workflow)
    call s:GenerateMissingThumbnails()

    " Lock to prevent race conditions
    let s:plot_display_in_progress = 1

    " If window mode is ON, generate and display composite instead
    if s:plot_window_mode
        let l:composite = s:GenerateCompositeImage()
        if l:composite != '' && filereadable(l:composite)
            call s:ForceDisplayDockerPlotFile(l:composite)
        endif
        call timer_start(200, {-> execute('let s:plot_display_in_progress = 0')})
        call timer_start(300, {-> s:RefreshPlotStatus()})
        return
    endif

    " Try to refresh existing pane first (flicker-free)
    if s:RefreshPlotInPane(l:plot_file)
        " Release lock quickly since we just sent a key
        call timer_start(200, {-> execute('let s:plot_display_in_progress = 0')})
        call timer_start(300, {-> s:RefreshPlotStatus()})
        return
    endif

    " No existing pane - create new one with display script
    let l:script = '/tmp/zzvim_plot_show.sh'
    let l:size_str = g:zzvim_r_plot_width_small . 'x' . g:zzvim_r_plot_height_small
    call writefile([
        \ '#!/bin/bash',
        \ 'PLOT_FILE="' . l:plot_file . '"',
        \ 'show_plot() {',
        \ '    clear',
        \ '    kitty +kitten icat --clear --align=left "$PLOT_FILE"',
        \ '    echo ""',
        \ '    echo "Plot ' . l:size_str . ' | r=refresh | q=close"',
        \ '}',
        \ 'show_plot',
        \ 'while true; do',
        \ '    read -n1 -s key',
        \ '    case "$key" in',
        \ '        r|R) show_plot ;;',
        \ '        q|Q|"") exit 0 ;;',
        \ '    esac',
        \ 'done'
        \ ], l:script)
    call system('chmod +x ' . l:script)

    " Launch the plot pane using configured location
    let l:location = g:zzvim_r_plot_location
    if l:location == 'tab'
        call system('kitty @ launch --type=tab --keep-focus --title ' . s:pane_title . ' /tmp/zzvim_plot_show.sh 2>/dev/null')
    else
        call system('kitty @ launch --location=' . l:location . ' --keep-focus --title ' . s:pane_title . ' /tmp/zzvim_plot_show.sh 2>/dev/null')
    endif
    redraw!

    " Release lock after a delay to prevent rapid re-triggers
    call timer_start(500, {-> execute('let s:plot_display_in_progress = 0')})

    " Update plot status for statusline
    call timer_start(600, {-> s:RefreshPlotStatus()})
endfunction

function! s:OpenDockerPlotInPreview() abort
    " Open small version in Preview
    let l:plot_file = s:GetPlotFile()
    if filereadable(l:plot_file)
        call system('open ' . shellescape(l:plot_file))
        let l:size = g:zzvim_r_plot_width_small . 'x' . g:zzvim_r_plot_height_small
        echom "Opened plot (" . l:size . ") in Preview"
    else
        call s:Error("No plot file found at " . l:plot_file)
    endif
endfunction

function! s:OpenDockerPlotHiresInPreview() abort
    " Open hi-res version in Preview (preferred for zoom)
    let l:plot_hires = s:GetPlotFileHires()
    let l:plot_file = s:GetPlotFile()

    let l:size_small = g:zzvim_r_plot_width_small . 'x' . g:zzvim_r_plot_height_small
    let l:size_large = g:zzvim_r_plot_width_large . 'x' . g:zzvim_r_plot_height_large

    if filereadable(l:plot_hires)
        call system('open ' . shellescape(l:plot_hires))
        echom "Opened hi-res plot (" . l:size_large . ") in Preview"
    elseif filereadable(l:plot_file)
        call system('open ' . shellescape(l:plot_file))
        echom "Opened plot (" . l:size_small . ") in Preview (hi-res not available)"
    else
        call s:Error("No plot file found")
    endif
endfunction

" Adaptive polling configuration
let s:poll_fast = get(g:, 'zzvim_r_poll_fast', 50)    " Fast polling during active work (ms)
let s:poll_slow = get(g:, 'zzvim_r_poll_slow', 1000)  " Slow polling when idle (ms)
let s:poll_current = s:poll_fast                       " Current polling rate
let s:last_r_activity = 0   " Timestamp of last R activity
let s:idle_threshold = 30   " Seconds of inactivity before slowing down

" Track R activity for adaptive polling
function! s:OnRActivity() abort
    let s:last_r_activity = localtime()
    if s:poll_current != s:poll_fast
        let s:poll_current = s:poll_fast
        call s:RestartPlotWatcher()
    endif
endfunction

" Check if we should slow down polling
function! s:MaybeSlowDown() abort
    if s:last_r_activity == 0
        return
    endif
    if localtime() - s:last_r_activity > s:idle_threshold
        if s:poll_current != s:poll_slow
            let s:poll_current = s:poll_slow
            call s:RestartPlotWatcher()
        endif
    endif
endfunction

function! s:StartPlotWatcher() abort
    " Write config for R to read on startup (only once)
    call s:WriteConfigForR()
    call s:RestartPlotWatcherTimer()
endfunction

" Restart just the timer without re-writing config (for adaptive polling)
function! s:RestartPlotWatcherTimer() abort
    if exists('s:plot_watcher_timer')
        call timer_stop(s:plot_watcher_timer)
    endif
    let s:plot_watcher_timer = timer_start(s:poll_current, {-> s:PlotWatcherTick()}, {'repeat': -1})
    let s:last_r_activity = localtime()
endfunction

function! s:RestartPlotWatcher() abort
    " For adaptive polling, only restart timer (don't rewrite config)
    call s:RestartPlotWatcherTimer()
endfunction

function! s:PlotWatcherTick() abort
    call s:DisplayDockerPlot()
    call s:MaybeSlowDown()
endfunction

function! s:StopPlotWatcher() abort
    if exists('s:plot_watcher_timer')
        call timer_stop(s:plot_watcher_timer)
        unlet s:plot_watcher_timer
    endif
endfunction

"------------------------------------------------------------------------------
" Ex Commands
"------------------------------------------------------------------------------

" Plot commands
command! -bar RPlotShow call s:ForceDisplayDockerPlot()

function! s:ForceDisplayDockerPlot() abort
    " Stop watcher temporarily
    if exists('s:plot_watcher_timer')
        call timer_stop(s:plot_watcher_timer)
        unlet s:plot_watcher_timer
    endif

    " Display directly without mtime check
    let l:plot_file = s:GetPlotFile()
    if !filereadable(l:plot_file)
        echom "Plot file not found: " . l:plot_file
        return
    endif

    " Close existing pane if present
    call system('kitty @ close-window --match title:' . s:pane_title . ' 2>/dev/null')
    sleep 50m

    " Create the same refresh-capable script used by DisplayDockerPlot
    let l:script = '/tmp/zzvim_plot_show.sh'
    let l:size_str = g:zzvim_r_plot_width_small . 'x' . g:zzvim_r_plot_height_small
    call writefile([
        \ '#!/bin/bash',
        \ 'PLOT_FILE="' . l:plot_file . '"',
        \ 'show_plot() {',
        \ '    clear',
        \ '    kitty +kitten icat --clear --align=left "$PLOT_FILE"',
        \ '    echo ""',
        \ '    echo "Plot ' . l:size_str . ' | r=refresh | q=close"',
        \ '}',
        \ 'show_plot',
        \ 'while true; do',
        \ '    read -n1 -s key',
        \ '    case "$key" in',
        \ '        r|R) show_plot ;;',
        \ '        q|Q|"") exit 0 ;;',
        \ '    esac',
        \ 'done'
        \ ], l:script)
    call system('chmod +x ' . l:script)

    " Launch the plot pane with refresh-capable script
    let l:location = g:zzvim_r_plot_location
    if l:location == 'tab'
        call system('kitty @ launch --type=tab --keep-focus --title ' . s:pane_title . ' ' . l:script . ' 2>/dev/null')
    else
        call system('kitty @ launch --location=' . l:location . ' --keep-focus --title ' . s:pane_title . ' ' . l:script . ' 2>/dev/null')
    endif
    echom "Launching plot pane"

    " Update mtime cache (use same variable as DisplayDockerPlot)
    let s:plot_signal_mtime = getftime(l:plot_file)

    " Restart watcher using adaptive polling rate
    call s:RestartPlotWatcherTimer()
endfunction
command! -bar RPlotPreview call s:OpenDockerPlotInPreview()
command! -bar RPlotZoom call s:ZoomPlotPane()
command! -bar RPlotZoomPreview call s:OpenDockerPlotHiresInPreview()
command! -bar RPlotWatchStart call s:StartPlotWatcher()
command! -bar RPlotWatchStop call s:StopPlotWatcher()
command! -bar RPlotDebug call s:DebugPlotWatcher()
command! -bar RPlotGallery call s:OpenPlotGallery()
command! -bar RPlotReset let s:plot_signal_mtime = 0 | let s:plot_display_in_progress = 0 | echo "Plot watcher reset"
command! -bar RPlotPrev call s:PlotPrev()
command! -bar RPlotNext call s:PlotNext()

" Navigate plot history via R
function! s:PlotPrev() abort
    call s:Send_to_r('plot_prev()', 1)
endfunction

function! s:PlotNext() abort
    call s:Send_to_r('plot_next()', 1)
endfunction

function! s:PlotHistory() abort
    call s:Send_to_r('plot_history()', 1)
endfunction

function! s:PlotHistoryPersistent() abort
    call s:Send_to_r('plot_history_persistent()', 1)
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

function! s:PlotSavePng() abort
    let l:filename = input('Save PNG to: ', getcwd() . '/plot.png')
    if empty(l:filename)
        return
    endif
    call s:Send_to_r('save_plot("' . l:filename . '")', 1)
endfunction

function! s:PlotSavePdf() abort
    let l:filename = input('Save PDF to: ', getcwd() . '/plot.pdf')
    if empty(l:filename)
        return
    endif
    call s:Send_to_r('plot_to_pdf("' . l:filename . '")', 1)
endfunction

function! s:PlotClose() abort
    call s:Send_to_r('close_plot_pane()', 1)
endfunction

function! s:PlotSplit() abort
    call s:Send_to_r('plot_split()', 1)
endfunction

function! s:PlotRedisplay() abort
    call s:Send_to_r('plot_redisplay_if_resized()', 1)
endfunction

function! s:PlotSetMode() abort
    let l:mode = input('Plot mode (pane/inline/auto): ', 'pane')
    if empty(l:mode)
        return
    endif
    call s:Send_to_r('set_plot_mode("' . l:mode . '")', 1)
endfunction

function! s:PlotSetAlign() abort
    let l:align = input('Plot alignment (left/center/right): ', 'center')
    if empty(l:align)
        return
    endif
    call s:Send_to_r('set_plot_align("' . l:align . '")', 1)
endfunction

function! s:PlotSetSize() abort
    let l:sw = input('Small width: ', '600')
    let l:sh = input('Small height: ', '450')
    let l:lw = input('Large width: ', '1200')
    let l:lh = input('Large height: ', '900')
    call s:Send_to_r('set_plot_size(' . l:sw . ', ' . l:sh . ', ' . l:lw . ', ' . l:lh . ')', 1)
endfunction

function! s:PlotWindowToggle() abort
    call s:Send_to_r('plot_window_toggle()', 1)
endfunction

function! s:PlotWindowSelect(n) abort
    call s:Send_to_r('plot_window_select(' . a:n . ')', 1)
endfunction

function! s:DebugPlotWatcher() abort
    echo "=== Plot Watcher Debug ==="
    let l:signal_file = s:GetSignalFile()
    echo "Signal file: " . l:signal_file
    echo "  Exists: " . filereadable(l:signal_file)
    echo "  Mtime: " . getftime(l:signal_file)
    echo "  Cached mtime: " . s:plot_signal_mtime
    echo ""
    let l:plot_file = s:GetPlotFile()
    echo "Plot file (small): " . l:plot_file
    echo "  Exists: " . filereadable(l:plot_file)
    echo "  Mtime: " . getftime(l:plot_file)
    echo ""
    let l:plot_hires = s:GetPlotFileHires()
    echo "Plot file (hi-res): " . l:plot_hires
    echo "  Exists: " . filereadable(l:plot_hires)
    echo "  Mtime: " . getftime(l:plot_hires)
    echo ""
    echo "Plot pane exists: " . s:PlotPaneExists()
    echo "  Pane title: " . s:pane_title
    echo ""
    echo "Docker R terminal bufnr: " . s:docker_r_terminal_bufnr
    echo "Adaptive polling: " . s:poll_current . "ms (fast=" . s:poll_fast . ", slow=" . s:poll_slow . ")"
    echo "Plots dir cache: " . s:plots_dir_cache
endfunction

"------------------------------------------------------------------------------
" Plot Gallery
"------------------------------------------------------------------------------
" Opens a Vim buffer showing the plot history with navigation

function! s:OpenPlotGallery() abort
    let l:index_file = s:GetHistoryIndexFile()
    if !filereadable(l:index_file)
        call s:Error("No plot history found. Create plots with zzplot() first.")
        return
    endif

    " Read and parse JSON
    let l:json_content = join(readfile(l:index_file), '')
    try
        let l:index = json_decode(l:json_content)
    catch
        call s:Error("Failed to parse plot history: " . v:exception)
        return
    endtry

    if empty(get(l:index, 'plots', []))
        call s:Error("Plot history is empty")
        return
    endif

    " Create gallery buffer
    vnew
    setlocal buftype=nofile bufhidden=wipe noswapfile
    setlocal nonumber norelativenumber signcolumn=no
    setlocal filetype=zzvim-gallery
    file [Plot\ Gallery]

    " Build gallery content
    let l:lines = []
    call add(l:lines, '╔══════════════════════════════════════════════════════════════════╗')
    call add(l:lines, '║                         Plot Gallery                             ║')
    call add(l:lines, '║  Press number (1-9) to view, Enter on line, q to close          ║')
    call add(l:lines, '║  /pattern to search, n/N for next/prev match                    ║')
    call add(l:lines, '╚══════════════════════════════════════════════════════════════════╝')
    call add(l:lines, '')

    let l:current_idx = get(l:index, 'current_index', 0)
    let l:display_num = 1
    let l:line_to_id = {}  " Map line numbers to plot IDs
    let l:header_lines = 6  " Number of header lines before plot list

    for plot in l:index.plots
        let l:marker = (plot.id == l:current_idx) ? '▶ ' : '  '
        let l:name = get(plot, 'name', 'unnamed')
        let l:created = get(plot, 'created', '')
        let l:code = get(plot, 'code', '')
        let l:plot_id = get(plot, 'id', l:display_num)
        " Truncate code for display
        if len(l:code) > 40
            let l:code = l:code[:37] . '...'
        endif
        " Clean display without internal ID marker
        let l:line = printf('%s[%d] %-20s  %s', l:marker, l:display_num, l:name, l:created)
        call add(l:lines, l:line)
        " Store mapping from line number to plot ID
        let l:line_to_id[len(l:lines) + l:header_lines] = l:plot_id
        if !empty(l:code)
            call add(l:lines, '       ' . l:code)
        endif
        let l:display_num += 1
    endfor

    call add(l:lines, '')
    call add(l:lines, 'Total: ' . len(l:index.plots) . ' plots')

    call setline(1, l:lines)
    setlocal readonly nomodifiable

    " Store index and line mapping in buffer variables for navigation
    let b:plot_index = l:index
    let b:line_to_id = l:line_to_id

    " Key mappings for gallery
    nnoremap <buffer> <silent> q :bwipe<CR>
    nnoremap <buffer> <silent> <CR> :call <SID>GallerySelectCurrent()<CR>
    nnoremap <buffer> <silent> <Esc> :bwipe<CR>
    for i in range(1, 9)
        execute 'nnoremap <buffer> <silent> ' . i . ' :call <SID>GallerySelect(' . i . ')<CR>'
    endfor
endfunction

function! s:GallerySelect(display_num) abort
    if !exists('b:plot_index')
        return
    endif
    if a:display_num > len(b:plot_index.plots)
        echom "Plot " . a:display_num . " not in history"
        return
    endif
    " Get the actual plot ID (not display number) for correct selection
    let l:plot = b:plot_index.plots[a:display_num - 1]
    let l:plot_id = get(l:plot, 'id', a:display_num)
    let l:plot_name = get(l:plot, 'name', 'unnamed')
    " Send command to R using the actual plot ID
    call s:Send_to_r('plot_goto(' . l:plot_id . ')', 1)
    echom "Displaying: " . l:plot_name . " (id:" . l:plot_id . ")"
endfunction

function! s:GallerySelectCurrent() abort
    " First try line-to-ID mapping (preferred method)
    if exists('b:line_to_id')
        let l:line_num = line('.')
        if has_key(b:line_to_id, l:line_num)
            let l:plot_id = b:line_to_id[l:line_num]
            call s:Send_to_r('plot_goto(' . l:plot_id . ')', 1)
            echom "Displaying plot id:" . l:plot_id
            return
        endif
    endif
    " Fallback to display number from [N] marker
    let l:match = matchstr(l:line, '\[\zs\d\+\ze\]')
    if !empty(l:match)
        call s:GallerySelect(str2nr(l:match))
    endif
endfunction

"------------------------------------------------------------------------------
" Thumbnail Gallery (Kitty pane with visual thumbnails)
"------------------------------------------------------------------------------
" Opens a Kitty pane showing thumbnail images of plot history
" Creates a montage image with ImageMagick and displays it

let s:thumb_pane_title = 'zzvim-thumbs'

function! s:OpenThumbnailGallery() abort
    let l:index_file = s:GetHistoryIndexFile()
    if !filereadable(l:index_file)
        call s:Error("No plot history found. Create plots with zzplot() first.")
        return
    endif

    " Check for ImageMagick montage command
    if system('which montage') == ''
        call s:Error("ImageMagick 'montage' command required for thumbnail gallery")
        return
    endif

    " Read and parse JSON
    let l:json_content = join(readfile(l:index_file), '')
    try
        let l:index = json_decode(l:json_content)
    catch
        call s:Error("Failed to parse plot history: " . v:exception)
        return
    endtry

    let l:plots = get(l:index, 'plots', [])
    if empty(l:plots)
        call s:Error("No plots in history")
        return
    endif

    " Get history directory
    let l:history_dir = s:GetPlotsPath('history')

    " Build list of thumbnail files (most recent first, limit to 9)
    let l:thumbs = []
    let l:count = 0
    for l:i in range(len(l:plots) - 1, 0, -1)
        let l:plot = l:plots[l:i]
        let l:thumb_file = l:history_dir . '/' . get(l:plot, 'thumb', '')
        let l:plot_file = l:history_dir . '/' . get(l:plot, 'file', '')
        if filereadable(l:thumb_file) && filereadable(l:plot_file)
            call add(l:thumbs, {
                \ 'thumb': l:thumb_file,
                \ 'plot': l:plot_file,
                \ 'name': get(l:plot, 'name', 'plot'),
                \ 'id': get(l:plot, 'id', 0)
                \ })
            let l:count += 1
            if l:count >= 9
                break
            endif
        endif
    endfor

    if empty(l:thumbs)
        call s:Error("No thumbnails found. Thumbnails require ImageMagick 'convert' command.")
        return
    endif

    " Close existing thumbnail pane if present
    call system('kitty @ close-window --match title:' . s:thumb_pane_title . ' 2>/dev/null')
    sleep 50m

    " Store thumbs for selection callback
    let s:thumb_gallery_items = l:thumbs

    " Create montage image with labels
    let l:montage_file = '/tmp/zzvim_montage.png'
    let l:montage_cmd = 'montage -label ""'
    let l:num = 1
    for l:thumb in l:thumbs
        " Add label with number and name
        let l:label = l:num . ': ' . l:thumb.name
        let l:montage_cmd .= ' -label ' . shellescape(l:label) . ' ' . shellescape(l:thumb.thumb)
        let l:num += 1
    endfor
    " 3 columns, with spacing and border
    let l:montage_cmd .= ' -tile 3x -geometry 200x150+5+5 -background "#1e1e2e" -fill white ' . shellescape(l:montage_file)
    call system(l:montage_cmd)

    " Create selection file path
    let l:selection_file = '/tmp/zzvim_thumb_selection'
    call delete(l:selection_file)

    " Create shell script to display montage and handle input
    let l:script = '/tmp/zzvim_thumbs.sh'
    let l:script_lines = [
        \ '#!/bin/bash',
        \ 'SELECTION_FILE="' . l:selection_file . '"',
        \ 'clear',
        \ 'kitty +kitten icat --align=left ' . shellescape(l:montage_file),
        \ 'echo ""',
        \ 'echo "Press 1-' . len(l:thumbs) . ' to select plot, q to close"',
        \ 'while true; do',
        \ '    read -n1 -s key',
        \ '    case "$key" in'
        \ ]

    " Add case for each thumbnail number - write display number to file
    let l:num = 1
    for l:thumb in l:thumbs
        call add(l:script_lines, '        ' . l:num . ') echo "' . l:num . '" > "$SELECTION_FILE"; exit 0 ;;')
        let l:num += 1
    endfor

    call add(l:script_lines, '        q|Q) exit 0 ;;')
    call add(l:script_lines, '    esac')
    call add(l:script_lines, 'done')

    call writefile(l:script_lines, l:script)
    call system('chmod +x ' . l:script)

    " Launch the thumbnail pane
    let l:cmd = 'kitty @ launch --location=vsplit --keep-focus --title ' . s:thumb_pane_title . ' ' . l:script
    call system(l:cmd)

    " Start a timer to check for selection
    let s:thumb_selection_file = l:selection_file
    let s:thumb_selection_timer = timer_start(200, function('s:CheckThumbSelection'), {'repeat': -1})
endfunction

" Check if user made a selection in the thumbnail gallery
function! s:CheckThumbSelection(timer) abort
    " Check if thumbnail pane still exists
    let l:result = system('kitty @ ls 2>/dev/null')
    if l:result !~# s:thumb_pane_title
        " Pane closed - stop timer and check for selection
        call timer_stop(a:timer)

        if filereadable(s:thumb_selection_file)
            let l:selection = str2nr(trim(join(readfile(s:thumb_selection_file), '')))
            call delete(s:thumb_selection_file)
            if l:selection > 0 && l:selection <= len(s:thumb_gallery_items)
                " Get the plot file from our stored mapping (1-indexed)
                let l:item = s:thumb_gallery_items[l:selection - 1]
                let l:plot_file = l:item.plot

                " Copy to current.png for display
                let l:current_file = s:GetPlotFile()
                call system('cp ' . shellescape(l:plot_file) . ' ' . shellescape(l:current_file))

                " Update signal file to trigger watcher
                let l:signal_file = s:GetSignalFile()
                call writefile([string(localtime())], l:signal_file)

                " Reset cached mtime so watcher will detect the change
                let s:plot_signal_mtime = 0

                echom "Displaying: " . l:item.name
            endif
        endif
    endif
endfunction

command! -bar RPlotThumbs call s:OpenThumbnailGallery()

"------------------------------------------------------------------------------
" Statusline Integration
"------------------------------------------------------------------------------
" Provides plot status for users to add to their statusline
" Uses mtime caching to avoid re-reading JSON on every statusline update

let s:plot_status_index = 0
let s:plot_status_total = 0
let s:plot_status_mtime = 0

" Public function for statusline - returns [Plot N/M] or empty string
function! ZzvimRPlotStatus() abort
    if s:plot_status_total == 0
        return ''
    endif
    return printf('[Plot %d/%d]', s:plot_status_index, s:plot_status_total)
endfunction

" Update plot status from history index file (with mtime caching)
function! s:UpdatePlotStatus() abort
    let l:index_file = s:GetHistoryIndexFile()
    if !filereadable(l:index_file)
        let s:plot_status_index = 0
        let s:plot_status_total = 0
        let s:plot_status_mtime = 0
        return
    endif

    " Check if file has changed since last read (mtime caching)
    let l:mtime = getftime(l:index_file)
    if l:mtime == s:plot_status_mtime
        " No change, skip re-reading
        return
    endif
    let s:plot_status_mtime = l:mtime

    try
        let l:json_content = join(readfile(l:index_file), '')
        let l:index = json_decode(l:json_content)
        let s:plot_status_total = len(get(l:index, 'plots', []))
        let s:plot_status_index = get(l:index, 'current_index', 0)
    catch
        let s:plot_status_index = 0
        let s:plot_status_total = 0
    endtry
endfunction

" Call this after displaying a plot to update status
function! s:RefreshPlotStatus() abort
    call s:UpdatePlotStatus()
    redrawstatus
endfunction

function! s:ZoomPlotPane() abort
    " Open hi-res version with 2x4 thumbnail grid in interactive Kitty window
    " Press 1-8 to switch plots, q to close

    let l:plot_hires = s:GetPlotFileHires()
    let l:plot_file = s:GetPlotFile()

    " Prefer hi-res, fall back to standard
    if filereadable(l:plot_hires)
        let l:main_file = l:plot_hires
    elseif filereadable(l:plot_file)
        let l:main_file = l:plot_file
    else
        echom "No plot file found"
        return
    endif

    " Generate zoom composite with 2x4 thumbnail grid
    let l:zoom_composite = s:GenerateZoomComposite(l:main_file)
    if l:zoom_composite == ''
        " Fallback to simple display if composite fails
        let l:cmd = 'kitty @ launch --type=os-window -- sh -c ' .
                  \ shellescape('kitty +kitten icat --hold ' . shellescape(l:main_file))
        call system(l:cmd)
        return
    endif

    " Create interactive script for zoom window
    let l:script = '/tmp/zzvim_zoom.sh'
    let l:plots_dir = s:GetPlotsDir()
    let l:history_dir = s:GetHistoryDir()

    call writefile([
        \ '#!/bin/bash',
        \ 'PLOTS_DIR="' . l:plots_dir . '"',
        \ 'HISTORY_DIR="' . l:history_dir . '"',
        \ 'CURRENT_FILE="' . l:zoom_composite . '"',
        \ '',
        \ 'show_plot() {',
        \ '    clear',
        \ '    kitty +kitten icat --clear --align=left "$CURRENT_FILE"',
        \ '    echo ""',
        \ '    echo "Zoom mode | 1-8=select plot | q=close"',
        \ '}',
        \ '',
        \ 'regenerate_composite() {',
        \ '    # Called from vim via kitty send-text',
        \ '    CURRENT_FILE="' . l:zoom_composite . '"',
        \ '    show_plot',
        \ '}',
        \ '',
        \ 'show_plot',
        \ 'while true; do',
        \ '    read -n1 -s key',
        \ '    case "$key" in',
        \ '        [1-8])',
        \ '            # Signal vim to select plot and regenerate',
        \ '            echo "$key" > /tmp/zzvim_zoom_select',
        \ '            # Wait for vim to regenerate composite',
        \ '            for i in 1 2 3 4 5; do',
        \ '                sleep 0.05',
        \ '                if [ "' . l:zoom_composite . '" -nt /tmp/zzvim_zoom_select ]; then break; fi',
        \ '            done',
        \ '            show_plot',
        \ '            ;;',
        \ '        r|R) show_plot ;;',
        \ '        q|Q) exit 0 ;;',
        \ '    esac',
        \ 'done',
        \ ], l:script)
    call system('chmod +x ' . l:script)

    " Launch zoom window
    call system('kitty @ launch --type=os-window --title=zzvim-zoom ' . l:script . ' &')

    " Start watching for selection
    let s:zoom_selection_file = '/tmp/zzvim_zoom_select'
    call delete(s:zoom_selection_file)
    let s:zoom_selection_timer = timer_start(30, function('s:CheckZoomSelection'), {'repeat': -1})

    echom "Zoom mode: 1-8 to select, q to close"
endfunction

" Generate zoom composite with 2x4 grid (8 thumbnails)
" Grid layout: 2 columns x 4 rows, numbered 1-4 (left col), 5-8 (right col)
" Position 1 = oldest, position 8 = newest
function! s:GenerateZoomComposite(main_file) abort
    if !executable('magick') && !executable('convert')
        return ''
    endif

    let l:convert_cmd = executable('magick') ? 'magick' : 'convert'
    let l:montage_cmd = executable('magick') ? 'magick montage' : 'montage'

    let l:plots_dir = s:GetPlotsDir()
    let l:history_dir = s:GetHistoryDir()
    let l:zoom_composite = s:GetPlotsPath('zoom_composite.png')
    let l:zoom_grid = s:GetPlotsPath('.zoom_grid.png')
    let l:index_file = s:GetHistoryIndexFile()

    if !filereadable(l:index_file)
        return ''
    endif

    let l:json_content = join(readfile(l:index_file), '')
    try
        let l:index = json_decode(l:json_content)
    catch
        return ''
    endtry

    if !has_key(l:index, 'plots') || len(l:index.plots) == 0
        return ''
    endif

    " Get last 8 plots for zoom
    let l:all_plots = l:index.plots
    let l:start_idx = max([0, len(l:all_plots) - 8])
    let l:recent_8 = l:all_plots[l:start_idx:]

    let l:thumb_files = []
    for l:p in l:recent_8
        let l:f = l:history_dir . '/' . l:p.file
        if filereadable(l:f)
            call add(l:thumb_files, l:f)
        endif
    endfor

    if len(l:thumb_files) == 0
        return ''
    endif

    " Reorder for 2x4 grid with column-first numbering:
    " Display positions:  1 5    Montage order: 1 2
    "                     2 6                   3 4
    "                     3 7                   5 6
    "                     4 8                   7 8
    let l:n_thumbs = len(l:thumb_files)
    let l:inputs = []
    for l:row in range(4)
        " Left column (positions 1-4)
        if l:row < l:n_thumbs
            call add(l:inputs, l:thumb_files[l:row])
        else
            call add(l:inputs, 'null:')
        endif
        " Right column (positions 5-8)
        if l:row + 4 < l:n_thumbs
            call add(l:inputs, l:thumb_files[l:row + 4])
        else
            call add(l:inputs, 'null:')
        endif
    endfor

    " Create header for zoom grid
    let l:header_file = s:GetPlotsPath('.zoom_header.png')
    let l:header_cmd = l:convert_cmd . ' -size 328x22 xc:"#333333" ' .
        \ '-font Helvetica-Bold -pointsize 12 -fill "#CCCCCC" ' .
        \ '-gravity center -annotate +0+0 "Plot History (1-' . l:n_thumbs . ')" ' .
        \ shellescape(l:header_file)
    call system(l:header_cmd)

    " Create 2x4 grid (2 columns, 4 rows)
    let l:montage_args = join(map(copy(l:inputs), 'shellescape(v:val)'), ' ')
    let l:montage_full = l:montage_cmd . ' ' . l:montage_args .
        \ ' -tile 2x4 -geometry 160x120+2+2 -background "#333333" ' .
        \ shellescape(l:zoom_grid)
    call system(l:montage_full)

    if !filereadable(l:zoom_grid)
        return ''
    endif

    " Add number labels (1-4 left column, 5-8 right column)
    let l:label_args = ''
    let l:thumb_w = 164
    let l:thumb_h = 124
    for l:i in range(1, l:n_thumbs)
        if l:i <= 4
            " Left column: positions 1-4
            let l:col = 0
            let l:row = l:i - 1
        else
            " Right column: positions 5-8
            let l:col = 1
            let l:row = l:i - 5
        endif
        let l:x = l:col * l:thumb_w + 6
        let l:y = l:row * l:thumb_h + 18
        let l:label_args .= ' -annotate +' . l:x . '+' . l:y . " '" . l:i . "'"
    endfor

    if l:label_args != ''
        let l:label_cmd = l:convert_cmd . ' ' . shellescape(l:zoom_grid) .
            \ ' -font Helvetica-Bold -pointsize 16 -fill "#CC0000"' . l:label_args .
            \ ' ' . shellescape(l:zoom_grid)
        call system(l:label_cmd)
    endif

    " Stack header on grid
    let l:grid_with_header = s:GetPlotsPath('.zoom_grid_header.png')
    let l:stack_header = l:convert_cmd . ' ' . shellescape(l:header_file) . ' ' .
        \ shellescape(l:zoom_grid) . ' -append ' . shellescape(l:grid_with_header)
    call system(l:stack_header)

    " Join main plot + grid horizontally
    let l:stack_cmd = l:convert_cmd . ' ' . shellescape(a:main_file) . ' ' .
        \ shellescape(l:grid_with_header) . ' +append ' . shellescape(l:zoom_composite)
    call system(l:stack_cmd)

    if filereadable(l:zoom_composite)
        return l:zoom_composite
    endif
    return ''
endfunction

function! s:CheckZoomSelection(timer) abort
    " Check if zoom window still exists
    let l:result = system('kitty @ ls 2>/dev/null')
    if l:result !~# 'zzvim-zoom'
        call timer_stop(a:timer)
        if exists('s:zoom_selection_file')
            call delete(s:zoom_selection_file)
        endif
        return
    endif

    " Check for selection
    if exists('s:zoom_selection_file') && filereadable(s:zoom_selection_file)
        let l:selection = str2nr(trim(join(readfile(s:zoom_selection_file), '')))
        call delete(s:zoom_selection_file)

        if l:selection >= 1 && l:selection <= 8
            " Select the plot and regenerate composite
            call s:ZoomSelectPlot(l:selection)
        endif
    endif
endfunction

function! s:ZoomSelectPlot(n) abort
    let l:index_file = s:GetHistoryIndexFile()
    if !filereadable(l:index_file)
        return
    endif

    let l:json_content = join(readfile(l:index_file), '')
    try
        let l:index = json_decode(l:json_content)
    catch
        return
    endtry

    if !has_key(l:index, 'plots') || len(l:index.plots) == 0
        return
    endif

    let l:history_dir = s:GetHistoryDir()
    let l:all_plots = l:index.plots
    let l:start_idx = max([0, len(l:all_plots) - 8])
    let l:recent_8 = l:all_plots[l:start_idx:]

    " Filter to only plots with existing files (must match GenerateZoomComposite)
    let l:valid_plots = []
    for l:p in l:recent_8
        let l:f = l:history_dir . '/' . l:p.file
        if filereadable(l:f)
            call add(l:valid_plots, l:p)
        endif
    endfor

    if a:n > len(l:valid_plots)
        return
    endif

    let l:selected = l:valid_plots[a:n - 1]

    " Try hi-res first, fall back to regular
    let l:hires_file = l:history_dir . '/' . substitute(l:selected.file, '\.png$', '_hires.png', '')
    let l:plot_file = l:history_dir . '/' . l:selected.file

    if filereadable(l:hires_file)
        let l:main_file = l:hires_file
    elseif filereadable(l:plot_file)
        let l:main_file = l:plot_file
    else
        return
    endif

    " Copy to current files
    let l:current_file = s:GetPlotFile()
    let l:current_hires = s:GetPlotFileHires()
    call system('cp ' . shellescape(l:plot_file) . ' ' . shellescape(l:current_file))
    if filereadable(l:hires_file)
        call system('cp ' . shellescape(l:hires_file) . ' ' . shellescape(l:current_hires))
    endif

    " Regenerate zoom composite
    call s:GenerateZoomComposite(l:main_file)
endfunction

" Core Operations
command! -bar ROpenTerminal call s:OpenRTerminal()
command! -bar RDockerTerminal call s:OpenDockerRTerminal()
command! -bar RDockerTerminalForce call s:OpenDockerRTerminal(s:GetTerminalName(), 1)
command! -bar RTerminalLocal call s:OpenLocalRTerminal()
command! -bar RTerminalVanilla call s:OpenLocalRTerminalVanilla()
command! -bar RSendLine call s:SendToR('line')
command! -bar RSendSelection call s:SendToR('selection')
command! -bar RSendFunction call s:SendToR('function')
command! -bar RSendSmart call s:SendToR('')
command! -bar RSendWithComments call s:SendToRWithComments('')
command! -bar RAddPipe call s:AddPipeAndNewLine()

" Chunk Navigation and Execution
command! -bar RNextChunk call s:MoveNextChunk()
command! -bar RPrevChunk call s:MovePrevChunk()
command! -bar RSendChunk call s:SubmitChunk()
command! -bar RSendPreviousChunks call s:SendToR('previous_chunks')

" R Markdown Rendering Commands
command! -bar -nargs=? RMarkdownRender call s:RMarkdownRender(<q-args>)
command! -bar RMarkdownPreview call s:RMarkdownPreview()
command! -bar RChunkInsert call s:InsertRChunk(0)
command! -bar RChunkInsertAbove call s:InsertRChunk(1)

" Help in Buffer Command (displays help in Vim buffer, not terminal)
command! -bar -nargs=? RHelpBuffer call s:RHelpBuffer(<q-args>)

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

" Terminal Association Commands
command! -bar RShowTerminal call s:RShowTerminalCommand()
command! -bar RListTerminals call s:RListTerminalsCommand()
command! -bar RSwitchToTerminal call s:RSwitchToTerminalCommand()
command! -bar -nargs=? ROpenSplit call s:ROpenSplitCommand(<q-args>)

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
    
    " Go to first HUD tab
    1tabnext
    
    echo "HUD Dashboard: 5 tabs created. Use gt/gT to navigate, <LocalLeader>0 to refresh"
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
