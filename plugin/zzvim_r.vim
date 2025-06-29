" ==============================================================================
" zzvim_r - R development plugin for Vim
" ==============================================================================
" File:        plugin/zzvim_r.vim
" Maintainer:  RG Thomas <rgthomas@ucsd.edu>
" Version:     3.0.0
" License:     GPL-3.0
" Description: Comprehensive R integration for Vim with terminal management,
"              chunk navigation, and object inspection capabilities.
"
" FEATURES:
" - Persistent R terminal session management per Vim tab
" - Send lines, visual selections, and R Markdown chunks to R
" - Navigate between R Markdown code chunks
" - Enhanced object inspection and workspace browser
" - Package management (install, load, update)
" - Data import/export utilities (CSV, RDS)
" - Directory management and navigation
" - Enhanced help system with examples and search
" - Configurable key mappings and behavior
" - Comprehensive error handling and debug logging
" - Support for R, R Markdown, and Quarto files
"
" REQUIREMENTS:
" - Vim 8.0+ with terminal support
" - R executable in PATH
" - Optional: tidyverse packages for enhanced inspection functions
"
" QUICK START:
" 1. Open an R file (.r, .rmd, .qmd)
" 2. Press <LocalLeader>r to open R terminal
" 3. Use <CR> to send current line or visual selection to R
" 4. Navigate chunks with <LocalLeader>j/k, execute with <LocalLeader>l
" 5. Use inspection shortcuts: <LocalLeader>h for head(), etc.
"
" CONFIGURATION:
" See g:zzvim_r_* variables below for customization options.
" ==============================================================================

" Prevent multiple loading and enforce minimum Vim version
if exists('g:loaded_zzvim_r') || v:version < 800 || !has('terminal')
    finish
endif
let g:loaded_zzvim_r = 1

" Save user's cpoptions and restore at end
let s:save_cpo = &cpoptions
set cpoptions&vim

"==============================================================================
" CONFIGURATION VARIABLES
"==============================================================================
" These variables control plugin behavior and can be customized in vimrc.
" All configuration is centralized for easier management and validation.

" Master configuration dictionary with all settings, defaults, and metadata
let s:config = {}

" User configuration
let s:config.command = get(g:, 'zzvim_r_command', 'R --no-save --quiet')
let s:config.width = max([30, min([300, 
                        \ get(g:, 'zzvim_r_terminal_width', 100)])])
let s:config.disable_mappings = get(g:, 'zzvim_r_disable_mappings', 0)
let s:config.chunk_start = get(g:, 'zzvim_r_chunk_start', '^```{[rR]')
let s:config.chunk_end = get(g:, 'zzvim_r_chunk_end', '^```\s*$')
let s:config.debug = get(g:, 'zzvim_r_debug', 0)
let s:config.log_file = get(g:, 'zzvim_r_log_file', '~/zzvim_r.log')

" Internal configuration
let s:config.supported_types = ['r', 'rmd', 'rnw', 'qmd']
let s:config.msg_types = {'error': [1, 'ErrorMsg', 0], 'warn': [2, 'WarningMsg', 1], 
                        \ 'info': [3, 'None', 1]}
let s:config.log_levels = ['', 'ERROR', 'WARN', 'INFO', 'DEBUG']
let s:config.terminal_settings = ['norelativenumber', 'nonumber', 'signcolumn=no', 
                               \ 'nobuflisted', 'bufhidden=wipe', 'nospell']
let s:config.r_functions = {'help': '"%s"', 'exists': '"%s"'}

" Enhanced inspections
let s:config.enhanced_inspections = {}
let s:config.enhanced_inspections.browse = 'ls.str()'
let s:config.enhanced_inspections.workspace = 'ls()'
let s:config.enhanced_inspections.class = 'cat("Class:", class(%s), 
                                        \ "\nType:", typeof(%s), "\n")'
let s:config.enhanced_inspections.detailed = 'str(%s, max.level=2)'

" Package operations
let s:config.package_operations = {}
let s:config.package_operations.install = 'install.packages("%s")'
let s:config.package_operations.load = 'library(%s)'
let s:config.package_operations.update = 'update.packages("%s")'
let s:config.package_operations.remove = 'remove.packages("%s")'

" Data operations
let s:config.data_operations = {}
let s:config.data_operations.read_csv = 'read.csv("%s")'
let s:config.data_operations.write_csv = 'write.csv(%s, "%s")'
let s:config.data_operations.read_rds = 'readRDS("%s")'
let s:config.data_operations.save_rds = 'saveRDS(%s, "%s")'

" Directory operations
let s:config.directory_operations = {}
let s:config.directory_operations.pwd = 'getwd()'
let s:config.directory_operations.cd = 'setwd("%s")'
let s:config.directory_operations.ls = 'list.files()'
let s:config.directory_operations.home = 'setwd("~")'

" Content types
let s:config.content_types = {}
let s:config.content_types.line = {'getter': 'getline(".")', 'single': 1, 
                                \ 'nav': 'normal! j'}
let s:config.content_types.selection = {'bounds': ["getpos(\"'<\")", 
                                     \ "getpos(\"'>\")"], 
                                     \ 'nav': 'cursor(%s[1] + 1, 1)'}
let s:config.content_types.chunk = {'pattern': ['chunk_start', 'chunk_end'], 
                                 \ 'nav': 'search(%s, "W") | normal! j | normal! zz'}
let s:config.content_types.previous = {'collect': 1}

" NOTE: We don't expose s:config.width globally anymore to avoid unnecessary
" global namespace pollution. For backward compatibility, we still read
" g:zzvim_r_terminal_width if it exists, but don't set it.

"==============================================================================
" CORE ENGINE FUNCTIONS
"==============================================================================
" These functions are shared between the plugin and autoload files to ensure
" consistent behavior. They provide the low-level functionality that the 
" public API builds upon.

" ==============================================================================
" s:engine(operation, ...) - Master plugin operation engine
" ==============================================================================
" PURPOSE: Central dispatch engine for all plugin operations
" PARAMETERS:
"   operation - String: operation type (log, msg, terminal, text, execute)
"   ...       - Variable: operation-specific parameters
" RETURNS: Operation-dependent results
" LOGIC: Single entry point dispatching to specialized operation handlers
" ==============================================================================
function! s:engine(operation, ...) abort
    if a:operation ==# 'log'
        " s:engine('log', msg, level)
        if len(a:000) >= 2 && s:config.debug >= a:2
            let l:entry = printf('[%s] %s: %s', strftime('%H:%M:%S'),
                               \ s:config.log_levels[a:2], a:1)
            try
                call writefile([l:entry], expand(s:config.log_file), 'a')
            catch
            endtry
            if s:config.debug >= 4
                echom 'zzvim-R: ' . a:1
            endif
        endif
        return 1  " Use integers (0/1) consistently for return values
        
    elseif a:operation ==# 'msg'
        " s:engine('msg', msg, type)
        let [l:level, l:hl, l:ret] = get(s:config.msg_types, a:2, 
                                      \ [3, 'None', 1])
        if l:hl !=# 'None' 
            execute 'echohl ' . l:hl 
        endif
        echom 'zzvim-R: ' . a:1
        if l:hl !=# 'None' 
            echohl None 
        endif
        call s:engine('log', a:1, l:level)
        return l:ret
        
    elseif a:operation ==# 'terminal'
        " s:engine('terminal', action, ...)
        return s:terminal_engine(a:1, get(a:000, 1, {}))
        
    elseif a:operation ==# 'text'
        " s:engine('text', type, ...)
        return s:text_engine(a:1, get(a:000, 1, {}))
        
    elseif a:operation ==# 'execute'
        " s:engine('execute', type, options)
        return s:execute_engine(a:1, get(a:000, 1, {}))
        
    elseif a:operation ==# 'package'
        " s:engine('package', 'action', 'package_name')
        return s:package_engine(a:1, a:2)
        
    elseif a:operation ==# 'data'
        " s:engine('data', 'action', 'file_path', 'variable')
        return s:data_engine(a:1, get(a:000, 1, ''), get(a:000, 2, ''))
        
    elseif a:operation ==# 'directory'
        " s:engine('directory', 'action', 'path')
        return s:directory_engine(a:1, get(a:000, 1, ''))
        
    elseif a:operation ==# 'validate'
        " s:engine('validate', type, value)
        return a:1 ==# 'filetype' ? 
             \ index(s:config.supported_types, &filetype) >= 0 :
             \ a:1 ==# 'word' ? 
             \ (!empty(a:2) && a:2 =~# '^[a-zA-Z_\.][a-zA-Z0-9_\.\$]*$') :
             \ a:1 ==# 'r_executable' ? executable('R') : 0
    endif

    return 0  " Use integers (0/1) consistently for return values
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:terminal_engine(action, options) - Terminal operation engine
" ==============================================================================
" PURPOSE: Handles all terminal-related operations through unified interface
" PARAMETERS:
"   action  - String: 'check', 'create', 'send', 'control', 'cleanup', 'info'
"   options - Dict: action-specific options
" RETURNS: Action-dependent results
" ==============================================================================
function! s:terminal_engine(action, options) abort
    if a:action ==# 'cleanup'
        for l:var in ['t:zzvim_r_terminal_id', 't:zzvim_r_job_id']
            if exists(l:var) 
                execute 'unlet ' . l:var 
            endif
        endfor
        call s:engine('log', 'Terminal variables cleaned', 4)
        return 0  " Use integers (0/1) consistently for return values
        
    elseif a:action ==# 'check'
        if !exists('t:zzvim_r_terminal_id') || !exists('t:zzvim_r_job_id')
            call s:engine('log', 'No terminal variables', 4)
            return 0
        endif
        
        for [l:check, l:msg] in [
            \ [bufexists(t:zzvim_r_terminal_id), 'Buffer missing'],
            \ [getbufvar(t:zzvim_r_terminal_id, '&buftype') ==# 'terminal', 
            \ 'Not terminal']
        \ ]
            if !l:check
                call s:engine('log', l:msg, 3)
                return s:terminal_engine('cleanup', {})
            endif
        endfor
        
        try
            return job_status(t:zzvim_r_job_id) ==# 'run' ?
                \ 1 : s:terminal_engine('cleanup', {})
        catch
            return s:terminal_engine('cleanup', {})
        endtry
        
    elseif a:action ==# 'create'
        if !s:engine('validate', 'r_executable', '') 
            return s:engine('msg', 'R executable not found', 'error')
        endif
        if s:terminal_engine('check', {})
            return s:engine('msg', 'R terminal already active', 'info')
        endif
        
        let l:context = [winnr(), bufnr('%')]
        try
            execute printf('vertical terminal %s', s:config.command)
            execute printf('vertical resize %d', s:config.width)
            for l:setting in s:config.terminal_settings 
                execute 'setlocal ' . l:setting 
            endfor
            silent! file [R-Terminal]
            let t:zzvim_r_terminal_id = bufnr('%')
            let t:zzvim_r_job_id = term_getjob(bufnr('%'))
            execute printf('%dwincmd w | if bufnr("%%") != %d | buffer %d | endif', 
                        \ l:context[0], l:context[1], l:context[1])
            call s:engine('msg', 'R terminal opened successfully', 'info')
            return 1  " Use integers (0/1) consistently for return values
        catch
            call s:terminal_engine('cleanup', {})
            return s:engine('msg', 'Failed to create terminal: ' . v:exception, 
                          \ 'error')
        endtry
        
    elseif a:action ==# 'send'
        if !s:terminal_engine('check', {}) && !s:terminal_engine('create', {}) 
            return 0  " Use integers (0/1) consistently for return values 
        endif
        
        let l:content = get(a:options, 'content', '')
        let l:desc = get(a:options, 'desc', 'command')
        
        if type(l:content) == v:t_string
            let l:cmd = trim(l:content)
            if empty(l:cmd)
                return 1  " Use integers (0/1) consistently
            endif
            try
                call term_sendkeys(t:zzvim_r_terminal_id, l:cmd . "\n")
                call s:engine('log', 'Sent: ' . l:cmd, 4)
                return 1  " Use integers (0/1) consistently
            catch
                return s:engine('msg', 'Send failed: ' . v:exception, 'error')
            endtry
            
        elseif type(l:content) == v:t_list
            if empty(filter(copy(l:content), '!empty(trim(v:val))'))
                return s:engine('msg', l:desc . ' has no executable code', 'warn')
            endif
            try
                let l:temp = tempname() . '.R'
                call writefile(l:content, l:temp)
                let l:success = s:terminal_engine('send', 
                            \ {'content': printf("source('%s', echo=TRUE)", l:temp), 
                            \ 'desc': 'source'})
                if l:success 
                    call s:engine('msg', 'Sourced ' . l:desc, 'info') 
                endif
                return l:success
            catch
                return s:engine('msg', 'Source failed: ' . v:exception, 'error')
            endtry
        endif
        
    elseif a:action ==# 'control'
        if !s:terminal_engine('check', {}) 
            return s:engine('msg', 'No terminal active', 'error') 
        endif
        try
            call term_sendkeys(t:zzvim_r_terminal_id, get(a:options, 'key', ''))
            return s:engine('msg', 'Sent control key', 'info')
        catch
            return s:engine('msg', 'Control key failed', 'error')
        endtry
        
    elseif a:action ==# 'info'
        return exists('t:zzvim_r_terminal_id') ? 
             \ {'id': t:zzvim_r_terminal_id, 
             \ 'active': s:terminal_engine('check', {})} : {}
    endif
    
    return 0  " Use integers (0/1) consistently for return values
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:text_engine(type, options) - Text extraction engine
" ==============================================================================
" PURPOSE: Unified text extraction for all content types
" PARAMETERS:
"   type    - String: content type (line, selection, chunk, previous)
"   options - Dict: extraction options
" RETURNS: List of text lines or empty list
" ==============================================================================
function! s:text_engine(type, options) abort
    let l:config = get(s:config.content_types, a:type, {})
    
    if a:type ==# 'line'
        return [getline('.')]
        
    elseif a:type ==# 'selection'
        let [l:start, l:end] = [getpos("'<"), getpos("'>")]
        let l:lines = getline(l:start[1], l:end[1])
        if empty(l:lines) 
            return [] 
        endif
        
        if len(l:lines) == 1
            let l:lines[0] = l:lines[0][l:start[2]-1 : l:end[2]-1]
        else
            let l:lines[0] = l:lines[0][l:start[2]-1:]
            let l:lines[-1] = l:lines[-1][:l:end[2]-1]
        endif
        return empty(trim(join(l:lines, "\n"))) ? [] : l:lines
        
    elseif a:type ==# 'chunk'
        let l:start = search(s:config.chunk_start, 'bcnW')
        if l:start == 0 
            return [] 
        endif
        
        let l:pos = getpos('.')
        call setpos('.', [0, l:start, 1, 0])
        let l:end = search(s:config.chunk_end, 'nW')
        call setpos('.', l:pos)
        
        return (l:end > 0 && l:pos[1] > l:start && l:pos[1] < l:end) ? 
             \ getline(l:start + 1, l:end - 1) : []
        
    elseif a:type ==# 'previous'
        let [l:lines, l:in_chunk] = [[], 0]
        for l:i in range(1, line('.'))
            let l:line = getline(l:i)
            let l:in_chunk = l:line =~# s:config.chunk_start ? 1 :
                           \ l:line =~# s:config.chunk_end ? 0 : l:in_chunk
            if l:in_chunk && !empty(trim(l:line)) 
                call add(l:lines, l:line) 
            endif
        endfor
        return l:lines
        
    elseif a:type ==# 'function_block'
        " Check if current line starts an R function definition
        let l:current_line = getline('.')
        let l:function_pattern = '^\s*\w\+\s*<-\s*function\s*('
        
        if l:current_line !~# l:function_pattern
            " Not a function definition, return just the current line
            return [l:current_line]
        endif
        
        " Find the function block by matching braces
        let l:start_line = line('.')
        let l:brace_count = 0
        let l:found_opening_brace = 0
        let l:lines = []
        
        " Start from current line and search for the complete function
        for l:line_num in range(l:start_line, line('$'))
            let l:line_content = getline(l:line_num)
            call add(l:lines, l:line_content)
            
            " Count braces to find the end of the function
            for l:char_idx in range(strlen(l:line_content))
                let l:char = l:line_content[l:char_idx]
                if l:char ==# '{'
                    let l:brace_count += 1
                    let l:found_opening_brace = 1
                elseif l:char ==# '}'
                    let l:brace_count -= 1
                    
                    " If we've found the opening brace and count is back to 0,
                    " we've found the end of the function
                    if l:found_opening_brace && l:brace_count == 0
                        return l:lines
                    endif
                endif
            endfor
        endfor
        
        " If we couldn't find matching braces, return just the current line
        return [getline('.')]
    endif
    
    return []
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:execute_engine(type, options) - Execution engine for all content types
" ==============================================================================
" PURPOSE: Unified execution engine handling all content types and navigation
" PARAMETERS:
"   type    - String: content type to execute
"   options - Dict: execution options (stay_on_line, etc.)
" RETURNS: Boolean success status
" ==============================================================================
function! s:execute_engine(type, options) abort
    let l:content = s:text_engine(a:type, a:options)
    let l:names = {'line': 'current line', 'selection': 'selection', 
                \ 'chunk': 'current chunk', 'previous': 'previous chunks',
                \ 'function_block': 'function block'}
    
    if empty(l:content)
        let l:msg = a:type ==# 'chunk' ? 'Not inside R chunk' :
                  \ a:type ==# 'previous' ? 'No previous chunks' : 'No content'
        return s:engine('msg', l:msg, 
                      \ a:type ==# 'previous' ? 'info' : 'error')
    endif
    
    " Execute content
    let l:send_content = a:type ==# 'line' ? l:content[0] : l:content
    let l:success = s:terminal_engine('send', 
                  \ {'content': l:send_content, 'desc': l:names[a:type]})
    
    " Handle navigation
    if l:success
        if a:type ==# 'line' && !get(a:options, 'stay_on_line', 0)
            normal! j
        elseif a:type ==# 'selection'
            let l:end = getpos("'>")
            execute "normal! \<Esc>"
            call cursor(l:end[1] + 1, 1)
        elseif a:type ==# 'chunk'
            let l:end = search(s:config.chunk_end, 'nW')
            if l:end > 0
                call setpos('.', [0, l:end + 1, 1, 0])
                if search(s:config.chunk_start, 'W') > 0 
                    normal! j 
                endif
                normal! zz
            endif
        elseif a:type ==# 'function_block'
            " For function blocks, move cursor to the line after the closing brace
            let l:start_line = line('.')
            let l:brace_count = 0
            let l:found_opening_brace = 0
            
            " Find the end of the function by matching braces
            for l:line_num in range(l:start_line, line('$'))
                let l:line_content = getline(l:line_num)
                
                for l:char_idx in range(strlen(l:line_content))
                    let l:char = l:line_content[l:char_idx]
                    if l:char ==# '{'
                        let l:brace_count += 1
                        let l:found_opening_brace = 1
                    elseif l:char ==# '}'
                        let l:brace_count -= 1
                        
                        if l:found_opening_brace && l:brace_count == 0
                            " Move to the line after the function ends
                            call cursor(l:line_num + 1, 1)
                            return l:success
                        endif
                    endif
                endfor
            endfor
        endif
    endif
    
    return l:success
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:package_engine(action, package) - Package management engine
" ==============================================================================
" PURPOSE: Handle package installation, loading, and management
" PARAMETERS:
"   action  - String: 'install', 'load', 'update', 'remove'
"   package - String: R package name
" RETURNS: Boolean success status
" ==============================================================================
function! s:package_engine(action, package) abort
    if empty(a:package)
        return s:engine('msg', 'Package name required', 'error')
    endif
    
    let l:format = get(s:config.package_operations, a:action, 
                    \ s:config.package_operations.load)
    let l:cmd = printf(l:format, a:package)
    let l:success = s:terminal_engine('send', 
                  \ {'content': l:cmd, 
                  \ 'desc': printf('%s package %s', a:action, a:package)})
    
    if l:success 
        call s:engine('msg', 
                    \ printf('Executed %s on package %s', a:action, a:package), 
                    \ 'info') 
    endif
    return l:success
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:data_engine(action, ...) - Data import/export engine
" ==============================================================================
" PURPOSE: Handle data file operations (read/write CSV, RDS)
" PARAMETERS:
"   action   - String: 'read_csv', 'write_csv', 'read_rds', 'save_rds'
"   file     - String: File path (optional, defaults to current file)
"   variable - String: Variable name for write operations (optional)
" RETURNS: Boolean success status
" ==============================================================================
function! s:data_engine(action, ...) abort
    let l:file = get(a:000, 0, expand('%:p'))
    let l:variable = get(a:000, 1, expand('<cword>'))
    
    if a:action =~# '^write\|^save' && empty(l:variable)
        return s:engine('msg', 'No variable under cursor for writing', 'error')
    endif
    
    let l:format = get(s:config.data_operations, a:action, '')
    if empty(l:format)
        return s:engine('msg', 'Unknown data operation: ' . a:action, 'error')
    endif
    
    let l:cmd = a:action =~# '^write\|^save' ? 
              \ printf(l:format, l:variable, l:file) : 
              \ printf(l:format, l:file)
    let l:success = s:terminal_engine('send', 
                  \ {'content': l:cmd, 
                  \ 'desc': printf('%s on %s', a:action, l:file)})
    
    if l:success
        call s:engine('msg', printf('Executed %s on %s', a:action, l:file), 'info')
    endif
    return l:success
endfunction
" ------------------------------------------------------------------------------

" ==============================================================================
" s:directory_engine(action, ...) - Directory management engine
" ==============================================================================
" PURPOSE: Handle directory operations (pwd, cd, ls, home)
" PARAMETERS:
"   action - String: 'pwd', 'cd', 'ls', 'home'
"   path   - String: Directory path for 'cd' (optional)
" RETURNS: Boolean success status
" ==============================================================================
function! s:directory_engine(action, ...) abort
    let l:path = get(a:000, 0, expand('%:p:h'))
    
    let l:format = get(s:config.directory_operations, a:action, '')
    if empty(l:format)
        return s:engine('msg', 'Unknown directory operation: ' . a:action, 'error')
    endif
    
    let l:cmd = a:action ==# 'cd' ? printf(l:format, l:path) : l:format
    let l:success = s:terminal_engine('send', 
                  \ {'content': l:cmd, 
                  \ 'desc': printf('directory %s', a:action)})
    
    if l:success
        call s:engine('msg', printf('Executed directory %s', a:action), 'info')
    endif
    return l:success
endfunction
" ------------------------------------------------------------------------------

"==============================================================================
" PUBLIC API FUNCTIONS
"==============================================================================
" Provides direct public API functions for use by autoload module.
" This bypasses the circular dependency issue by keeping the API
" implementation directly in the plugin file.

" Public API wrapper for validation
function! s:public_wrapper(Func, ...) abort
    " Use 0/1 return values consistently throughout the plugin API
    return s:engine('validate', 'filetype', '') ? call(a:Func, a:000) :
         \ s:engine('msg', 'File type not supported', 'error')
endfunction

" ==============================================================================
" Core API functions used directly by command mappings
" These can be overridden by the autoload versions if loaded
" ==============================================================================

function! zzvim_r#open_terminal() abort
    return s:public_wrapper(function('s:terminal_engine'), 'create', {})
endfunction

function! zzvim_r#submit_line() abort
    " Check if current line starts a function definition
    let l:current_line = getline('.')
    let l:function_pattern = '^\s*\w\+\s*<-\s*function\s*('
    
    if l:current_line =~# l:function_pattern
        " Use function_block type for intelligent function detection
        return s:public_wrapper(function('s:execute_engine'), 'function_block', {})
    else
        " Use normal line submission for non-function lines
        return s:public_wrapper(function('s:execute_engine'), 'line', {})
    endif
endfunction

function! zzvim_r#submit_selection() abort
    return s:public_wrapper(function('s:execute_engine'), 'selection', {})
endfunction

function! zzvim_r#terminal_status() abort
    let l:info = s:terminal_engine('info', {})
    echo '=== zzvim-R Status ==='
    echo empty(l:info) ? 'No R terminal' : printf('R terminal %s (Buffer: %d)', 
         \ l:info.active ? 'ACTIVE' : 'INACTIVE', l:info.id)
    echo printf('File: %s | Debug: %d | R: %s', &filetype, s:config.debug, 
              \ s:engine('validate', 'r_executable', '') ? 'Found' : 'Missing')
    echo '====================='
    return 1
endfunction

function! zzvim_r#toggle_debug() abort
    let s:config.debug = (s:config.debug + 1) % 5
    call s:engine('msg', 'Debug level: ' . s:config.debug, 'info')
    return 1
endfunction

function! zzvim_r#package_management(action, package) abort
    return s:public_wrapper(function('s:package_engine'), a:action, a:package)
endfunction

function! zzvim_r#data_operation(action, ...) abort
    return call('s:public_wrapper', [function('s:data_engine'), a:action] + a:000)
endfunction

function! zzvim_r#directory_operation(action, ...) abort
    return call('s:public_wrapper', [function('s:directory_engine'), a:action] + a:000)
endfunction

"==============================================================================
" COMMANDS & MAPPINGS
"==============================================================================
" Programmatically generated commands and mappings using the engine system.

" Generate commands programmatically
let s:cmd_list = [
    \ ['ROpenTerminal', 'zzvim_r#open_terminal()'],
    \ ['RSubmitLine', 'zzvim_r#submit_line()'],
    \ ['RSubmitSelection', 'zzvim_r#submit_selection()'],
    \ ['RTerminalStatus', 'zzvim_r#terminal_status()'],
    \ ['RToggleDebug', 'zzvim_r#toggle_debug()'],
    \ ['RPackage', 'zzvim_r#package_management(get(a:000, 0, "load"), 
    \ get(a:000, 1, ""))'],
    \ ['RData', 'zzvim_r#data_operation(get(a:000, 0, "read_csv"), 
    \ get(a:000, 1, ""))'],
    \ ['RDirectory', 'zzvim_r#directory_operation(get(a:000, 0, "pwd"), 
    \ get(a:000, 1, ""))']
\ ]
for item in s:cmd_list
    let cmd = item[0]
    let func = item[1]
    execute printf('command! -nargs=* %s call %s', cmd, func)
endfor

" Comprehensive mapping system
if !s:config.disable_mappings
    augroup zzvim_r_mappings
        autocmd!
        
        " Core mapping definitions with metadata using public API functions
        let s:mapping_defs = [
            \ ['<LocalLeader>r', 'zzvim_r#open_terminal()', 'all', 'n'],
            \ ['<CR>', 'zzvim_r#submit_line()', 'all', 'n'],
            \ ['<CR>', 'zzvim_r#submit_selection()', 'all', 'x'],
            \ ['<LocalLeader>q', 'zzvim_r#send_quit()', 'all', 'n'],
            \ ['<LocalLeader>c', 'zzvim_r#send_interrupt()', 'all', 'n'],
            \ ['<LocalLeader>o', 'zzvim_r#add_pipe()', 'all', 'n'],
            \ ['<LocalLeader>j', 'zzvim_r#navigate_next_chunk()', 'doc', 'n'],
            \ ['<LocalLeader>k', 'zzvim_r#navigate_prev_chunk()', 'doc', 'n'],
            \ ['<LocalLeader>l', 'zzvim_r#execute_chunk()', 'doc', 'n'],
            \ ['<LocalLeader>t', 'zzvim_r#execute_previous_chunks()', 'doc', 'n'],
            \ ['<LocalLeader>xi', 'zzvim_r#install_package()', 'all', 'n'],
            \ ['<LocalLeader>xl', 'zzvim_r#load_package()', 'all', 'n'],
            \ ['<LocalLeader>xu', 'zzvim_r#update_package()', 'all', 'n'],
            \ ['<LocalLeader>zr', 'zzvim_r#read_csv()', 'all', 'n'],
            \ ['<LocalLeader>zw', 'zzvim_r#write_csv()', 'all', 'n'],
            \ ['<LocalLeader>zl', 'zzvim_r#read_rds()', 'all', 'n'],
            \ ['<LocalLeader>zs', 'zzvim_r#save_rds()', 'all', 'n'],
            \ ['<LocalLeader>vd', 'zzvim_r#print_directory()', 'all', 'n'],
            \ ['<LocalLeader>vc', 'zzvim_r#change_directory()', 'all', 'n'],
            \ ['<LocalLeader>vl', 'zzvim_r#list_directory()', 'all', 'n'],
            \ ['<LocalLeader>vh', 'zzvim_r#home_directory()', 'all', 'n'],
            \ ['<LocalLeader>wb', 'zzvim_r#browse_workspace()', 'all', 'n'],
            \ ['<LocalLeader>wl', 'zzvim_r#list_workspace()', 'all', 'n'],
            \ ['<LocalLeader>wc', 'zzvim_r#show_class()', 'all', 'n'],
            \ ['<LocalLeader>wd', 'zzvim_r#show_detailed()', 'all', 'n'],
            \ ['<LocalLeader>ue', 'zzvim_r#help_examples()', 'all', 'n'],
            \ ['<LocalLeader>ua', 'zzvim_r#apropos_help()', 'all', 'n'],
            \ ['<LocalLeader>uf', 'zzvim_r#find_definition()', 'all', 'n']
        \ ]

        " Add additional inspect mappings with proper public API calls
        for inspect_item in ['h:head', 's:str', 'd:dim', 'n:names', 'p:print',
                            \ 'f:length', 'g:glimpse', 'b:summary', 'y:help']
            let key = split(inspect_item, ':')[0]
            let func = split(inspect_item, ':')[1]
            call add(s:mapping_defs,
                  \ ['<LocalLeader>' . key,
                  \ 'zzvim_r#inspect_' . func . '()', 'all', 'n'])
        endfor
        
        " Generate all mappings
        for mapping in s:mapping_defs
            let key = mapping[0]
            let cmd = mapping[1]
            let scope = mapping[2]
            let mode = mapping[3]

            let types = scope ==# 'all' ? s:config.supported_types :
                      \ filter(copy(s:config.supported_types), 'v:val !=# "r"')
            for ft in types
                execute printf('autocmd FileType %s %snoremap <buffer> <silent> %s
                            \ :<C-u>call %s<CR>',
                            \ ft, mode, key, cmd)
            endfor
        endfor
    augroup END
endif

" Restore user's cpoptions
let &cpoptions = s:save_cpo
unlet s:save_cpo

" ==============================================================================
" QUICK REFERENCE
" ==============================================================================
" Core Commands:
"   <LocalLeader>r  - Open R terminal
"   <CR>            - Send line/selection to R
"
" Chunk Navigation (R Markdown):
"   <LocalLeader>j  - Next chunk
"   <LocalLeader>k  - Previous chunk
"   <LocalLeader>l  - Execute current chunk
"   <LocalLeader>t  - Execute all previous chunks
"
" Session Control:
"   <LocalLeader>q  - Send Q (quit browser/debugger)
"   <LocalLeader>c  - Send Ctrl-C (interrupt)
"
" Object Inspection (word under cursor):
"   <LocalLeader>h  - head()     | <LocalLeader>d  - dim()
"   <LocalLeader>s  - str()      | <LocalLeader>n  - names()
"   <LocalLeader>p  - print()    | <LocalLeader>f  - length()
"   <LocalLeader>g  - glimpse()  | <LocalLeader>b  - summary()
"   <LocalLeader>y  - help()
"
" Object Browser & Workspace:
"   <LocalLeader>wb  - Object browser (ls.str())
"   <LocalLeader>wl  - Workspace listing (ls())
"   <LocalLeader>wc  - Class & type info of object
"   <LocalLeader>wd  - Detailed object structure
"
" Package Management:
"   <LocalLeader>xi  - Install package
"   <LocalLeader>xl  - Load package
"   <LocalLeader>xu  - Update package
"
" Data Import/Export:
"   <LocalLeader>zr  - Read CSV file
"   <LocalLeader>zw  - Write CSV file
"   <LocalLeader>zl  - Load RDS file
"   <LocalLeader>zs  - Save RDS file
"
" Directory Management:
"   <LocalLeader>vd  - Print working directory
"   <LocalLeader>vc  - Change directory
"   <LocalLeader>vl  - List directory contents
"   <LocalLeader>vh  - Change to home directory
"
" Enhanced Help:
"   <LocalLeader>ue  - Help with examples
"   <LocalLeader>ua  - Search help (apropos)
"   <LocalLeader>uf  - Find function definition
"
" Utilities:
"   <LocalLeader>o  - Add pipe operator (%>%)
" ==============================================================================