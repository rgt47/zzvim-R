# Changelog

## [2.3.2] - 2025-06-02
### Changed
- Fixed script-local loop variables to use function-local scope for better maintainability
- Standardized return types to use integers (0/1) consistently throughout the plugin
- Added helper functions for common operations like error handling and config access
- Removed unnecessary global variable to reduce namespace pollution
- Improved delegation pattern in wrapper functions
- Enhanced configuration access with robust fallback mechanism

### Technical
- Created `s:error_msg()` helper for consistent error handling
- Created `s:get_config()` helper for safe configuration access with fallbacks
- Updated all loops to use properly scoped function-local variables
- Standardized on integer return values (0/1) instead of booleans
- Maintained backward compatibility while reducing global namespace usage
- Improved code organization and reduced redundancy

## [2.3.1] - 2025-06-01
### Changed
- Optimized code structure with improved separation of concerns
- Implemented consistent delegation pattern between plugin and autoload files
- Reduced code duplication and improved function organization
- Enhanced error handling for more robust operation
- Added technical documentation for developers
- Fixed potential race condition in plugin loading
- Eliminated circular dependencies between autoload and plugin files
- Improved autoload function error handling with existence checks
- Added fallback behavior when plugin functions are not available
- Added consistent error messages for missing dependencies

### Technical
- Updated delegation model to use function references for script-local functions
- Added existence checks for all script-local function calls
- Enhanced error messages to provide more context
- Fixed potential issues with s:config access in autoload functions
- Documented architectural improvements in README and help files

## [2.3.0] - 2025-05-31
### Added
- Fixed chunk navigation issues, particularly with previous chunk navigation
- Eliminated key mapping conflicts by changing two-letter mappings
  - Package commands changed from `pi/pl/pu` to `xi/xl/xu`
  - Data commands changed from `dr/dw/dl/ds` to `zr/zw/zl/zs`
  - Directory commands changed from `pd/cd/ld/hd` to `vd/vc/vl/vh`
  - Help commands changed from `he/ha/hf` to `ue/ua/uf`
- Updated all documentation to reflect new mapping scheme

## [2.2.0] - 2025-05-29
### Added
- Enhanced Object Inspection: workspace browser, class info, detailed structure
- Package Management: install, load, update functions
- Data Import/Export: CSV and RDS file operations
- Directory Management: working directory navigation and management
- Enhanced Help System: help with examples, apropos search, function finding
- New key mappings for all new features
- New commands: `:RPackage`, `:RData`, `:RDirectory`
- Updated documentation

### Changed
- Updated plugin.json to reflect new version and features
- Improved s:r_inspect() function with more inspection options
- Extended s:engine() function with new operation types

## [2.1.0] - 2025-05-28
### Added
- Initial release of the plugin with core features
- Terminal integration for R
- Code execution for lines, selections, and chunks
- R Markdown chunk navigation
- Basic object inspection
- Configuration options