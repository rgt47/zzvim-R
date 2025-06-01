# zzvim-R Plugin Architecture & Development Guide

This document provides comprehensive information about the zzvim-R plugin, its architecture, functionality, development history, and key code patterns to help Claude understand and work with this codebase effectively.

## Plugin Overview

zzvim-R is a Vim plugin that provides comprehensive R integration for Vim/Neovim, enabling seamless development workflows for R programming. The plugin is designed with a clean, modular architecture and follows best practices for Vim plugin development.

### Key Features

- **Terminal Integration**: Persistent R terminal session management per Vim tab
- **Code Execution**: Send lines, visual selections, and R Markdown chunks to R
- **Chunk Navigation**: Navigate between R Markdown code chunks
- **Object Inspection**: Examine R objects with various inspection functions
- **Package Management**: Install, load, and update R packages
- **Data Import/Export**: Work with CSV and RDS files
- **Directory Management**: Navigate working directories
- **Help System**: Access R documentation and examples

## Project Structure

```
zzvim-R/
├── autoload/               # Lazy-loaded functions (loaded on demand)
│   └── zzvim_r.vim         # Public API functions
├── plugin/                 # Core plugin code (loaded at startup)
│   └── zzvim_r.vim         # Core engine functions
├── doc/                    # Documentation
│   └── zzvim-R.txt         # Vim help documentation
├── test_files/             # Test files
│   ├── code_examples/      # Example code patterns
│   ├── test.R              # R test file
│   ├── test.Rmd            # R Markdown test file
│   └── test_error_handling.vim  # Error handling test
├── CHANGELOG.md            # Version history
├── LICENSE                 # License information
├── README.md               # User documentation
├── improvements.md         # Development improvements
└── code_quality_report.md  # Code quality assessment
```

## Architecture & Design Patterns

The plugin uses a layered architecture with a clear separation of concerns:

1. **Core Engine Layer** (plugin/zzvim_r.vim):
   - Configuration management through `s:config` dictionary
   - Core engine functions with action-based dispatch through `s:engine()`
   - Command and mapping registration

2. **Public API Layer** (autoload/zzvim_r.vim):
   - User-facing functions with comprehensive documentation
   - Lazy-loaded through Vim's autoload mechanism
   - Delegates to core engines for implementation

3. **Communication Pattern**:
   - Functions validate context before execution using `s:public_wrapper()`
   - Robust error handling and dependency checking
   - Consistent return values (integers 0/1)

## Key Engine Functions

The `s:engine()` function is the central dispatch mechanism that routes operations to specialized handlers:

1. `s:terminal_engine()`: Manages R terminal sessions
2. `s:text_engine()`: Handles text extraction for different content types
3. `s:execute_engine()`: Executes code in the R terminal
4. `s:package_engine()`: Manages R package operations
5. `s:data_engine()`: Handles data file operations
6. `s:directory_engine()`: Manages working directory operations

## Public API Functions

The public API is defined in autoload/zzvim_r.vim and includes:

1. **Terminal Control**: `open_terminal()`, `send_quit()`, `send_interrupt()`
2. **Code Execution**: `submit_line()`, `submit_selection()`
3. **Chunk Navigation**: `navigate_next_chunk()`, `navigate_prev_chunk()`, `execute_chunk()`, `execute_previous_chunks()`
4. **Package Management**: `install_package()`, `load_package()`, `update_package()`
5. **Data Operations**: `read_csv()`, `write_csv()`, `read_rds()`, `save_rds()`
6. **Object Inspection**: `inspect()`, `browse_workspace()`, `list_workspace()`, etc.
7. **Help Functions**: `help_examples()`, `apropos_help()`, `find_definition()`

## Key Mappings System

The plugin provides a comprehensive set of key mappings that follow a consistent naming scheme:

1. **Core Operations**:
   - `<LocalLeader>r`: Open R terminal
   - `<CR>`: Send line/selection to R

2. **Chunk Navigation**:
   - `<LocalLeader>j/k`: Next/previous chunk
   - `<LocalLeader>l`: Execute current chunk
   - `<LocalLeader>t`: Execute all previous chunks

3. **Object Inspection** (single-letter):
   - `<LocalLeader>h`: head()
   - `<LocalLeader>s`: str()
   - `<LocalLeader>d`: dim()
   - `<LocalLeader>p`: print()
   - etc.

4. **Feature-Specific Prefixes**:
   - `<LocalLeader>x*`: Package operations
   - `<LocalLeader>z*`: Data operations
   - `<LocalLeader>v*`: Directory operations
   - `<LocalLeader>u*`: Help functions
   - `<LocalLeader>w*`: Workspace operations

## Development History

### Version 2.3.0 (Key Mapping & Navigation Fixes)

In version 2.3.0, two major issues were fixed:

1. **Chunk Navigation Fix**: The `navigate_prev_chunk()` function was completely rewritten to fix several critical issues:
   - Original function incorrectly used pattern strings as line numbers with `setpos()`
   - No actual pattern searching was performed
   - The function didn't consider the cursor's context
   - The fixed implementation properly uses `search()`, handles cursor context, and preserves position

2. **Key Mapping Conflict Resolution**: Changed prefixes for two-letter mappings to eliminate conflicts with single-letter mappings:
   - Package management: `pi/pl/pu` → `xi/xl/xu`
   - Data operations: `dr/dw/dl/ds` → `zr/zw/zl/zs`
   - Directory operations: `pd/cd/ld/hd` → `vd/vc/vl/vh`
   - Help functions: `he/ha/hf` → `ue/ua/uf`

### Version 2.3.1 & 2.3.2 (Code Quality Improvements)

These versions focused on code quality and architecture:

1. **Delegation Pattern**: Implemented a clean delegation pattern between autoload and plugin files
2. **Variable Scoping**: Fixed issues with script-local vs. function-local variables
3. **Return Value Standardization**: Changed from v:true/v:false to integers (0/1)
4. **Error Handling**: Added helper functions and improved error messaging
5. **Configuration Access**: Implemented safe configuration access with fallbacks

### Version 3.0.0 (API Streamlining)

Major code cleanup and API streamlining:

1. **Removed Redundancies**: Eliminated duplicate functions and deprecated wrapper
2. **Unified API**: Consolidated object inspection into a unified `inspect()` function
3. **Enhanced Documentation**: Added breaking changes section to help documentation
4. **Improved Architecture**: Better separation of concerns between files
5. **Standardized Behavior**: Consistent return values and error handling

## Code Examples & Patterns

### Engine Function Pattern

```vim
function! s:engine(operation, ...) abort
    if a:operation ==# 'terminal'
        return s:terminal_engine(a:1, get(a:000, 1, {}))
    elseif a:operation ==# 'text'
        return s:text_engine(a:1, get(a:000, 1, {}))
    " ... more operations ...
    endif
    return 0
endfunction
```

### Autoload Delegation Pattern

```vim
function! zzvim_r#open_terminal() abort
    if exists('*s:public_wrapper') && exists('*s:terminal_engine')
        return s:public_wrapper(function('s:terminal_engine'), 'create', {})
    else
        echom 'zzvim-R: Plugin core functions not available'
        return 0
    endif
endfunction
```

### Unified API Pattern

```vim
function! zzvim_r#inspect(type, ...) abort
    " Define mapping of inspection types to R functions and default args
    let l:inspect_map = {
        \ 'head': ['head', 'n = 10'],
        \ 'str': ['str', ''],
        \ 'dim': ['dim', ''],
        \ ...
    \ }
    
    " Get the R function and default args
    let [l:func, l:default_args] = l:inspect_map[a:type]
    
    " Override default args if provided
    let l:extra_args = get(a:, 1, l:default_args)
    
    " Delegate to helper function
    return s:send_inspect_command(l:func, l:extra_args)
endfunction
```

## Common Development Patterns

1. **Function Validation**: Always check that required functions exist before calling them
2. **Error Handling**: Use helper functions for consistent error messages
3. **Configuration Access**: Use helper functions with fallbacks for accessing configuration
4. **Terminal Checking**: Verify terminal exists before sending commands
5. **Return Values**: Use integers (0/1) consistently for success/failure
6. **Function References**: Pass script-local functions as references to avoid scoping issues

## Key Issue Fixes

### Chunk Navigation Fix

The original problematic implementation:

```vim
function! zzvim_r#navigate_prev_chunk() abort
    let l:chunk_start = get(g:, 'zzvim_r_chunk_start', '^```{[rR]')
    call setpos('.', [0, l:chunk_start, 1, 0])
    let l:chunk_end = get(g:, 'zzvim_r_chunk_end', '^```\s*$')
    call setpos('.', [0, l:chunk_end, 1, 0])
    let l:chunk_start = get(g:, 'zzvim_r_chunk_start', '^```{[rR]')
    call setpos('.', [0, l:chunk_start, 1, 0])
            normal! j
endfunction
```

The fixed implementation properly handles chunk navigation by:
- Saving the current position
- Checking if the cursor is inside a chunk
- Using proper search functions with appropriate flags
- Handling edge cases and providing feedback
- Centering the display after navigation

### Key Mapping Conflict Resolution

The plugin had conflicts where pressing a single-letter mapping would delay to check for two-letter mappings with the same prefix. The solution was to change prefixes for two-letter mappings:

- `<LocalLeader>h` for head() no longer conflicts with help functions
- `<LocalLeader>p` for print() no longer conflicts with package functions
- `<LocalLeader>d` for dim() no longer conflicts with data functions

## Vim-Specific Implementation Notes

1. **Autoload Mechanism**: Functions in autoload/ are only loaded when called
2. **Script-Local Functions**: Functions prefixed with `s:` are only accessible within their script
3. **Terminal Management**: Uses Vim's built-in terminal features
4. **Variable Scoping**:
   - `g:` Global variables
   - `s:` Script-local variables
   - `l:` Function-local variables
   - `a:` Function argument variables
   - `t:` Tab-local variables
5. **Error Handling**: Uses try/catch and existence checks
6. **Command Registration**: Uses `execute` with `printf` for dynamic command creation
7. **Key Mapping**: Uses autocmd with FileType to create filetype-specific mappings

## Working with the Codebase

When modifying this plugin:

1. **Test Files**: Use the test files in test_files/ for testing changes
2. **Error Handling**: Always include proper error handling and dependency checks
3. **Return Values**: Return 0 for failure and 1 for success consistently
4. **Variable Scoping**: Be careful with variable scoping in loops
5. **File Organization**: Keep core engines in plugin file, public API in autoload
6. **Documentation**: Update both inline comments and help documentation

## Testing Process

When testing the plugin, focus on these key areas:

1. **Terminal Integration**: Verify terminal creation and interaction
2. **Chunk Navigation**: Test navigation in R Markdown files
3. **Object Inspection**: Test all inspection functions
4. **Error Handling**: Test plugin behavior with invalid inputs
5. **File Type Support**: Test with different R file types (R, RMD, QMD)

## Security & Limitations

- The plugin interacts directly with the R interpreter
- Functions are designed to work with specific R data structures and patterns
- Error handling is focused on missing functions and invalid inputs
- The plugin does not implement any security restrictions beyond what Vim provides