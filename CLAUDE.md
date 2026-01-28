# zzvim-R Plugin Architecture & Development Guide

This document provides comprehensive information about the zzvim-R plugin, its current architecture, functionality, development history, and key code patterns to help Claude understand and work with this codebase effectively.

## Document Status

**Last Updated**: January 28, 2026
**Plugin Version**: 1.0
**Documentation Status**: Comprehensive accuracy review completed
**Test Coverage**: Full test suite + clean execution validation with automated CI workflows
**Release Readiness**: Production ready with clean terminal output and professional UX

### Key Features
- **Code Execution**: Pattern-based detection with non-interactive execution
- **Multi-Terminal Management**: Buffer-specific R terminal sessions
- **Terminal Selection**: Automatic detection with user prompting
- **Docker Container Support**: Full container integration
- **Window Management**: Flexible split windows (vertical/horizontal)
- **Chunk Navigation**: R Markdown code chunk traversal
- **Pattern Recognition**: Brace {} and parenthesis () matching
- **Code Execution Output**: Clean terminal output (no clutter)
- **Object Inspection**: R workspace browsing and examination
- **Key Mappings**: Context-aware `<CR>` behavior
- **Kitty Plot Display**: Automatic plot display in dedicated kitty terminal pane

## Project Structure

```
zzvim-R/
├── plugin/
│   └── zzvim-R.vim         # All plugin functionality
├── doc/
│   └── zzvim-R.txt         # Vim help documentation
├── test_files/             # Test files and examples
├── .github/workflows/      # GitHub Actions CI/CD
├── CHANGELOG.md            # Version history & detailed session notes
├── LICENSE, README.md      # User documentation
├── docs/                   # Comparison documentation
└── CLAUDE.md               # This file - development guide
```

## Architecture & Design Patterns

**Single-File Architecture**: `plugin/zzvim-R.vim` contains all functionality organized into logical sections:

1. **Configuration Management**: Global variables and settings
2. **Core Functions**: Terminal management, R communication
3. **Generalized SendToR System**: Smart pattern detection
4. **Chunk Navigation**: R Markdown chunk handling
5. **Object Inspection**: R object examination
6. **Key Mappings**: Context-aware key bindings

### Key Design Principles

1. **Pattern-Based Detection**: Automatic detection of R code structures
2. **Consistent Temp File Approach**: All code submission uses temporary files
3. **Context-Aware Behavior**: `<CR>` key adapts to cursor position
4. **Error Handling**: Robust position restoration and error messaging
5. **Backward Compatibility**: Preserves existing function behavior

## Core Function Groups

### 1. Generalized SendToR System
- `s:SendToR(selection_type)`: Main dispatcher for all code submission
- `s:GetTextByType(selection_type)`: Smart text extraction with auto-detection
- `s:IsBlockStart(line)`: Pattern matching for code block detection
- `s:GetCodeBlock()`: Brace matching algorithm for complete blocks

### 2. Text Extraction Functions
- `s:GetVisualSelectionLines()`: Extract visual selection as lines
- `s:GetCurrentChunk()`: Extract R Markdown chunk content
- `s:GetPreviousChunks()`: Collect all previous chunks

### 3. Multi-Terminal Management
- `s:GetTerminalName()`: Generate unique terminal names
- `s:GetAllTerminals()`: Detect all existing terminal buffers
- `s:PromptTerminalSelection()`: Interactive prompt for terminal selection
- `s:GetBufferTerminal()`: Find or create buffer-specific terminal
- `s:OpenRTerminal()`: Create and manage R terminal sessions
- `s:Send_to_r(cmd, stay_on_line)`: Send commands to buffer-specific terminal

### 4. Terminal Association Visibility
- `s:RShowTerminalCommand()`: Display current buffer's terminal association
- `s:RListTerminalsCommand()`: List all R file ↔ terminal associations
- `s:RSwitchToTerminalCommand()`: Switch to buffer-specific terminal window

### 5. Chunk Navigation
- `s:MoveNextChunk()`: Navigate to next R Markdown chunk
- `s:MovePrevChunk()`: Navigate to previous R Markdown chunk
- `s:SubmitChunk()`: Execute current chunk

### 6. Pattern Recognition & Cursor Management
- `s:IsIncompleteStatement()`: Detect continuation lines
- `s:IsInsideFunction()`: Function boundary detection
- `s:MoveCursorAfterSubmission()`: Cursor positioning after submission
- `s:GetCodeBlock()`: Brace/parenthesis matching

### 7. Object Inspection
- `s:RAction(action, stay_on_line)`: Execute R functions on word at cursor
- Built-in actions: head, str, dim, print, names, length, glimpse, etc.

## Key Mappings System

### Context-Aware `<CR>` Behavior

- **Function definitions**: Sends entire function block
- **Control structures**: Sends entire if/for/while block
- **Regular lines**: Sends current line only
- **Visual Mode**: Sends visual selection

### R Terminal Launch
- `<LocalLeader>r` or `ZR`: Container R (via `make r`, with renv)
- `<LocalLeader>rr`: Host R with renv (normal startup)
- `<LocalLeader>rh`: Host R without renv (vanilla mode)
- `<LocalLeader>w`: Open R terminal in vertical split
- `<LocalLeader>W`: Open R terminal in horizontal split
- `<CR>`: Smart submission (context-aware)

### Chunk Navigation
- `<LocalLeader>j`: Next chunk
- `<LocalLeader>k`: Previous chunk
- `<LocalLeader>l`: Execute current chunk
- `<LocalLeader>t`: Execute all previous chunks

### Object Inspection
- `<LocalLeader>h`: head()
- `<LocalLeader>s`: str()
- `<LocalLeader>d`: dim()
- `<LocalLeader>p`: print()
- `<LocalLeader>n`: names()
- `<LocalLeader>f`: length()
- `<LocalLeader>g`: glimpse()
- `<LocalLeader>b`: data.table print
- `<LocalLeader>u`: tail()
- `<LocalLeader>y`: help()

### Plot Display (Kitty Terminal)
- `<LocalLeader>[`: Open current plot in macOS Preview
- `<LocalLeader>]`: Open hi-res plot in new Kitty window (zoom)

### Control Keys
- `<LocalLeader>q`: Quit R session
- `<LocalLeader>c`: Interrupt R session (Ctrl-C)

### Generalized Send Functions
- `<LocalLeader>sf`: Force send function block
- `<LocalLeader>sl`: Force send current line only
- `<LocalLeader>sa`: Auto-detection

## Development History Summary

**Version Timeline**: 1.0 → 2.3 → 3.0 (current)

### Major Milestones

**Aug 2025 - Foundation**
- v1.0: Generalized SendToR system with pattern-based detection
- v2.3.0-2.3.2: Fixed chunk navigation and key mapping conflicts
- v3.0.0: API streamlining

**Sep 2025 - IDE Enhancement**
- SendToRWithComments: Code documentation feature
- HUD Functions: Workspace overview dashboard
- LSP Integration: Cross-platform Vim/Neovim support

**Oct-Nov 2025 - Advanced Features**
- Terminal Selection: Auto-detection with user prompting
- Docker Integration: Container support with force-association
- Clean Execution: Optimized output display

**Dec 2025 - Polish & Optimization**
- Temp File Strategy: Improved reliability with validation
- Competitive Analysis: Honest research-focused comparisons

**Jan 2026 - Kitty Plot Display & Dual Resolution**
- Docker Plot Watcher: Signal-based detection with adaptive polling (100ms active, 1s idle)
- Kitty Terminal Integration: Display plots in dedicated pane using `kitty +kitten icat`
- Plot Pane Management: Auto-creates pane to the right of R terminal using splits layout
- Pre-warmed Pane: Updates image in-place instead of recreating (faster refresh)
- Plot Commands: `:RPlotShow`, `:RPlotPreview`, `:RPlotZoom`, `:RPlotZoomPreview`, `:RPlotGallery`
- Key Mappings:
  - `<LocalLeader>[` opens current plot in Preview
  - `<LocalLeader>]` opens hi-res plot in new Kitty window
- VimResized Autocmd: Auto-equalizes vim window splits when kitty pane changes
- Plot Cleanup: Auto-closes plot pane when R terminal exits (TermClose event)
- Race Condition Prevention: Lock mechanism prevents duplicate plot panes
- **Dual-Resolution Plots**: `zzplot()`/`zzggplot()` render both sizes:
  - Small (600x450): Displayed in pane, crisp without scaling
  - Large (1800x1350): Used for zoom/export, 3x detail
- **Persistent History**: Plots saved to `.plots/history/` with thumbnails
  - `plot_goto(name_or_id)`: Navigate to specific plot
  - `plot_search(pattern)`: Search plots by name or code
  - `plot_history_persistent()`: List all saved plots
  - `:RPlotGallery`: Vim buffer with plot gallery navigation
- **Statusline Integration**: `ZzvimRPlotStatus()` function for statusline
- **Unified Configuration**: `.plots/.config.json` shared between Vim and R
  - `:RPlotConfig`: Show current configuration
  - `:RPlotSize 800 600`: Set plot dimensions (large = 3x small)
  - `g:zzvim_r_plot_*` variables for customization
  - R reads config on startup via `.read_vim_config()`
- Template Versioning: Auto-detects outdated `.Rprofile.local`, prompts to update with backup
- `ZR` mapping: Quick access to Docker R terminal (same as `<LocalLeader>r`)
- Comprehensive vignette: `docs/plot-display-vignette.md` documents all plot features

### Key Technical Achievements
- Clean execution system (source command elimination)
- Multi-terminal workflow isolation
- Robust error handling and position restoration
- Comprehensive LSP/formatting support
- Docker container compatibility

### Note on Detailed Session Documentation

**Comprehensive session notes from August through December 2025** are documented in `CHANGELOG.md` with detailed explanations of:
- Implementation architecture for each feature
- Technical problem resolution
- Performance optimizations
- Testing verification
- User experience impact

See CHANGELOG.md for complete historical documentation of feature development.

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

## Common Development Patterns

1. **Pattern-Based Detection**: Use regex patterns to identify R code structures
2. **Position Preservation**: Always save and restore cursor position in navigation functions
3. **Temp File Approach**: Use temporary files for all R code submission
4. **Error Handling**: Provide clear error messages and restore state on failure
5. **Brace Counting**: Use proper brace matching for nested structures
6. **Context Awareness**: Functions should adapt behavior based on cursor location

## Current Capabilities & Limitations

### ✅ Core Functionality (Production Ready)
- **Smart Code Detection**: Automatic recognition of R functions, control structures, and code blocks
- **Intelligent Submission**: Context-aware `<CR>` key determines optimal code boundaries
- **Multi-Terminal Architecture**: Buffer-specific R terminal sessions with complete workflow isolation
- **Advanced Window Management**: Flexible split window terminals (vertical/horizontal)
- **Terminal Association Visibility**: Commands to view and manage R file ↔ terminal associations
- **Enhanced Pattern Recognition**: Balanced character counting for nested structures and operators
- **Reliable Transmission**: Temp file approach with unlimited code size
- **Chunk Navigation**: Complete R Markdown/Quarto chunk traversal
- **Object Inspection**: Full suite of R data analysis functions
- **Error Handling**: Comprehensive validation and graceful failure recovery

### ✅ Advanced Features (Fully Implemented)
- **30+ Ex Commands**: Complete command-line interface with tab completion
- **Educational Documentation**: 400+ inline comments for VimScript learning
- **Comprehensive Test Suite**: Testing framework with multi-terminal validation
- **Flexible Configuration System**: Extensive customization with safe defaults
- **Cross-Platform**: Linux, macOS, Windows compatibility verified
- **Version Compatibility**: Vim 8.0+ and Neovim support

### ✅ Quality Assurance (Production Grade)
- **Test Coverage**: 24/24 Ex commands verified, pattern matching validated
- **GitHub CI/CD**: Automated testing across multiple platforms
- **VimScript Linting**: Automated code quality checks
- **Cross-Platform Validation**: R dependency verification
- **Performance**: Optimized algorithms with search limits
- **Security**: Safe temp file handling within Vim's security model

### Known Limitations (Design Choices)
- **Pattern-Based Parsing**: Uses regex rather than full R parser (intentional for simplicity)
- **Basic R Integration**: Focuses on core workflow rather than comprehensive IDE features
- **File-Based Communication**: Temp files rather than direct terminal injection (for reliability)

## Future Development Roadmap

### Potential Enhancements (Post-1.0)
- **Enhanced Pattern Detection**: Support for additional R constructs (S4 classes, R6 objects)
- **Multiple Terminal Support**: Multiple R sessions with session switching
- **Package Integration**: Built-in package management
- **Debugging Integration**: R debugger integration with breakpoint support
- **LSP Integration**: Language Server Protocol support for advanced IDE features
- **Performance Monitoring**: Code profiling and performance analysis tools

### Community Contributions Welcome
- **Additional Patterns**: New R language construct recognition
- **Platform Testing**: Extended compatibility validation
- **Documentation**: Additional examples and use cases
- **Integration**: Compatibility with other Vim plugins

## Important Development Notes

### Working with the Current Codebase

**Key Principles**:
- Always use pattern-based detection with fallback to simpler approaches
- Test changes with multi-terminal workflows
- Preserve backward compatibility with existing configurations
- Validate temp file handling works in both local and Docker environments

### Testing Process

1. **Unit Testing**: Test individual functions with various input patterns
2. **Integration Testing**: Test multi-terminal workflows across R Markdown and regular R files
3. **Cross-Platform**: Verify on Linux, macOS, and in Docker containers
4. **Edge Cases**: Handle empty files, malformed code, and extreme nesting levels

### Key Issue Fixes Reference

See `CHANGELOG.md` for detailed resolution of:
- Character limit issues
- Smart code detection implementation
- Brace matching algorithm refinements
- Quote escaping handling
- Backtick function reference detection
- R Markdown chunk execution fixes
- Docker container integration
- Terminal selection improvements

## Performance Considerations

- **Brace Matching**: Limited search depth to prevent hangs on malformed code
- **Terminal Detection**: Caches terminal list to reduce repeated queries
- **Pattern Matching**: Uses efficient regex with early termination
- **Temp Files**: Automatic cleanup to prevent disk accumulation

## Configuration Variables

```vim
" Terminal sizing
let g:zzvim_r_terminal_width = 100      " Vertical split width
let g:zzvim_r_terminal_height = 15      " Horizontal split height

" Functionality
let g:zzvim_r_disable_mappings = 0      " Master switch for key mappings
let g:zzvim_r_command = 'R'             " R startup command

" Project detection
let g:zzvim_r_project_root = ''         " Override automatic detection
```

## Security Model

- **Code Execution**: Plugin executes user-written R code (expected behavior)
- **Temp Files**: Created in system temp directory with appropriate permissions
- **Input Validation**: Basic sanitization with comprehensive error checking
- **Vim Security**: Relies on Vim's built-in plugin security framework
- **No External Dependencies**: Pure VimScript implementation

## Key References

- **User Guide**: See `README.md` for end-user documentation
- **Help System**: Vim `:help zzvim-r` for complete reference
- **Comparison Docs**: `docs/` directory for honest comparisons with R.nvim and RStudio
- **Session History**: `CHANGELOG.md` for comprehensive development history
- **Testing**: `test_files/` directory for test cases and examples
