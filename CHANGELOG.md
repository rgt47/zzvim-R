
# Changelog

All notable changes to the zzvim-R plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-09-06

### Added
- **HUD Dashboard System**: Revolutionary workspace situational awareness
  - `<LocalLeader>0` - Unified HUD Dashboard opening all 5 workspace tabs simultaneously
  - Memory Usage HUD (`<LocalLeader>m`) - Object memory consumption analysis
  - Data Frames HUD (`<LocalLeader>e`) - Overview of all data frames with dimensions
  - Package Status HUD (`<LocalLeader>z`) - Currently loaded packages display  
  - Environment Variables HUD (`<LocalLeader>x`) - System environment inspection
  - R Options HUD (`<LocalLeader>a`) - R session options with value processing
- **Enhanced RAction**: RStudio-style Data Viewer (`<LocalLeader>v`)
  - Professional tabulated display with Tabularize/EasyAlign integration
  - Cross-platform compatibility and automatic temp file cleanup
  - Read-only buffer configuration for data safety

### Features
- **Unified Workspace Intelligence**: Single keystroke access to complete workspace overview
- **Professional Tab Management**: Automatic cleanup, smart naming, and refresh capability
- **IDE-Quality Experience**: Workspace awareness matching commercial tools with Vim efficiency
- **Cross-Platform Support**: Full Vim/Neovim compatibility with identical functionality
- **Real-Time Data**: All HUD displays show current workspace state with refresh capability

### Technical Implementation
- **Advanced Tab Architecture**: Intelligent buffer naming with source file context
- **Efficient Data Generation**: Optimized R commands with proper error handling
- **Resource Management**: Automatic temp file cleanup and memory optimization
- **Terminal Association**: Proper R terminal discovery and reuse logic
- **Professional Buffer Setup**: Read-only, auto-cleanup configuration for all HUD displays

### Documentation
- Complete help system integration with detailed command reference
- Comprehensive README updates with usage examples and navigation guide
- Updated key mappings documentation with HUD function categorization

## [1.0.1] - 2025-08-12

### Added
- Comprehensive inline documentation for educational purposes (300+ explanatory comments)
- VimScript fundamentals embedded throughout the codebase for learning
- Advanced algorithm documentation (pattern detection, brace matching)
- Complete function headers with parameters and return value explanations
- Plugin architecture and design philosophy documentation
- Configuration system explanation with real-world examples
- Key mappings reference with VimScript convention explanations
- Ex commands documentation with parameter and usage details

### Changed
- Enhanced error handling with detailed explanations
- Improved code organization with educational comments
- Updated documentation to serve as VimScript programming tutorial

### Technical Details
- Plugin now serves dual purpose as functional tool and educational resource
- All core algorithms documented with step-by-step breakdowns
- VimScript best practices clearly explained throughout codebase
- Maintains 100% backward compatibility while adding educational value

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
