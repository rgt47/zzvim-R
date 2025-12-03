
# Changelog

All notable changes to the zzvim-R plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-03

### Release Information
Initial stable release (1.0.0) of zzvim-R.

### Added
- **Robust Temp File Strategy**:
  - Unique timestamp-based filenames preventing collision conflicts
  - R-side cleanup via `unlink()` after code execution
  - Docker-compatible relative path handling
  - Project root detection with priority-based marker checking
  - Writability validation before file operations

### Changed
- Repository cleanup: Removed development artifacts from tracking
- Consistent versioning across plugin and documentation
- Organized test files in dedicated `test_files/` directory

### Quality Assurance
- Repository structure organized for distribution
- Test suite passing on Vim/Neovim platforms (Ubuntu, macOS)
- Documentation includes README, help file, and contributing guide

### Features
- 50 Ex commands for R operations
- 59 key mappings for common operations
- Multi-terminal support with buffer-specific sessions
- Docker container support
- Workspace display functions (5 tab views)
- R Markdown/Quarto chunk navigation and execution
- Object inspection functions (head, str, dim, names, etc.)
- Code execution with pattern-based detection

## [1.1.0] - 2025-09-06

### Added
- **Workspace Display System**: Tabbed display of workspace information
  - `<LocalLeader>0` - Open all 5 workspace tabs
  - Memory Usage display (`<LocalLeader>m`) - Object memory consumption
  - Data Frames display (`<LocalLeader>e`) - Data frame listing with dimensions
  - Package Status display (`<LocalLeader>z`) - Loaded packages
  - Environment Variables display (`<LocalLeader>x`) - Environment variable listing
  - R Options display (`<LocalLeader>a`) - R session options
- **Data Frame Display**: Formatted display of data frame contents (`<LocalLeader>v`)
  - Display integration with Tabularize/EasyAlign
  - Cross-platform file handling
  - Read-only buffer configuration

### Technical Changes
- Workspace display implemented as temporary tabbed buffers
- Display update function callable from normal mode
- Support for Tabularize or EasyAlign formatting plugins
- Automatic temporary file cleanup
- R terminal discovery and association functionality

### Documentation
- Complete help system integration with detailed command reference
- Comprehensive README updates with usage examples and navigation guide
- Updated key mappings documentation with HUD function categorization

## [1.0.1] - 2025-08-12

### Added
- Inline documentation with explanatory comments (300+)
- Function headers with parameter and return value descriptions
- Pattern detection algorithm documentation
- Brace matching algorithm documentation
- Configuration system documentation
- Key mappings reference
- Ex commands reference

### Changed
- Enhanced error handling with explanatory messages
- Improved code organization with inline comments
- Updated documentation structure

### Maintenance
- Core algorithms documented with step-by-step explanations
- VimScript patterns explained throughout codebase
- Backward compatibility maintained

## [1.0.0] - 2025-08-12

### Added
- Generalized SendToR system with intelligent code detection
- Smart pattern recognition for R language constructs
- Sophisticated brace matching algorithm for nested structures
- Context-aware `<CR>` key behavior
- Unified temporary file approach for reliable code transmission
- Complete R Markdown/Quarto chunk navigation system
- 24 Ex commands with comprehensive functionality
- Object inspection suite (head, str, dim, print, names, etc.)
- Visual selection support with precise boundary handling
- Robust error handling and recovery mechanisms
- Comprehensive test suite with 40+ test assertions
- Cross-platform compatibility (Linux, macOS, Windows)

### Features
- **Smart Code Execution**: Automatic detection of functions, control structures, and code blocks
- **Terminal Integration**: Persistent R session management with auto-recovery
- **Pattern-Based Detection**: Advanced regex engine for R construct recognition
- **Educational Documentation**: Extensive inline comments for VimScript learning
- **Flexible Configuration**: Comprehensive customization options with safe defaults

### Technical Implementation
- Single-file architecture for simple deployment
- Script-local functions for proper encapsulation
- Defensive programming patterns throughout
- Optimized algorithms with performance considerations
- Pure VimScript implementation (no external dependencies)

## [0.1.0] - Initial Development

### Added
- Basic R terminal integration
- Simple code submission functionality
- Initial chunk navigation for R Markdown
- Core key mappings for R workflow
