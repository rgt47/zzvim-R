---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: 'bug'
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Open file '...'
2. Press key '...'
3. Execute command '...'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Actual behavior**
What actually happened instead.

**Environment (please complete the following information):**
- OS: [e.g. macOS 13.0, Ubuntu 22.04, Windows 11]
- Vim version: [output of `:version`]
- R version: [output of `R --version`]
- Plugin version: [e.g. 3.0.0]

**Configuration**
Please share relevant configuration from your vimrc:
```vim
" Example:
let g:zzvim_r_command = 'R --vanilla'
let g:zzvim_r_terminal_width = 80
```

**Error messages**
If applicable, include any error messages:
- From Vim: `:messages`
- From R terminal: copy any error output
- From debug log: `:let g:zzvim_r_debug = 4` then reproduce issue

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Additional context**
Add any other context about the problem here:
- Does it happen with specific R packages?
- Does it happen in specific file types?
- Is it reproducible with minimal configuration?

**Checklist**
- [ ] I have searched existing issues for duplicates
- [ ] I can reproduce this bug consistently
- [ ] I have included all requested information
- [ ] I have tested with the latest version of the plugin