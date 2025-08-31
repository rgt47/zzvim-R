# Neovim R Development Setup - Testing Guide

This guide helps verify that your complete R development environment is working correctly in Neovim.

## Prerequisites

1. **R Language Server**: Install in R console:
   ```r
   install.packages("languageserver")
   ```

2. **styler**: For code formatting:
   ```r
   install.packages("styler")
   ```

## Testing Steps

### 1. Start Neovim and Install Plugins

```bash
cd /Users/zenn/Library/CloudStorage/Dropbox/prj/d05/zzvim-R
nvim test_neovim_setup.R
```

In Neovim:
```
:Lazy sync
```

Wait for all plugins to install, then restart Neovim.

### 2. Test zzvim-R Plugin Functionality

With `test_neovim_setup.R` open:

**Basic code execution:**
- Position cursor on line 5: `library(dplyr)`
- Press `<Space><CR>` (space + enter) to execute line
- Should create R terminal and execute the command

**Block detection:**
- Position cursor on line 11: `my_function <- function(x, y) {`  
- Press `<Space><CR>` - should execute entire function block

**Backtick syntax (recent bug fix):**
- Position cursor on line 21: `column_names <- sapply(mtcars, \`[[\`, 1)`
- Press `<Space><CR>` - should execute without errors

### 3. Test LSP Features

**Diagnostics:**
- You should see underlined issues for style problems (e.g., `x<-5` on line 7)
- Press `,d` to open diagnostics panel
- Press `q` to close panel

**Code actions (auto-fix):**
- Position cursor on `x<-5` (line 7) 
- Press `,ca` to see code actions
- Should offer to fix spacing: `x <- 5`

**Formatting:**
- Press `,f` to format entire file
- Should fix spacing issues automatically

**Hover documentation:**
- Position cursor on `dplyr` (line 4)
- Press `K` to see documentation

### 4. Test Other LSP Features

**Go to definition:**
- Position cursor on `mtcars` (line 15)
- Press `gd` to jump to definition

**Navigate diagnostics:**
- Press `]d` to go to next diagnostic
- Press `[d` to go to previous diagnostic

## Expected Results

✅ **zzvim-R integration**: R terminal opens, code executes cleanly  
✅ **Smart detection**: Functions and blocks execute as complete units  
✅ **LSP diagnostics**: Style issues highlighted with underlines  
✅ **Auto-fixing**: Code actions available via `,ca`  
✅ **Formatting**: `,f` fixes spacing and style issues  
✅ **Documentation**: `K` shows hover info, `gd` jumps to definitions  

## Troubleshooting

**No R terminal**: Check that R is installed and in PATH
**No LSP features**: Verify `languageserver` R package is installed  
**No formatting**: Install `styler` R package
**Plugin not loaded**: Run `:Lazy sync` and restart Neovim

## Key Mappings Reference

### zzvim-R (LocalLeader = Space)
- `<Space><CR>` - Smart code execution
- `<Space>r` - Open R terminal  
- `<Space>h` - head() of object under cursor
- `<Space>s` - str() of object under cursor

### LSP and Formatting (Leader = Comma)  
- `,f` - Format file
- `,d` - Toggle diagnostics panel
- `,ca` - Code actions (auto-fix)
- `K` - Hover documentation
- `gd` - Go to definition
- `]d` / `[d` - Next/previous diagnostic

This setup provides a complete R development environment comparable to RStudio or VS Code, but with Vim's efficiency and your preferred workflow.