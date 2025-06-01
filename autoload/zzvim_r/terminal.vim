" ==============================================================================
" terminal.vim - Terminal management for zzvim-R plugin
" ==============================================================================
" File:         autoload/zzvim_r/terminal.vim
" Maintainer:   RG Thomas <rgthomas@ucsd.edu>
" Version:      2.3
" License:      GPL-3.0
" Description:  Terminal management functionality for the zzvim-R plugin
"
" OVERVIEW:
" This module handles all terminal-related operations for the zzvim-R plugin,
" including creating, checking, sending commands to, and managing the R terminal.
" The module provides a unified interface through the process() function and
" specialized handlers for each terminal operation.
"
" FUNCTIONS:
" - cleanup()    : Cleans up terminal variables
" - check()      : Checks if the terminal is active and valid
" - create()     : Creates a new R terminal
" - send()       : Sends commands to the R terminal
" - control()    : Sends control keys to the terminal
" - info()       : Retrieves terminal information
" - process()    : Main dispatcher for terminal operations
"
" VARIABLES:
" - t:zzvim_r_terminal_id: Buffer ID of the R terminal
" - t:zzvim_r_job_id:      Job ID of the R process
"
" DEPENDENCIES:
" - zzvim_r#config  : Configuration management
" - zzvim_r#engine  : Engine for logging and messaging
" ==============================================================================

" ==============================================================================
" zzvim_r#terminal#cleanup({options}) - Clean up terminal variables
" ==============================================================================
" PURPOSE: Removes terminal-related tab variables when the terminal is closed
" PARAMETERS:
"   options - Dict: Currently unused
" RETURNS: v:false (to indicate terminal is not active)
" SIDE EFFECTS: Unsets t:zzvim_r_terminal_id and t:zzvim_r_job_id if they exist
" ==============================================================================
function! zzvim_r#terminal#cleanup(...) abort
    " Clean up tab variables
    for l:var in ['t:zzvim_r_terminal_id', 't:zzvim_r_job_id']
        if exists(l:var) | execute 'unlet ' . l:var | endif
    endfor

    " Optionally clean up terminal buffers if requested
    if get(a:, 1, {}) != {} && get(a:000, 0, {}) == {'kill_buffers': v:true}
        let l:cleaned = 0
        " Find and kill all terminal buffers
        for l:buf in range(1, bufnr('$'))
            if bufexists(l:buf) && getbufvar(l:buf, '&buftype') ==# 'terminal'
                try
                    " Try to kill job first
                    if !has('nvim') && exists('*term_getjob')
                        let l:job = term_getjob(l:buf)
                        if l:job != v:null
                            call job_stop(l:job, 'kill')
                            sleep 100m
                        endif
                    endif

                    " Try to kill Neovim job
                    if has('nvim')
                        let l:chan = getbufvar(l:buf, 'terminal_job_id', -1)
                        if l:chan != -1
                            call jobstop(l:chan)
                            sleep 100m
                        endif
                    endif

                    " Force delete buffer
                    execute 'silent! bdelete! ' . l:buf
                    let l:cleaned += 1
                catch
                    " Just log errors
                    call zzvim_r#engine#log('Error cleaning terminal buffer ' . l:buf . ': ' . v:exception, 3)
                endtry
            endif
        endfor
        call zzvim_r#engine#log('Cleaned ' . l:cleaned . ' terminal buffers', 3)
    endif

    call zzvim_r#engine#log('Terminal variables cleaned', 4)
    return v:false
endfunction

" ==============================================================================
" zzvim_r#terminal#check({options}) - Check terminal status
                    endif
                endif

                " Try to kill jobs in Neovim
                if has('nvim')
                    let l:chan = getbufvar(l:buf, 'terminal_job_id', -1)
                    if l:chan != -1
                        call jobstop(l:chan)
                        sleep 100m
                    endif
                endif

                " Force delete the buffer with !
                execute 'silent! bdelete! ' . l:buf
                let l:cleaned += 1
            catch
                " Just log errors and continue
                call zzvim_r#engine#log('Error cleaning terminal buffer ' . l:buf . ': ' . v:exception, 3)
            endtry
        endif
    endfor

    call zzvim_r#engine#log('Cleaned ' . l:cleaned . ' terminal buffers', 3)
    return l:cleaned
endfunction

" ==============================================================================
" zzvim_r#terminal#check({options}) - Check terminal status
" ==============================================================================
" PURPOSE: Validates that the R terminal exists and is in a valid state
" PARAMETERS:
"   options - Dict: Currently unused
" RETURNS: 
"   v:true if terminal is active and valid
"   v:false if terminal doesn't exist or is invalid (also cleans up in this case)
" LOGIC:
"   1. Checks if terminal variables exist
"   2. Validates buffer exists and is a terminal
"   3. Verifies job is still running
" ==============================================================================
function! zzvim_r#terminal#check(...) abort
    " Step 1: Check if terminal variables exist
    if !exists('t:zzvim_r_terminal_id') || !exists('t:zzvim_r_job_id')
        call zzvim_r#engine#log('No terminal variables', 4)
        return v:false
    endif
    
    " Step 2: Validate terminal buffer
    for [l:check, l:msg] in [
        \ [bufexists(t:zzvim_r_terminal_id), 'Buffer missing'],
        \ [getbufvar(t:zzvim_r_terminal_id, '&buftype') ==# 'terminal', 'Not terminal']
    \ ]
        if !l:check
            call zzvim_r#engine#log(l:msg, 3)
            return zzvim_r#terminal#cleanup({})
        endif
    endfor
    
    " Step 3: Check job status using Vim or Neovim specific methods
    try
        if has('nvim')
            " Neovim approach
            let l:chan = getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id', -1)
            if l:chan == -1 || !jobwait([l:chan], 0)[0] == -1
                return zzvim_r#terminal#cleanup({})
            endif
            return v:true
        else
            " Vim approach
            return job_status(t:zzvim_r_job_id) ==# 'run' ? v:true : zzvim_r#terminal#cleanup({})
        endif
    catch
        return zzvim_r#terminal#cleanup({})
    endtry
endfunction

" ==============================================================================
" zzvim_r#terminal#create({options}) - Create a new R terminal
" ==============================================================================
" PURPOSE: Creates a new R terminal in a vertical split
" PARAMETERS:
"   options - Dict: Currently unused
" RETURNS:
"   v:true if terminal was created successfully
"   v:false if creation failed or R executable not found
" SIDE EFFECTS:
"   - Creates a new terminal window with R
"   - Sets terminal buffer settings
"   - Stores terminal info in tab variables
"   - Returns focus to the original window
" ==============================================================================
function! zzvim_r#terminal#create(...) abort
    let l:config = zzvim_r#config#get_all()

    " Check if R is available
    if !zzvim_r#engine#validate('r_executable', '')
        return zzvim_r#engine#msg('R executable not found', 'error')
    endif

    " Check if terminal already exists - if so, use it
    if zzvim_r#terminal#check({})
        return zzvim_r#engine#msg('R terminal already active', 'info')
    endif

    " If we reach here, we need to create a new terminal
    " First, clean up any stale terminal variables
    call zzvim_r#terminal#cleanup({})

    " Save current window/buffer context
    let l:context = [winnr(), bufnr('%')]

    " Find and kill all terminal buffers with running jobs
    for l:buf in range(1, bufnr('$'))
        if bufexists(l:buf) && getbufvar(l:buf, '&buftype') ==# 'terminal'
            try
                execute 'bdelete! ' . l:buf
            catch
                " Ignore errors
            endtry
        endif
    endfor

    try
        " Create a new window for the terminal
        execute 'vertical new'

        " Create terminal with job in this window
        if has('nvim')
            " Neovim approach
            call termopen(l:config.command)
        else
            " Vim approach - using ++curwin to use current window
            execute 'terminal ++curwin ++kill=kill ' . l:config.command
        endif

        " Apply settings
        execute 'vertical resize ' . l:config.width
        for l:setting in l:config.terminal_settings | execute 'setlocal ' . l:setting | endfor
        silent! file [R-Terminal]

        " Store terminal references (differently for Vim and Neovim)
        let t:zzvim_r_terminal_id = bufnr('%')
        if has('nvim')
            " In Neovim, job ID is stored in buffer variable
            let t:zzvim_r_job_id = b:terminal_job_id
        else
            " In Vim, get the job from the terminal
            let t:zzvim_r_job_id = term_getjob(bufnr('%'))
        endif

        " Return to original window
        execute printf('%dwincmd w | if bufnr("%%") != %d | buffer %d | endif', l:context[0], l:context[1], l:context[1])
        call zzvim_r#engine#msg('R terminal opened successfully', 'info')
        return v:true
    catch
        call zzvim_r#terminal#cleanup({})
        return zzvim_r#engine#msg('Failed to create terminal: ' . v:exception, 'error')
    endtry
endfunction

" ==============================================================================
" zzvim_r#terminal#send(options) - Send commands to R terminal
" ==============================================================================
" PURPOSE: Sends commands or code to the R terminal
" PARAMETERS:
"   options - Dict: {
"     content: String or List - Command(s) to send
"     desc: String - Description of the content (for messages)
"   }
" RETURNS:
"   v:true if send was successful
"   v:false if terminal couldn't be created or send failed
" LOGIC:
"   - Handles both single-line commands (string) and multi-line code (list)
"   - For multi-line code, creates a temporary file and sources it
" ==============================================================================
function! zzvim_r#terminal#send(options) abort
    " Get content before terminal creation to avoid adding it to history
    let l:content = get(a:options, 'content', '')
    let l:desc = get(a:options, 'desc', 'command')

    " If content is empty, nothing to send
    if empty(l:content)
        return v:true
    endif

    " Check terminal and create if needed
    if !zzvim_r#terminal#check({})
        call zzvim_r#engine#msg('Creating R terminal for ' . l:desc . '...', 'info')
        let l:created = zzvim_r#terminal#create({})
        if !l:created
            call zzvim_r#engine#msg('Failed to create R terminal for sending command', 'error')
            return v:false
        endif
        " Allow time for terminal to initialize
        sleep 500m
    endif
    
    " Handle string content (single line)
    if type(l:content) == v:t_string
        let l:cmd = trim(l:content)
        if empty(l:cmd) | return v:true | endif
        try
            " Send keys differently depending on Vim or Neovim
            if has('nvim')
                " Neovim approach
                let l:chan = bufnr('%') == t:zzvim_r_terminal_id ?
                           \ b:terminal_job_id : getbufvar(t:zzvim_r_terminal_id, 'terminal_job_id')
                call chansend(l:chan, l:cmd . "\n")
            else
                " Vim approach
                call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
            endif

            call zzvim_r#engine#log('Sent: ' . l:cmd, 4)
            return v:true
        catch
            return zzvim_r#engine#msg('Send failed: ' . v:exception, 'error')
        endtry
    
    " Handle list content (multi-line code)
    elseif type(l:content) == v:t_list
        " Skip if no executable content
        if empty(filter(copy(l:content), '!empty(trim(v:val))'))
            return zzvim_r#engine#msg(l:desc . ' has no executable code', 'warn')
        endif
        
        try
            " Create temporary file and source it
            let l:temp = tempname() . '.R'
            call writefile(l:content, l:temp)
            let l:success = zzvim_r#terminal#send({'content': printf("source('%s', echo=TRUE)", l:temp), 'desc': 'source'})
            if l:success | call zzvim_r#engine#msg('Sourced ' . l:desc, 'info') | endif
            return l:success
        catch
            return zzvim_r#engine#msg('Source failed: ' . v:exception, 'error')
        endtry
    endif
    
    return v:false
endfunction

" ==============================================================================
" zzvim_r#terminal#control(options) - Send control keys to terminal
" ==============================================================================
" PURPOSE: Sends special control characters to the R terminal
" PARAMETERS:
"   options - Dict: {
"     key: String - Control key to send (e.g., "\<C-c>")
"   }
" RETURNS:
"   v:true if control key was sent successfully
"   v:false if terminal not active or send failed
" ==============================================================================
function! zzvim_r#terminal#control(options) abort
    if !zzvim_r#terminal#check({}) | return zzvim_r#engine#msg('No terminal active', 'error') | endif
    try
        call term_sendkeys(t:zzvim_r_terminal_id, get(a:options, 'key', ''))
        return zzvim_r#engine#msg('Sent control key', 'info')
    catch
        return zzvim_r#engine#msg('Control key failed', 'error')
    endtry
endfunction

" ==============================================================================
" zzvim_r#terminal#info({options}) - Get terminal information
" ==============================================================================
" PURPOSE: Retrieves information about the current R terminal
" PARAMETERS:
"   options - Dict: Currently unused
" RETURNS:
"   Dict with terminal information:
"     - id: Buffer ID of the terminal
"     - active: Boolean indicating if terminal is active
"   Empty dict if no terminal exists
" ==============================================================================
function! zzvim_r#terminal#info(...) abort
    return exists('t:zzvim_r_terminal_id') ? 
         \ {'id': t:zzvim_r_terminal_id, 'active': zzvim_r#terminal#check({})} : {}
endfunction

" ==============================================================================
" zzvim_r#terminal#process(action, options) - Main terminal function dispatcher
" ==============================================================================
" PURPOSE: Central dispatch point for all terminal operations
" PARAMETERS:
"   action  - String: The operation to perform ('cleanup', 'check', 'create', etc.)
"   options - Dict: Operation-specific options
" RETURNS:
"   Operation-dependent result value
" LOGIC:
"   Routes requests to the appropriate specialized handler function
" ==============================================================================
function! zzvim_r#terminal#process(action, options) abort
    if a:action ==# 'cleanup'
        return zzvim_r#terminal#cleanup(a:options)
    elseif a:action ==# 'check'
        return zzvim_r#terminal#check(a:options)
    elseif a:action ==# 'create'
        return zzvim_r#terminal#create(a:options)
    elseif a:action ==# 'send'
        return zzvim_r#terminal#send(a:options)
    elseif a:action ==# 'control'
        return zzvim_r#terminal#control(a:options)
    elseif a:action ==# 'info'
        return zzvim_r#terminal#info(a:options)
    endif
    
    return v:false
endfunction