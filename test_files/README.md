# zzvim-R Testing Directory

This directory contains test files and code examples to verify the functionality of the zzvim-R plugin after architectural improvements.

## Contents

- `test.R`: Simple R file for testing basic functionality
- `test.Rmd`: R Markdown file for testing chunk navigation and execution
- `test_error_handling.vim`: Script to test error handling when plugin functions are unavailable
- `code_examples/`: Directory containing explanations of key improvements:
  - `chunk_navigation.txt`: Details on the improved chunk navigation logic
  - `delegation_pattern.txt`: Explanation of the improved delegation pattern

## Test Plan

A comprehensive test plan is available in the main repository directory: `../test_plan.md`. This plan covers:

1. Terminal Management
2. Code Execution
3. Chunk Navigation
4. Object Inspection
5. Package Management
6. Data Operations
7. Directory Operations
8. Help Functions
9. Utilities
10. Error Handling

## Code Quality Report

A detailed code quality report documenting the architectural improvements is available at `../code_quality_report.md`.

## How to Run Tests

### Interactive Testing

The best way to test the plugin is through interactive use in Vim:

1. Open one of the test files in Vim
2. Try the various key mappings documented in the help
3. Verify the behavior matches the expected results

### Error Handling Testing

To test error handling:

```
vim -u NONE -S test_error_handling.vim
```

This will run the error handling tests in a clean Vim environment without loading the plugin.

### Architecture Verification

The delegation pattern and error handling can be verified by examining the code in:
- `../autoload/zzvim_r.vim`
- `../plugin/zzvim_r.vim`

Key aspects to verify include:
- Existence checks before calling script-local functions
- Proper error messages when functions are missing
- Consistent delegation pattern throughout the autoload file