# zzvim-R Plugin Development

This document describes the development and improvements made to the zzvim-R plugin with Claude's assistance.

## Version 2.3 Changes

The plugin has been substantially improved and upgraded to version 2.3 with the following enhancements:

1. **Fixed R Markdown Chunk Navigation**: Rewrote the navigation functions to correctly handle chunk navigation
2. **Eliminated Key Mapping Conflicts**: Changed two-letter mappings that conflicted with single-letter mappings
3. **Comprehensive Documentation**: Updated all documentation to reflect the new mapping scheme
4. **Improved User Experience**: Made navigating between R code chunks more reliable and consistent

## Navigation Function Fixes

### Previous Chunk Navigation Issue

The `zzvim_r#navigate_prev_chunk()` function had severe issues that caused it to not work properly:

```vim
# Original problematic implementation
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

The key issues were:
1. It was using pattern strings as line numbers with `setpos()`
2. It wasn't actually searching for the patterns
3. It didn't correctly handle being inside a chunk

### Fixed Implementation

```vim
function! zzvim_r#navigate_prev_chunk() abort
    " Get patterns for R code chunks from plugin config
    let l:chunk_start_pattern = get(g:, 'zzvim_r_chunk_start', '^```{[rR]')
    
    " Save current position
    let l:current_pos = getpos('.')
    let l:current_line_num = line('.')
    
    " First, find the current chunk we might be in
    let l:current_chunk_start = search(l:chunk_start_pattern, 'bcnW')
    
    " If we're inside or at the start of the current chunk,
    " we need to move before this chunk to find the previous one
    if l:current_chunk_start > 0
        " If we're not at the chunk start itself, go to it first
        if l:current_line_num > l:current_chunk_start
            call cursor(l:current_chunk_start, 1)
        endif
        
        " Now go one line above the current chunk start to search
        if l:current_chunk_start > 1
            call cursor(l:current_chunk_start - 1, 1)
        endif
    endif
    
    " Now search for the previous chunk
    let l:prev_chunk_start = search(l:chunk_start_pattern, 'bW')
    
    if l:prev_chunk_start > 0
        " Move inside the chunk (to the line after the chunk header)
        call cursor(l:prev_chunk_start + 1, 1)
        normal! zz
        echom "Moved to previous chunk at line " . line('.')
        return 1
    else
        " No previous chunk found, restore position
        call setpos('.', l:current_pos)
        echom "No previous chunk found"
        return 0
    endif
endfunction
```

The next chunk navigation function was also improved for consistency.

## Key Mapping Conflict Resolution

The plugin originally had conflicts between single-letter mappings and two-letter mappings that shared the same first letter. For example, `<LocalLeader>h` (head) conflicted with `<LocalLeader>he` (help examples).

### Changed Mappings

To resolve these conflicts, the following mappings were changed:

1. **Package Management**:
   - `<LocalLeader>pi` → `<LocalLeader>xi` (install package)
   - `<LocalLeader>pl` → `<LocalLeader>xl` (load package)
   - `<LocalLeader>pu` → `<LocalLeader>xu` (update package)

2. **Data Operations**:
   - `<LocalLeader>dr` → `<LocalLeader>zr` (read CSV)
   - `<LocalLeader>dw` → `<LocalLeader>zw` (write CSV)
   - `<LocalLeader>dl` → `<LocalLeader>zl` (load RDS)
   - `<LocalLeader>ds` → `<LocalLeader>zs` (save RDS)

3. **Directory Management**:
   - `<LocalLeader>pd` → `<LocalLeader>vd` (print directory)
   - `<LocalLeader>cd` → `<LocalLeader>vc` (change directory)
   - `<LocalLeader>ld` → `<LocalLeader>vl` (list directory)
   - `<LocalLeader>hd` → `<LocalLeader>vh` (home directory)

4. **Help Functions**:
   - `<LocalLeader>he` → `<LocalLeader>ue` (help examples)
   - `<LocalLeader>ha` → `<LocalLeader>ua` (apropos help)
   - `<LocalLeader>hf` → `<LocalLeader>uf` (find definition)

This changes eliminated all conflicts with the single-letter mappings:
- `<LocalLeader>h` (head)
- `<LocalLeader>p` (print)
- `<LocalLeader>d` (dim)

## Documentation Updates

All documentation files were updated to reflect these changes:
- `doc/zzvim-R.txt`: Help documentation
- `README.md`: User readme
- `CHANGELOG.md`: Version history with new entry for 2.3.0

## Tips for Vim Plugin Development

1. **Navigation Functions**: When implementing navigation commands:
   - Always save the current position before moving
   - Use proper search flags (`W` for forward, `bW` for backward)
   - Consider the context (e.g., already being in a chunk)
   - Restore the position if the search fails

2. **Key Mapping Conflicts**: When designing key mappings:
   - Avoid using the same first letter for single and multi-letter mappings
   - Choose intuitive prefixes for related functionality (x for package, z for data, etc.)
   - Document all mappings clearly in help files

3. **VimScript Patterns**:
   - Use `cursor()` instead of `setpos()` for simple line/column positioning
   - Remember to use proper flags in search functions:
     - `b` for backward search
     - `c` to accept current position
     - `n` to not move the cursor
     - `W` to not wrap around the end of the file
   - Save and restore cursor position when appropriate

4. **Testing Strategy**:
   - Test with a variety of document structures
   - Check edge cases like being at the start/end of file
   - Verify behavior when inside, at the start, and after a chunk

These improvements make the zzvim-R plugin more robust and user-friendly, especially for working with R Markdown documents.

## Version 1.1 Development - Object Browser Implementation (August 16, 2025)

### Major Feature Addition: vim-peekaboo Style Object Browser

A significant new feature has been implemented following the architectural patterns of vim-peekaboo to provide R workspace inspection capabilities.

#### **Feature Overview**

The object browser provides an intuitive, vim-peekaboo inspired interface for R workspace exploration:

- **Key Mapping**: `<LocalLeader>"` (follows vim-peekaboo's `"` pattern)
- **Interface**: Right-side vertical split panel (40 columns)
- **Navigation**: Number keys 1-9 for quick inspection, ESC/q to close
- **Integration**: Works seamlessly with existing multi-terminal architecture

#### **Implementation Architecture**

**Core Functions:**

1. **`s:RObjectBrowser()`** - Main browser window creation and management
   - Creates vim-peekaboo style temporary buffer on right side
   - Configures buffer as scratch with appropriate local settings
   - Sets up buffer-local key mappings for navigation
   - Integrates with existing error handling and terminal validation

2. **`s:PopulateObjectList()`** - R workspace querying with detailed object information
   - Uses temporary file approach for reliable R communication
   - Generates comprehensive object listings with types and dimensions
   - Formats output: `1. object_name (type dimensions)` for clarity
   - Handles empty workspace gracefully with informative messages

3. **`s:InspectObjectAtCursor()`** - Detailed object examination with adaptive display
   - Extracts object names using regex pattern matching
   - Provides context-aware inspection based on object type:
     - Data frames: structure + head() preview
     - Long vectors: first/last 10 elements  
     - Models: summary statistics
     - Lists: nested structure display
   - Uses ESC key to return to object list (dual-mode navigation)

4. **`s:InspectObjectByNumber()`** - Quick numeric key navigation
   - Enables vim-peekaboo style number key shortcuts (1-9)
   - Provides immediate object inspection without cursor movement
   - Maintains intuitive workflow for rapid object exploration

#### **User Experience Design**

**vim-peekaboo Pattern Adherence:**
- **Trigger Key**: `"` for registers → `<LocalLeader>"` for R objects
- **Window Behavior**: Right-side temporary split with identical positioning
- **Navigation**: ESC for close/return, q for full exit
- **Visual Design**: Clean numbered list with clear instructions

**Interactive Workflow:**
```
1. Press <LocalLeader>" → Browser opens with object list
2. Press number 1-9 → Quick inspect specific objects  
3. Use <CR> → Inspect object at cursor position
4. Press ESC → Return to object list (from detail view)
5. Press q → Close browser entirely
```

#### **Technical Implementation Details**

**VimScript Best Practices:**
- **Buffer Management**: Proper scratch buffer configuration with `buftype=nofile`
- **Key Mapping Isolation**: Buffer-local mappings prevent conflicts
- **Error Handling**: Comprehensive validation for missing terminals/objects
- **Position Management**: Saves and restores window state appropriately

**R Communication Protocol:**
- **Temp File Approach**: Consistent with existing plugin architecture
- **Capture Output**: Uses `capture.output()` for reliable data retrieval
- **Smart Timing**: Appropriate delays for R command execution
- **Object Introspection**: Leverages R's class(), dim(), length() for metadata

**Performance Considerations:**
- **Lazy Loading**: Objects queried only when browser opened
- **Efficient Regex**: Optimized pattern matching for object parsing
- **Memory Management**: Temporary files properly cleaned up
- **Search Limits**: Bounded operations to prevent hangs

#### **Documentation Integration**

**Key Mapping Documentation Added:**
```vim
"   <LocalLeader>"    - Object Browser - vim-peekaboo style R workspace browser
"                      Opens right-side panel showing all R objects with types
"                      Number keys 1-9: quick inspect, ESC/q: close browser
```

**Ex Command Reference Added:**
```vim
" Object Browser:
" --------------
"     :RObjectBrowser          - Open vim-peekaboo style R object browser
"                               Right panel showing workspace objects with types
"                               Navigation: 1-9 keys inspect, ESC/q close
```

#### **Development Process & Quality Assurance**

**Feature Branch Strategy:**
- Implemented in isolated `feature/object-browser` branch
- Complete rollback capability preserving master branch stability
- Comprehensive testing framework with multiple test files
- Safe merge strategy allows thorough validation before production

**Testing Infrastructure:**
- **`test_object_browser_demo.R`**: Comprehensive object creation for testing various R types
- **`TESTING_CHECKLIST.md`**: Systematic validation process covering all functionality
- **Integration Tests**: Verified compatibility with existing multi-terminal features
- **Performance Tests**: Validated behavior with large workspaces and complex objects

**Code Quality:**
- **Inline Documentation**: Extensive comments explaining object browser architecture
- **Error Handling**: Robust validation with clear user feedback
- **VimScript Standards**: Follows established plugin conventions and patterns
- **Educational Value**: Implementation serves as example of advanced Vim plugin development

#### **Strategic Impact**

**Competitive Positioning:**
- **Addresses IDE Gap**: Provides modern workspace inspection comparable to RStudio/VS Code
- **Maintains Performance**: Lightweight implementation preserving zzvim-R's speed advantage
- **Extends vim-peekaboo Pattern**: Leverages proven UI paradigm for R development
- **Enhances Workflow**: Reduces context switching between code and object inspection

**User Experience Enhancement:**
- **Visual Object Management**: Clear overview of workspace state during analysis
- **Rapid Iteration**: Quick object inspection enables faster exploratory data analysis
- **Contextual Information**: Type and dimension display aids in debugging and development
- **Intuitive Navigation**: Familiar vim-peekaboo patterns reduce learning curve

#### **Implementation Lessons**

**VimScript Architecture Patterns:**
1. **Temporary Buffer Management**: Proper scratch buffer configuration for tool windows
2. **Buffer-Local Mappings**: Isolated key mappings prevent global conflicts
3. **R Communication**: Temp file approach scales better than direct terminal injection
4. **Error Recovery**: Graceful degradation with helpful error messages

**vim-peekaboo Study Benefits:**
- **Proven UI Patterns**: Established interaction model reduces implementation risk
- **Window Management**: Effective temporary split window techniques
- **Key Mapping Design**: Intuitive navigation following Vim conventions
- **Buffer Lifecycle**: Proper temporary buffer creation and cleanup

**Feature Development Process:**
- **Incremental Implementation**: Core functionality first, polish second
- **Comprehensive Testing**: Multiple test files covering various scenarios
- **Documentation Integration**: Help system updates concurrent with implementation
- **Safe Deployment**: Feature branch isolation enables confident experimentation

#### **Future Enhancement Opportunities**

**Potential Additions:**
- **Object Filtering**: Search/filter objects by name pattern or type
- **Sort Options**: Alphabetical, size, type, or creation time ordering
- **Batch Operations**: Select multiple objects for combined actions
- **Visual Enhancements**: Syntax highlighting and improved formatting
- **Export Functionality**: Save object summaries to files

**Architecture Extensions:**
- **Plugin System**: Object browser as template for other tool windows
- **Context Awareness**: Smart object suggestions based on current code context
- **Integration Hooks**: API for other plugins to extend object browser functionality

The object browser represents a significant evolution in zzvim-R's capabilities, bringing modern IDE functionality to Vim while maintaining the plugin's core philosophy of lightweight, terminal-based R development. The implementation demonstrates advanced VimScript techniques and provides a foundation for future enhancements.

## January 2026 - Plot System & HUD Improvements

### Plot System Refactoring (Template v8)

Major simplification of the plot system:

- **Architecture**: PDF master + PNG preview (replaces dual-resolution PNG)
  - PDF: Vector format, infinite zoom, publication-ready
  - PNG: 900x675 raster for kitty pane display (150 dpi)
- **Code Reduction**: Plot section reduced from 1629 to 312 lines (81%)
- **Function Renaming**: `zzplot()` → `show()`, all related functions to `show_*` pattern

### Plot HUD Implementation

New Plot HUD integrated with the HUD system:

- **Command**: `:RPlotHUD` or `<LocalLeader>P`
- **Features**: Plot history navigation, zoom to PDF, save, delete
- **Dashboard Integration**: 6th tab in `:RHUDDashboard`
- **Auto-refresh**: Updates when new plots are created

### Preview.app Integration (macOS)

- Auto-close previous plot PDFs before opening new ones
- Force Preview.app (not default PDF viewer)
- 200% zoom via AppleScript automation

### Plot Display Improvements

- Centered plots in kitty pane (horizontal + vertical padding)
- Increased PNG size from 100 to 150 dpi
- Plot pane closes on Vim exit (`VimLeavePre` autocmd)
- Suppressed "Press ENTER" prompts (changed `echom` to `redraw | echo`)

### Critical Bug Fix: Plot HUD Path Resolution

**Problem**: Plots selected from HUD were not displaying (PNG or PDF).

**Root Cause**: All Plot HUD functions used `s:GetHistoryDir()` which relies on
`getcwd()`. When the HUD was opened from Dashboard or after changing directories,
`getcwd()` might not point to the R project directory where `.plots` exists.

**Solution**: Store paths as buffer-local variables when HUD is created:

```vim
" In s:RPlotHUD() - store paths before creating new buffer
let l:plots_dir = s:GetPlotsDir()
let l:history_dir = s:GetHistoryDir()
" ... create buffer ...
let b:plots_dir = l:plots_dir
let b:history_dir = l:history_dir

" In PlotHUDSelectNum() - use buffer-local paths
let l:hist_dir = get(b:, 'history_dir', s:GetHistoryDir())
let l:plots_dir = get(b:, 'plots_dir', s:GetPlotsDir())
```

**Functions Updated**:
- `s:RPlotHUD()` - stores paths before buffer creation
- `s:RHUDDashboard()` - captures paths before creating tabs
- `s:CreateHUDTab()` - accepts optional path args for Plots tab
- `s:PlotHUDSelectNum()` - uses buffer-local paths
- `s:PlotHUDZoom()` - uses buffer-local paths
- `s:PlotHUDSave()` - uses buffer-local paths
- `s:PlotHUDDelete()` - uses buffer-local paths
- `s:PlotHUDRefresh()` - uses buffer-local paths
- `s:GeneratePlotHUD()` - stores paths if not already set

### Template Version Checking

Added version checking for `.Rprofile.local`:

- Plugin stores `s:template_version = 8`
- On R file open, compares local vs template version
- Prompts user when local copy is outdated

### Other Fixes

- **E117 OnRActivity**: Removed orphaned function call
- **file.copy() error**: Fixed `parent.frame()` scoping in `show()` function
- **Plot HUD Enter key in Dashboard**: Excluded Plots tab from generic HUD mappings
- **Cursor jumping**: Save/restore cursor position in `GeneratePlotHUDContent()`