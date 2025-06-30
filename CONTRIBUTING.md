# Contributing to zzvim-R

Thank you for your interest in contributing to zzvim-R! This document provides guidelines for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Submitting Changes](#submitting-changes)

## Code of Conduct

This project adheres to a code of conduct that promotes a welcoming and inclusive environment. By participating, you agree to uphold this code.

## Getting Started

### Prerequisites
- Vim 8.0+ with terminal support or Neovim 0.5.0+
- R executable in PATH
- Git for version control
- Basic knowledge of VimScript and R

### Areas for Contribution
- 🐛 **Bug fixes**: Improve reliability and fix issues
- ✨ **Features**: Add new functionality (see open issues)
- 📚 **Documentation**: Improve help docs, README, examples
- 🧪 **Testing**: Expand test coverage and test automation
- 🎨 **Code quality**: Refactoring, optimization, code cleanup

## Development Setup

1. **Fork and Clone**
   ```bash
   git clone https://github.com/yourusername/zzvim-r.git
   cd zzvim-r
   ```

2. **Set up Development Environment**
   ```bash
   # Test the plugin loads correctly
   make test-quick
   
   # Install in your Vim for testing
   ln -s $(pwd) ~/.vim/pack/dev/start/zzvim-r
   ```

3. **Verify Installation**
   ```vim
   :help zzvim-r
   ```

## Contributing Guidelines

### Before You Start
- Check existing issues and PRs to avoid duplication
- For major changes, open an issue first to discuss the approach
- Ensure you can reproduce any bugs you're trying to fix

### Types of Contributions

#### Bug Reports
- Use the bug report template
- Include Vim version, OS, and R version
- Provide minimal reproduction steps
- Include error messages and logs

#### Feature Requests
- Use the feature request template
- Explain the use case and benefit
- Consider if it fits the plugin's scope
- Provide examples of desired behavior

#### Pull Requests
- Follow the PR template
- Link to related issues
- Include tests for new functionality
- Update documentation as needed

## Coding Standards

### VimScript Style
```vim
" Function names: PascalCase for public, snake_case for private
function! MyPublicFunction() abort
function! s:my_private_function() abort

" Variables: Use proper scoping
let g:global_var = 'value'      " Global
let s:script_var = 'value'      " Script-local
let l:local_var = 'value'       " Function-local

" Comments: Comprehensive documentation
" Brief description
"
" Parameters:
"   param1 - Type: Description
"   param2 - Type: Description
"
" Returns:
"   Type: Description
```

### Code Organization
- **Functions**: Group related functions with clear section headers
- **Comments**: Document complex logic and algorithms
- **Error Handling**: Use `abort` keyword and proper try/catch
- **Performance**: Avoid unnecessary loops and function calls

### Key Principles
1. **Backward Compatibility**: Don't break existing functionality
2. **Error Handling**: Fail gracefully with helpful messages
3. **Performance**: Consider impact on startup time and responsiveness
4. **Security**: Validate inputs and avoid shell injection
5. **User Experience**: Maintain consistent behavior and clear feedback

## Testing

### Running Tests
```bash
# Quick validation
make test-quick

# Comprehensive test
vim -u NONE -S tests/simple_test.vim

# Manual testing
vim test_files/test.R
```

### Writing Tests
- Add tests for new functionality
- Test error conditions and edge cases
- Ensure tests work without R (unit tests)
- Use descriptive test names

### Test Structure
```vim
" Test example
function! TestMyFeature() abort
    " Setup
    new
    set filetype=r
    
    " Test
    let result = zzvim_r#my_function()
    
    " Assert
    call assert_equal(expected, result)
    
    " Cleanup
    bdelete!
endfunction
```

## Documentation

### Help Documentation
- Update `doc/zzvim-R.txt` for new features
- Follow existing format and style
- Include examples and common use cases
- Add tags for searchability

### Code Documentation
- Document all public functions
- Explain complex algorithms
- Include parameter and return type information
- Use clear, concise language

### README Updates
- Update feature lists for new functionality
- Add new configuration options
- Update examples and usage instructions

## Submitting Changes

### Pull Request Process

1. **Create Feature Branch**
   ```bash
   git checkout -b feature/my-new-feature
   git checkout -b fix/issue-123
   ```

2. **Make Changes**
   - Write code following style guidelines
   - Add/update tests
   - Update documentation
   - Test thoroughly

3. **Commit Messages**
   ```
   type(scope): brief description
   
   Longer explanation if needed.
   
   Fixes #123
   ```
   
   Types: `feat`, `fix`, `docs`, `test`, `refactor`, `style`, `chore`

4. **Submit PR**
   - Use the PR template
   - Link to related issues
   - Describe changes and motivation
   - Include testing information

### Review Process
- Maintainer will review within 1-2 weeks
- Address feedback constructively
- Keep discussions focused and respectful
- Update PR based on feedback

### Merge Criteria
- ✅ Passes all tests
- ✅ Follows coding standards
- ✅ Includes appropriate documentation
- ✅ Maintains backward compatibility
- ✅ Has clear, focused scope

## Development Tips

### Debugging
```vim
" Enable debug logging
let g:zzvim_r_debug = 4
let g:zzvim_r_log_file = '/tmp/zzvim_debug.log'

" Check terminal status
:RTerminalStatus

" View logs
:edit /tmp/zzvim_debug.log
```

### Common Patterns
```vim
" Error handling
if !exists('*required_function')
    return s:error_msg('Required function not available')
endif

" Safe configuration access
let value = get(g:, 'config_var', 'default')

" Input validation
if empty(a:input) || a:input !~# '^[a-zA-Z][a-zA-Z0-9_]*$'
    return s:error_msg('Invalid input')
endif
```

### Architecture Notes
- **plugin/**: Core functionality, loaded at startup
- **autoload/**: Public API, lazy-loaded on demand
- **doc/**: Help documentation
- **tests/**: Automated test suite

## Questions?

- 📖 Check the documentation: `:help zzvim-r`
- 🐛 Search existing issues on GitHub
- 💬 Open a discussion for questions
- 📧 Contact maintainer: rgthomas@ucsd.edu

Thank you for contributing to zzvim-R! 🎉