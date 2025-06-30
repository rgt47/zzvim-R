# zzvim-R Test Suite

This directory contains automated tests for the zzvim-R plugin.

## Structure

- `test_runner.vim` - Main test runner script
- `unit/` - Unit tests that don't require R
- `integration/` - Integration tests that require R to be available

## Running Tests

### Run All Tests
```bash
vim -u NONE -S tests/test_runner.vim
```

### Run Specific Test Categories

**Unit Tests Only** (no R required):
```bash
vim -u NONE -c "source tests/unit/test_configuration.vim" -c "source tests/unit/test_functions.vim" -c "qa"
```

**Integration Tests Only** (requires R):
```bash
vim -u NONE -c "source tests/integration/test_basic_functionality.vim" -c "qa"
```

## Test Categories

### Unit Tests
- **Configuration Tests**: Plugin loading, configuration variables, command definitions
- **Function Tests**: Function existence, error handling, graceful failure

### Integration Tests  
- **Basic Functionality**: R file detection, chunk navigation, content extraction
- **Terminal Integration**: R terminal creation and interaction (limited testing)

## Requirements

### For Unit Tests
- Vim 8.0+ with terminal support
- No external dependencies

### For Integration Tests
- All unit test requirements
- R executable in PATH
- Ability to create temporary files

## Test Framework

The tests use a simple custom framework with these assertion functions:

- `Assert(condition, message)` - Assert a condition is true
- `AssertEqual(expected, actual, message)` - Assert values are equal
- `AssertExists(funcname, message)` - Assert a function exists

## CI/CD Integration

These tests are designed to run in automated environments:

- Exit code 0 = all tests passed
- Exit code 1 = some tests failed
- Minimal output for automated parsing
- No interactive prompts or user input required

## Limitations

Due to the interactive nature of some plugin features:

- **Terminal creation**: Limited testing to avoid hanging in CI
- **User input**: Package management functions tested for graceful handling only
- **R execution**: No actual R code execution in tests (would require complex setup)

## Adding New Tests

1. Create test files in appropriate subdirectory (`unit/` or `integration/`)
2. Use the assertion functions provided by `test_runner.vim`
3. Add the test file to the runner in `test_runner.vim`
4. Ensure tests are deterministic and don't require user interaction