# Security Policy

## Overview

zzvim-R is a Vim plugin that integrates with the R programming language by executing R code and managing R terminal sessions. This document outlines the security considerations and policies for the plugin.

## Security Model

### Code Execution
- **User Code Only**: The plugin only executes R code that the user explicitly sends to it
- **No Automatic Execution**: No code is executed without explicit user action (key press or command)
- **Terminal Isolation**: R code runs in a separate terminal process, not in Vim's process space
- **User Permission**: All R execution requires the user to actively send code (via `<CR>` or commands)

### Input Validation
- **File Paths**: User-provided file paths are validated before use
- **Package Names**: Package names are validated against R naming conventions
- **R Commands**: Only user-authored R code is executed, no command injection

### Process Management
- **Isolated R Process**: R runs in its own terminal process managed by Vim
- **Process Cleanup**: Plugin properly cleans up R terminal processes
- **No Shell Injection**: File operations use Vim's built-in functions, not shell commands

## Potential Security Considerations

### 1. R Code Execution
**Risk**: The plugin executes R code in a terminal session.
**Mitigation**: 
- Only executes code explicitly sent by the user
- No automatic code execution or code modification
- R runs with the user's permissions, not elevated privileges

### 2. File System Access
**Risk**: Plugin reads/writes files for data import/export and workspace operations.
**Mitigation**:
- Only operates on files specified by the user
- Uses Vim's built-in file operations
- No automatic file modification outside user requests

### 3. Temporary Files
**Risk**: Plugin creates temporary files for R script execution.
**Mitigation**:
- Uses Vim's `tempname()` function for secure temporary file creation
- Temporary files are cleaned up after use
- Temporary files contain only user-authored R code

### 4. External Process Communication
**Risk**: Plugin communicates with R terminal process.
**Mitigation**:
- Communication only sends user-provided R code
- No interpretation or modification of R output
- R process runs with user's permissions

## Safe Usage Guidelines

### For Users
1. **Review R Code**: Always review R code before executing it
2. **Trusted Sources**: Only execute R code from trusted sources
3. **File Paths**: Be cautious with file paths in data operations
4. **Package Installation**: Only install packages from trusted repositories

### For Developers/Contributors
1. **Input Validation**: Always validate user inputs
2. **No Shell Commands**: Use Vim functions instead of shell commands where possible
3. **Secure Defaults**: Choose secure default configurations
4. **Error Handling**: Fail safely and provide clear error messages

## Reporting Security Issues

If you discover a security vulnerability in zzvim-R, please report it responsibly:

1. **Do not** open a public GitHub issue
2. **Email** the maintainer directly: rgthomas@ucsd.edu
3. **Include** detailed information about the vulnerability
4. **Allow** reasonable time for response and patching

### What to Include
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Suggested mitigation (if any)

## Security Updates

Security updates will be handled as follows:

1. **Assessment**: Evaluate the severity and impact
2. **Fix Development**: Develop and test a fix
3. **Release**: Issue a patch release with security fix
4. **Notification**: Update this document and release notes
5. **Disclosure**: Responsible disclosure after fix is available

## Supported Versions

Security updates are provided for:
- Latest major version (3.x)
- Previous major version (2.x) for critical issues only

## Security Features

### Current Security Measures
- ✅ Input validation for file paths and package names
- ✅ Secure temporary file creation and cleanup
- ✅ No automatic code execution
- ✅ Process isolation for R execution
- ✅ Proper error handling and cleanup

### Security Best Practices Implemented
- ✅ Minimal privilege principle (runs with user permissions)
- ✅ Defense in depth (multiple validation layers)
- ✅ Secure defaults (conservative configuration)
- ✅ Clear separation of concerns (R process vs Vim)

## Disclaimer

While zzvim-R implements security best practices, users should:
- Exercise caution when executing any code
- Understand that R code execution inherits user permissions
- Be aware that file operations can modify the file system
- Keep both Vim and R updated to their latest versions

The plugin maintainers are not responsible for damages caused by malicious R code or user error. Users execute R code at their own risk and responsibility.