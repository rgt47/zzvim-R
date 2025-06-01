" ==============================================================================
" config.vim - Configuration management for zzvim-R plugin
" ==============================================================================
" File:         autoload/zzvim_r/config.vim
" Maintainer:   RG Thomas <rgthomas@ucsd.edu>
" Version:      2.3
" License:      GPL-3.0
" Description:  Configuration management for the zzvim-R plugin
"
" OVERVIEW:
" This module handles all configuration aspects of the zzvim-R plugin, separating
" user-configurable settings from internal plugin structures. It provides
" a schema-based approach for user settings with validation, default values,
" and documentation. The module also manages configuration retrieval and updates.
"
" CONFIGURATION:
" User configuration is defined through global variables (g:zzvim_r_*) which
" are loaded, validated, and stored by this module. Internal configuration
" structures define plugin behavior that users don't typically need to modify.
"
" FUNCTIONS:
" - init()          : Initialize configuration from user settings and defaults
" - get()           : Get a specific configuration value
" - set()           : Set a configuration value
" - get_all()       : Get the complete configuration
" - get_internal()  : Get internal configuration structures
" - get_schema()    : Get user configuration schema
" - load_user_config() (private): Load and validate user settings
"
" VARIABLES:
" - s:user_config_schema: Schema for user-configurable settings
" - s:internal_config:    Internal configuration structures
" - s:config:             Combined configuration (user + internal)
"
" DEPENDENCIES:
" This module has no dependencies on other zzvim_r modules, as it provides
" foundational configuration for the rest of the plugin.
" ==============================================================================

" ==============================================================================
" User Configuration Schema
" ==============================================================================
" FORMAT:
" 'key': ['global_variable_name', default_value, 'description']
" ==============================================================================
let s:user_config_schema = {
    \ 'command': ['zzvim_r_command', 'R --no-save --quiet', 'R command to execute'],
    \ 'width': ['zzvim_r_terminal_width', 100, 'Width of R terminal window'],
    \ 'disable_mappings': ['zzvim_r_disable_mappings', 0, 'Disable default key mappings'],
    \ 'chunk_start': ['zzvim_r_chunk_start', '^```{[rR]', 'R chunk start pattern'],
    \ 'chunk_end': ['zzvim_r_chunk_end', '^```\s*$', 'R chunk end pattern'],
    \ 'debug': ['zzvim_r_debug', 0, 'Debug level (0-4)'],
    \ 'log_file': ['zzvim_r_log_file', '~/zzvim_r.log', 'Log file path']
\ }

" ==============================================================================
" Internal Configuration Structures
" ==============================================================================
" These structures define plugin behavior that users typically don't need
" to modify directly. They include file type support, messaging formats,
" terminal settings, and R command templates.
" ==============================================================================
let s:internal_config = {
    \ 'supported_types': ['r', 'rmd', 'rnw', 'qmd'],
    \ 'msg_types': {'error': [1, 'ErrorMsg', 0], 'warn': [2, 'WarningMsg', 1], 'info': [3, 'None', 1]},
    \ 'log_levels': ['', 'ERROR', 'WARN', 'INFO', 'DEBUG'],
    \ 'terminal_settings': ['norelativenumber', 'nonumber', 'signcolumn=no', 'nobuflisted', 'bufhidden=wipe', 'nospell'],
    \ 'r_functions': {'help': '"%s"', 'exists': '"%s"'},
    \ 'enhanced_inspections': {
        \ 'browse': 'ls.str()', 
        \ 'workspace': 'ls()', 
        \ 'class': 'cat("Class:", class(%s), "\nType:", typeof(%s), "\n")',
        \ 'detailed': 'str(%s, max.level=2)'
    \ },
    \ 'package_operations': {
        \ 'install': 'install.packages("%s")',
        \ 'load': 'library(%s)',
        \ 'update': 'update.packages("%s")',
        \ 'remove': 'remove.packages("%s")'
    \ },
    \ 'data_operations': {
        \ 'read_csv': 'read.csv("%s")',
        \ 'write_csv': 'write.csv(%s, "%s")',
        \ 'read_rds': 'readRDS("%s")',
        \ 'save_rds': 'saveRDS(%s, "%s")'
    \ },
    \ 'directory_operations': {
        \ 'pwd': 'getwd()',
        \ 'cd': 'setwd("%s")',
        \ 'ls': 'list.files()',
        \ 'home': 'setwd("~")'
    \ },
    \ 'content_types': {
        \ 'line': {'getter': 'getline(".")', 'single': 1, 'nav': 'normal! j'},
        \ 'selection': {'bounds': ["getpos(\"'<\")", "getpos(\"'>\")"], 'nav': 'cursor(%s[1] + 1, 1)'},
        \ 'chunk': {'pattern': ['chunk_start', 'chunk_end'], 'nav': 'search(%s, "W") | normal! j | normal! zz'},
        \ 'previous': {'collect': 1}
    \ }
\ }

" Combined configuration (initialized in init())
let s:config = {}

" ==============================================================================
" zzvim_r#config#init() - Initialize configuration
" ==============================================================================
" PURPOSE: Initialize plugin configuration by loading user settings and defaults
" PARAMETERS: None
" RETURNS: Dict with the complete configuration
" SIDE EFFECTS:
"   - Sets the g:zzvim_r_terminal_width global variable for backward compatibility
"   - Initializes the s:config dictionary
" ==============================================================================
function! zzvim_r#config#init() abort
    " Load user configuration and extend with internal config
    let s:config = extend(s:load_user_config(), s:internal_config)
    
    " Expose width for backward compatibility
    let g:zzvim_r_terminal_width = s:config.width
    
    return s:config
endfunction

" ==============================================================================
" s:load_user_config() - Load and validate user configuration
" ==============================================================================
" PURPOSE: Load user settings from global variables with validation and defaults
" PARAMETERS: None
" RETURNS: Dict with validated user configuration
" LOGIC:
"   1. For each setting in the schema, get the value from global variable or default
"   2. Apply validation rules (e.g., min/max for width)
"   3. Store validated values in a new configuration dictionary
" ==============================================================================
function! s:load_user_config() abort
    " Initialize empty configuration
    let l:user_config = {}
    
    " Process each configuration option
    for [l:key, l:schema] in items(s:user_config_schema)
        " Extract schema components
        let [l:var_name, l:default, l:desc] = l:schema
        
        " Get the user value or default
        let l:value = get(g:, l:var_name, l:default)
        
        " Apply validation rules for specific settings
        if l:key ==# 'width'
            " Enforce min/max bounds for terminal width
            let l:value = max([30, min([300, l:value])])
        endif
        
        " Store validated value
        let l:user_config[l:key] = l:value
    endfor
    
    return l:user_config
endfunction

" ==============================================================================
" zzvim_r#config#get(key, [default]) - Get configuration value
" ==============================================================================
" PURPOSE: Retrieve a specific configuration value
" PARAMETERS:
"   key     - String: The configuration key to retrieve
"   default - Any (optional): Value to return if key is not found
" RETURNS: The configuration value or the default if not found
" ==============================================================================
function! zzvim_r#config#get(key, ...) abort
    let l:default = get(a:, 1, '')
    return has_key(s:config, a:key) ? s:config[a:key] : l:default
endfunction

" ==============================================================================
" zzvim_r#config#set(key, value) - Set configuration value
" ==============================================================================
" PURPOSE: Update a configuration value
" PARAMETERS:
"   key   - String: The configuration key to set
"   value - Any: The new value to set
" RETURNS: The newly set value
" SIDE EFFECTS:
"   - Updates the corresponding global variable for backward compatibility
"     (currently only implemented for 'width')
" ==============================================================================
function! zzvim_r#config#set(key, value) abort
    " Update the configuration value
    let s:config[a:key] = a:value
    
    " Special case for width - also update global for backward compatibility
    if a:key ==# 'width'
        let g:zzvim_r_terminal_width = a:value
    endif
    
    return a:value
endfunction

" ==============================================================================
" zzvim_r#config#get_all() - Get all configuration
" ==============================================================================
" PURPOSE: Retrieve the complete configuration dictionary
" PARAMETERS: None
" RETURNS: Dict with the complete configuration
" ==============================================================================
function! zzvim_r#config#get_all() abort
    return s:config
endfunction

" ==============================================================================
" zzvim_r#config#get_internal() - Get internal configuration
" ==============================================================================
" PURPOSE: Retrieve the internal configuration structures
" PARAMETERS: None
" RETURNS: Dict with the internal configuration
" ==============================================================================
function! zzvim_r#config#get_internal() abort
    return s:internal_config
endfunction

" ==============================================================================
" zzvim_r#config#get_schema() - Get user configuration schema
" ==============================================================================
" PURPOSE: Retrieve the user configuration schema
" PARAMETERS: None
" RETURNS: Dict with the user configuration schema
" ==============================================================================
function! zzvim_r#config#get_schema() abort
    return s:user_config_schema
endfunction