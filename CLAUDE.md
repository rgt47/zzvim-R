# zzvim-R Plugin Architecture & Development Guide

This document provides comprehensive information about the zzvim-R plugin, its current architecture, functionality, development history, and key code patterns to help Claude understand and work with this codebase effectively.

## Plugin Overview

zzvim-R is a Vim plugin that provides R integration for Vim/Neovim, enabling seamless development workflows for R programming. The plugin focuses on smart code execution with pattern-based detection and follows a simple, single-file architecture.

### Key Features

- **Smart Code Execution**: Intelligent detection of R functions, control structures, and code blocks
- **Terminal Integration**: R terminal session management with persistent sessions
- **Chunk Navigation**: Navigate between R Markdown code chunks
- **Pattern-Based Detection**: Automatic recognition of function definitions, if/else blocks, loops
- **Unified Temp File Approach**: Consistent handling of code submission regardless of size
- **Object Inspection**: Examine R objects with various inspection functions
- **Flexible Key Mappings**: Smart `<CR>` behavior adapts to context

## Project Structure

```
zzvim-R/
├── plugin/                 # Core plugin code (single file architecture)
│   └── zzvim-R.vim         # All plugin functionality
├── doc/                    # Documentation
│   └── zzvim-R.txt         # Vim help documentation
├── test_files/             # Test files and examples
│   ├── code_examples/      # Example code patterns
│   ├── test.R              # R test file
│   ├── test.Rmd            # R Markdown test file
│   ├── test_generalized_send.R     # Tests for generalized SendToR
│   ├── new_functionality_demo.R    # Demo of smart detection
│   └── test_error_handling.vim     # Error handling test
├── CHANGELOG.md            # Version history
├── LICENSE                 # License information
├── README.md               # User documentation
├── improvements.md         # Development improvements
├── code_quality_report.md  # Code quality assessment
└── CLAUDE.md               # This file - development guide
```

## Architecture & Design Patterns

The plugin uses a simple, single-file architecture with clear functional separation:

### **Current Architecture (Single File)**

**plugin/zzvim-R.vim** contains all functionality organized into logical sections:

1. **Configuration Management**: Global variables and settings
2. **Core Functions**: Terminal management, R communication
3. **Generalized SendToR System**: Smart pattern detection and text extraction
4. **Chunk Navigation**: R Markdown chunk handling
5. **Object Inspection**: R object examination functions
6. **Key Mappings**: Context-aware key bindings

### **Key Design Principles**

1. **Pattern-Based Intelligence**: Automatic detection of R code structures
2. **Consistent Temp File Approach**: All code submission uses temporary files
3. **Context-Aware Behavior**: `<CR>` key adapts to cursor position
4. **Error Handling**: Robust position restoration and error messaging
5. **Backward Compatibility**: Preserves existing function behavior

## Core Function Groups

### **1. Generalized SendToR System**
- **`s:SendToR(selection_type)`**: Main dispatcher for all code submission
- **`s:GetTextByType(selection_type)`**: Smart text extraction with auto-detection
- **`s:IsBlockStart(line)`**: Pattern matching for code block detection
- **`s:GetCodeBlock()`**: Brace matching algorithm for complete blocks

### **2. Text Extraction Functions**
- **`s:GetVisualSelectionLines()`**: Extract visual selection as lines
- **`s:GetCurrentChunk()`**: Extract R Markdown chunk content
- **`s:GetPreviousChunks()`**: Collect all previous chunks (placeholder)

### **3. Terminal and Communication**
- **`s:OpenRTerminal()`**: Create and manage R terminal sessions
- **`s:Send_to_r(cmd, stay_on_line)`**: Send commands to R terminal
- **`s:SendControlKeys(key)`**: Send control sequences to terminal

### **4. Chunk Navigation**
- **`s:MoveNextChunk()`**: Navigate to next R Markdown chunk
- **`s:MovePrevChunk()`**: Navigate to previous R Markdown chunk
- **`s:SubmitChunk()`**: Execute current chunk (uses generalized system)

### **5. Object Inspection**
- **`s:RAction(action, stay_on_line)`**: Execute R functions on word under cursor
- **Built-in actions**: head, str, dim, print, names, length, glimpse, etc.

## Key Mappings System

The plugin provides an intelligent key mapping system with smart context detection:

### **Smart `<CR>` Behavior (Context-Aware)**

**Normal Mode**: `<CR>` calls `s:SmartSubmit()` which automatically detects:
- **Function definitions**: `my_func <- function(x) {` → sends entire function block
- **Control structures**: `if (condition) {`, `for (i in 1:10) {` → sends entire block
- **Regular lines**: `x <- 5` → sends current line only
- **Lines inside functions**: Individual line execution for debugging

**Visual Mode**: `<CR>` → sends visual selection to R

### **Core Operations**
- **`<LocalLeader>r`**: Open R terminal
- **`<CR>`**: Smart submission (context-aware)

### **Chunk Navigation**
- **`<LocalLeader>j`**: Next chunk
- **`<LocalLeader>k`**: Previous chunk
- **`<LocalLeader>l`**: Execute current chunk
- **`<LocalLeader>t`**: Execute all previous chunks

### **Object Inspection (Single-Letter)**
- **`<LocalLeader>h`**: head()
- **`<LocalLeader>s`**: str()
- **`<LocalLeader>d`**: dim()
- **`<LocalLeader>p`**: print()
- **`<LocalLeader>n`**: names()
- **`<LocalLeader>f`**: length()
- **`<LocalLeader>g`**: glimpse()
- **`<LocalLeader>b`**: dt (data.table print)
- **`<LocalLeader>u`**: tail()
- **`<LocalLeader>y`**: help()

### **Control Keys**
- **`<LocalLeader>q`**: Send Q to R (quit)
- **`<LocalLeader>c`**: Send Ctrl-C to R (interrupt)

### **Generalized Send Functions (Advanced)**
- **`<LocalLeader>sf`**: Force send function block
- **`<LocalLeader>sl`**: Force send current line only
- **`<LocalLeader>sa`**: Smart auto-detection (same as `<CR>`)

### **Other Operations**
- **`<LocalLeader>o`**: Add pipe operator (`%>%`) and new line

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

### Current Version (Generalized SendToR System)

Major architectural improvement implementing intelligent code detection:

1. **Generalized SendToR Function**: Created `s:SendToR(selection_type)` as unified dispatcher
2. **Smart Pattern Detection**: Implemented `s:IsBlockStart()` for automatic R code structure recognition
3. **Brace Matching Algorithm**: Added `s:GetCodeBlock()` for accurate code block extraction
4. **Context-Aware `<CR>` Key**: Enhanced `<CR>` to intelligently detect and send appropriate code units
5. **Unified Temp File Approach**: All code submission uses consistent temporary file method
6. **Backward Compatibility**: Existing functions updated to use new system while preserving behavior
7. **Additional Key Mappings**: Added `<LocalLeader>sf/sl/sa` for explicit control

**Key Benefits**:
- **Intelligent Workflow**: `<CR>` automatically detects functions, control structures, or individual lines
- **Character Limit Handling**: Temp file approach handles any code size consistently
- **Pattern-Based Detection**: Recognizes `function()`, `if()`, `for()`, `while()`, standalone `{}` blocks
- **Debugging Friendly**: Lines inside functions still execute individually
- **Extensible Architecture**: Easy to add new pattern detection

## Code Examples & Patterns

### Generalized SendToR Pattern

```vim
function! s:SendToR(selection_type, ...) abort
    " Get text lines based on selection type or smart detection
    let text_lines = s:GetTextByType(a:selection_type)
    
    if empty(text_lines)
        call s:Error("No text to send to R.")
        return
    endif
    
    " Always use temp file approach for consistency
    let temp_file = tempname()
    call writefile(text_lines, temp_file)
    let cmd = "source('" . temp_file . "', echo=T)\n"
    call s:Send_to_r(cmd, 0)
    
    " Provide feedback about what was sent
    let line_count = len(text_lines)
    echom "Sent " . line_count . " lines to R."
endfunction
```

### Smart Detection Pattern

```vim
function! s:IsBlockStart(line) abort
    " Remove leading/trailing whitespace
    let clean_line = substitute(a:line, '^\s\+\|\s\+$', '', 'g')
    
    " Check each pattern individually
    if clean_line =~# '.*function\s*('
        return 1
    endif
    if clean_line =~# '^\s*if\s*('
        return 1
    endif
    if clean_line =~# '^\s*for\s*('
        return 1
    endif
    " ... more patterns ...
    
    return 0
endfunction
```

### Brace Matching Algorithm

```vim
function! s:GetCodeBlock() abort
    let save_pos = getpos('.')
    let current_line_num = line('.')
    
    " Find the opening brace
    let brace_line = current_line_num
    let found_opening = 0
    
    while brace_line <= line('$')
        let line_content = getline(brace_line)
        if line_content =~ '{'
            let found_opening = 1
            break
        endif
        let brace_line += 1
        if brace_line > current_line_num + 5
            break
        endif
    endwhile
    
    " Find matching closing brace using brace counting
    let brace_count = 0
    let end_line = -1
    
    for line_num in range(brace_line, line('$'))
        let line_content = getline(line_num)
        let open_braces = len(substitute(line_content, '[^{]', '', 'g'))
        let close_braces = len(substitute(line_content, '[^}]', '', 'g'))
        let brace_count += open_braces - close_braces
        
        if brace_count == 0 && (open_braces > 0 || close_braces > 0)
            let end_line = line_num
            break
        endif
    endfor
    
    call setpos('.', save_pos)
    return getline(current_line_num, end_line)
endfunction
```

### Smart Submission Wrapper

```vim
function! s:SmartSubmit() abort
    " Use smart detection (empty string triggers auto-detection)
    call s:SendToR('')
endfunction
```

## Common Development Patterns

1. **Pattern-Based Detection**: Use regex patterns to identify R code structures
2. **Position Preservation**: Always save and restore cursor position in navigation functions
3. **Temp File Approach**: Use temporary files for all R code submission to handle size limits
4. **Error Handling**: Provide clear error messages and restore state on failure
5. **Brace Counting**: Use proper brace matching algorithms for nested structures
6. **Context Awareness**: Functions should adapt behavior based on cursor location
7. **Return Values**: Use integers (0/1) consistently for success/failure
8. **Script-Local Functions**: Keep internal functions private with `s:` prefix

## Key Issue Fixes

### Character Limit Issue Resolution

**Problem**: R terminals and Vim's terminal communication have character/line limits that caused issues with large functions or chunks.

**Solution**: Implemented unified temp file approach:
```vim
let temp_file = tempname()
call writefile(text_lines, temp_file)
let cmd = "source('" . temp_file . "', echo=T)\n"
call s:Send_to_r(cmd, 0)
```

**Benefits**:
- Works for any size selection
- Consistent behavior across all submission types
- No character limits
- R's `source()` with `echo=T` shows executed code

### Smart Code Detection Implementation

**Problem**: Users had to manually specify whether to send a line, function, or code block.

**Solution**: Implemented pattern-based detection system:

```vim
function! s:IsBlockStart(line) abort
    " Detects: function(), if(), for(), while(), repeat{}, {}
    if clean_line =~# '.*function\s*('
        return 1
    endif
    " ... more patterns
endfunction
```

**Key Benefits**:
- `<CR>` automatically detects context
- Function definitions → send entire function
- Control structures → send entire block  
- Regular lines → send individual line
- Lines inside functions → individual execution for debugging

### Brace Matching Algorithm

**Problem**: Accurately finding the end of R code blocks with nested braces.

**Solution**: Implemented robust brace counting:

```vim
let brace_count = 0
for line_num in range(brace_line, line('$'))
    let open_braces = len(substitute(line_content, '[^{]', '', 'g'))
    let close_braces = len(substitute(line_content, '[^}]', '', 'g'))
    let brace_count += open_braces - close_braces
    
    if brace_count == 0 && (open_braces > 0 || close_braces > 0)
        let end_line = line_num
        break
    endif
endfor
```

**Handles**:
- Nested functions and control structures
- Multiple braces on same line
- Complex R code patterns

## Vim-Specific Implementation Notes

1. **Single File Architecture**: All functionality contained in plugin/zzvim-R.vim
2. **Script-Local Functions**: Functions prefixed with `s:` are only accessible within their script
3. **Terminal Management**: Uses Vim's built-in terminal features
4. **Variable Scoping**:
   - `g:` Global variables (configuration)
   - `s:` Script-local variables
   - `l:` Function-local variables
   - `a:` Function argument variables
5. **Pattern Matching**: Uses Vim's regex engine with `=~#` for case-sensitive matching
6. **Position Management**: Uses `getpos()` and `setpos()` for cursor position handling
7. **Key Mapping**: Uses autocmd with FileType to create filetype-specific mappings

## Working with the Current Codebase

When modifying this plugin:

1. **Test Files**: Use test_files/ for testing changes, especially:
   - `test_generalized_send.R` - Test smart detection patterns
   - `new_functionality_demo.R` - Demo various use cases
2. **Pattern Testing**: Test new patterns in `s:IsBlockStart()` thoroughly
3. **Position Preservation**: Always save/restore cursor position in navigation functions
4. **Temp File Approach**: Maintain consistency with temp file method for R submission
5. **Error Handling**: Include proper error messages and state restoration
6. **Documentation**: Update CLAUDE.md when adding significant functionality

## Testing Process

Focus on these key areas when testing:

1. **Smart Detection**: Test pattern recognition on various R code structures
2. **Brace Matching**: Verify correct code block extraction with nested structures  
3. **Context Awareness**: Test `<CR>` behavior in different cursor positions
4. **Terminal Integration**: Verify R terminal creation and code submission
5. **Chunk Navigation**: Test R Markdown chunk handling
6. **Error Scenarios**: Test behavior with malformed code and missing braces
7. **File Type Support**: Test with R, RMD, QMD files

## Current Capabilities & Limitations

### **What Works Well**
- Smart detection of function definitions and control structures
- Accurate brace matching for nested code blocks
- Consistent temp file approach handles any code size
- Context-aware `<CR>` key behavior
- Backward compatibility with existing workflows

### **Current Limitations**
- Pattern detection limited to common R structures
- `s:GetPreviousChunks()` function not fully implemented
- No advanced R parsing (uses regex patterns only)
- Limited to basic R terminal interaction
- No package management, data operations, or help functions

### **Security Notes**
- Plugin executes R code directly through terminal
- Temp files created in system temp directory
- No input sanitization beyond basic error checking
- Relies on Vim's built-in security model