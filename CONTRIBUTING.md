# Contributing to zzvim-R

Thank you for your interest in contributing to the zzvim-R plugin! This document provides guidelines for contributing to the project.

## Code of Conduct

This project follows the principles of respectful collaboration. Please be kind, constructive, and professional in all interactions.

## How to Contribute

### Reporting Issues

Before creating an issue, please:
1. Check existing issues to avoid duplicates
2. Use the latest version of the plugin
3. Include relevant system information (Vim version, OS, R version)

**Issue Template:**
```
**Bug Description:**
A clear description of the issue

**Steps to Reproduce:**
1. Step one
2. Step two
3. Step three

**Expected Behavior:**
What you expected to happen

**Actual Behavior:**
What actually happened

**Environment:**
- Vim version: 
- R version:
- Operating System:
- Plugin version:
```

### Suggesting Features

Feature requests are welcome! Please:
1. Check existing issues for similar requests
2. Explain the use case and benefit
3. Consider backward compatibility
4. Provide implementation ideas if possible

### Code Contributions

#### Development Setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/zzvim-R.git`
3. Create a feature branch: `git checkout -b feature-name`
4. Make your changes
5. Test your changes thoroughly
6. Commit with clear messages
7. Push to your fork
8. Create a pull request

#### Code Standards

**VimScript Style Guidelines:**
- Use 4-space indentation
- Function names should be descriptive and follow VimScript conventions
- Use `s:` prefix for script-local functions
- Include `abort` keyword in function definitions
- Add comprehensive documentation for new functions
- Follow existing error handling patterns

**Documentation Requirements:**
- All new functions must include header comments explaining:
  - Purpose and functionality
  - Parameters with types and descriptions
  - Return values
  - Usage examples where helpful
- Update help documentation (`doc/zzvim-R.txt`) for user-facing changes
- Add educational comments following the established pattern

**Testing Requirements:**
- Add test cases for new functionality
- Ensure existing tests pass
- Test on multiple platforms when possible
- Include edge case testing

#### Commit Guidelines

Follow conventional commits format:
```
type(scope): description

Longer description if needed

- List specific changes
- Reference issues: Fixes #123
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

#### Pull Request Process

1. **Before Submitting:**
   - Ensure all tests pass
   - Update documentation if needed
   - Add yourself to contributors if desired
   - Rebase on latest master branch

2. **Pull Request Template:**
   ```
   ## Description
   Brief description of changes

   ## Type of Change
   - [ ] Bug fix
   - [ ] New feature
   - [ ] Documentation update
   - [ ] Code refactoring

   ## Testing
   - [ ] Existing tests pass
   - [ ] New tests added
   - [ ] Manual testing completed

   ## Checklist
   - [ ] Code follows style guidelines
   - [ ] Self-review completed
   - [ ] Documentation updated
   - [ ] No breaking changes (or clearly documented)
   ```

3. **Review Process:**
   - Maintainers will review within reasonable time
   - Address feedback constructively
   - Keep discussions focused on the code
   - Be patient with the review process

## Development Areas

### Priority Areas for Contribution

1. **Pattern Recognition Enhancement**
   - Support for additional R language constructs
   - S4 class and R6 object detection
   - Advanced control flow patterns

2. **Platform Compatibility**
   - Windows-specific testing and fixes
   - Neovim compatibility improvements
   - Terminal emulation enhancements

3. **User Experience**
   - Performance optimizations
   - Error message improvements
   - Configuration validation

4. **Documentation**
   - Additional usage examples
   - Video tutorials or animated GIFs
   - Multi-language documentation

5. **Testing Infrastructure**
   - Automated testing improvements
   - Integration test coverage
   - Performance benchmarking

### Technical Architecture

Understanding the plugin architecture helps with contributions:

**Core Components:**
- `s:SendToR()`: Main code submission orchestrator
- `s:IsBlockStart()`: Pattern detection engine
- `s:GetCodeBlock()`: Brace matching algorithm
- `s:Send_to_r()`: Terminal communication
- Chunk navigation system
- Configuration management

**Key Design Principles:**
- Single-file architecture for simplicity
- Educational code with comprehensive documentation
- Defensive programming patterns
- Pure VimScript implementation
- Backward compatibility maintenance

## Release Process

Releases follow semantic versioning:
- **Major (x.0.0)**: Breaking changes
- **Minor (x.y.0)**: New features, backward compatible
- **Patch (x.y.z)**: Bug fixes, backward compatible

## Getting Help

- **Documentation**: Read `README.md` and `doc/zzvim-R.txt`
- **Issues**: Check existing issues and discussions
- **Code Questions**: Comment on relevant code sections
- **General Discussion**: Use GitHub discussions

## Recognition

Contributors are recognized in:
- Git commit history
- Release notes
- README acknowledgments (for significant contributions)

Thank you for helping improve zzvim-R!