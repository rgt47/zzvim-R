# Changelog

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