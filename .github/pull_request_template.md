# Pull Request

## Description
Provide a clear and concise description of what this PR does.

## Type of Change
Please delete options that are not relevant:
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Code refactoring (no functional changes)
- [ ] Performance improvement
- [ ] Test improvements

## Related Issues
Fixes #(issue_number)
Relates to #(issue_number)

## Changes Made
Describe the specific changes made in this PR:
- Added/modified function X to do Y
- Fixed bug in Z component
- Updated documentation for feature A

## Testing
Describe the testing you've done:
- [ ] All existing tests pass (`make test-quick`)
- [ ] Added new tests for new functionality
- [ ] Tested manually with R files
- [ ] Tested with R Markdown files
- [ ] Tested error conditions

**Test Environment:**
- OS: [e.g. macOS 13.0]
- Vim version: [e.g. 8.2]
- R version: [e.g. 4.3.0]

## Documentation
- [ ] Updated help documentation (`doc/zzvim-R.txt`)
- [ ] Updated README if needed
- [ ] Updated CHANGELOG.md
- [ ] Added/updated code comments

## Configuration Changes
If this PR adds new configuration options:
- [ ] Added default values
- [ ] Updated documentation
- [ ] Maintained backward compatibility

## Breaking Changes
If this PR introduces breaking changes:
- [ ] Documented in CHANGELOG.md
- [ ] Updated help documentation
- [ ] Provided migration guidance

## Code Quality
- [ ] Follows VimScript style guidelines
- [ ] Includes proper error handling
- [ ] Functions include `abort` keyword
- [ ] Variables use appropriate scoping (`g:`, `s:`, `l:`)
- [ ] Comments explain complex logic

## Security Considerations
If applicable:
- [ ] Validates user inputs
- [ ] Avoids shell injection vulnerabilities
- [ ] Handles file paths safely
- [ ] No new security risks introduced

## Screenshots
If applicable, add screenshots to demonstrate the changes.

## Additional Notes
Any additional information, concerns, or questions about this PR.

## Checklist
- [ ] I have read the contributing guidelines
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes