# zzcollab + png1: Quick Start Guide

**Your Setup:**
- Vim config: `~/.vimrc`
- LocalLeader: `<Space>` (not backslash)
- Workspace: `~/prj/d07/zzcollab`
- Docker image: `png1`
- Launch: `make r`

## The Simple Workflow

### Step 1: Open R file in Vim
```bash
cd ~/prj/d07/zzcollab
vim analysis.R
```

### Step 2: Launch Docker R and execute

**In Vim:**
```vim
ZR            " Launch Docker R via 'make r' (Shift+Z then Shift+R)
<CR>          " Execute code
```

## That's It!

After `ZR` launches Docker R, all normal zzvim-R features work:
- `<CR>` - Execute code
- `<Space>h` - head(object)
- `<Space>s` - str(object)
- `<Space>m` - Memory HUD
- Visual select + `<CR>` - Execute selection

## Alternative: External Terminal Workflow

If you prefer to launch Docker R externally before opening Vim:

```bash
# Terminal 1:
cd ~/prj/d07/zzcollab
make r                # Launches png1 with R

# Terminal 2:
cd ~/prj/d07/zzcollab
vim src/analysis.R

# In Vim:
<Space>dr             # Force-associate with make r terminal
<CR>                  # Execute code as needed
```

## Launching Docker R from Vim

The recommended approach is to launch Docker R directly from Vim:

```vim
ZR            " Launches png1 via 'make r' (Shift+Z then Shift+R)
```

This is simpler and faster than using external terminals.

## Key Mappings Summary (Your LocalLeader = Space)

| Key | Action |
|-----|--------|
| `ZR` | **Launch Docker R via make r** ⭐ |
| `<Space>dr` | Force-associate with existing Docker terminal |
| `<Space>r` | Launch regular (non-Docker) R terminal |
| `<CR>` | Execute current line/function/block |
| `<Space>h` | head(object under cursor) |
| `<Space>s` | str(object) |
| `<Space>d` | dim(object) |
| `<Space>p` | print(object) |
| `<Space>m` | Memory HUD |
| `<Space>e` | Data frames HUD |
| `<Space>0` | Full HUD dashboard (all tabs) |

## Troubleshooting

**"No terminals found"**
```vim
:ls!                  " See all buffers including terminals
:b [terminal-num]     " Switch to docker terminal (e.g., :b 5)
:file R-analysis      " Rename it to match your R file
Ctrl-W p              " Back to R file
<Space>dr             " Try force-associate again
```

**Check association status**
```vim
:RShowTerminal        " Shows current buffer's terminal
:RListTerminals       " Shows all R file ↔ terminal associations
```

**Verify Docker terminal is running**
```vim
:ls!                  " List all buffers including terminals
" Look for a terminal buffer with 'make r' or R prompt visible
```

## Complete Example Session

**Open your R file:**
```bash
cd ~/prj/d07/zzcollab
vim src/analysis.R
```

**In Vim editing `src/analysis.R`:**

```r
# Your R code:
library(tidyverse)        # Line 1

data <- tibble(           # Line 3
    x = 1:10,
    y = rnorm(10)
)

summary(data)             # Line 8
```

**Execute the code:**
```vim
" Launch Docker R
ZR                     " Shift+Z then Shift+R

" Execute line 1
" Cursor on line 1, press Enter:
<CR>
" → library(tidyverse) runs in png1 container

" Execute lines 3-6 (the tibble block)
" Cursor anywhere on line 3, 4, 5, or 6, press Enter:
<CR>
" → Entire tibble creation runs in png1 container

" Execute line 8
" Cursor on line 8, press Enter:
<CR>
" → summary(data) runs in png1 container

" Inspect the data object
" Cursor on word "data", press Space+h:
<Space>h
" → head(data) runs and shows first rows

" See data structure
" Cursor on word "data", press Space+s:
<Space>s
" → str(data) shows structure
```

All executed code runs in your png1 container!

## Working with .Rmd Files

If you use R Markdown in zzcollab:

```bash
cd ~/prj/d07/zzcollab
vim report.Rmd
```

**In Vim:**
```vim
ZR                  " Launch Docker R

" Navigate chunks:
<Space>j            " Next chunk
<Space>k            " Previous chunk

" Execute current chunk:
<Space>l            " Runs entire chunk in png1 container

" Execute all previous chunks:
<Space>t            " Runs all chunks from start to cursor
```

## Quick Reference Card

```
DOCKER TERMINAL MANAGEMENT
--------------------------
ZR         → Launch png1 via make r ⭐ (recommended)
<Space>dr  → Force-associate with existing terminal
<Space>r   → Launch regular R (no Docker)

CODE EXECUTION
--------------
<CR>       → Execute line/function/block
V (select) → Then <CR> to execute selection

OBJECT INSPECTION
-----------------
<Space>h   → head()
<Space>s   → str()
<Space>d   → dim()
<Space>p   → print()
<Space>n   → names()
<Space>g   → glimpse()

CHUNK NAVIGATION (.Rmd files)
------------------------------
<Space>j   → Next chunk
<Space>k   → Previous chunk
<Space>l   → Execute current chunk
<Space>t   → Execute all previous chunks

HUD DISPLAYS
------------
<Space>m   → Memory usage
<Space>e   → Data frames
<Space>z   → Loaded packages
<Space>v   → Data viewer (cursor on df)
<Space>0   → Full dashboard (all tabs)

TERMINAL MANAGEMENT
-------------------
:RShowTerminal      → Show current association
:RListTerminals     → List all associations
:RSwitchToTerminal  → Switch to R terminal window
```

## Common Issues

**Issue:** Press `<Space>dr` but nothing happens

**Solutions:**
1. Check LocalLeader is set:
   ```vim
   :echo maplocalleader
   " Should show a space character or empty
   ```

2. Verify terminal exists:
   ```vim
   :ls!
   " Look for terminal buffer running R
   ```

3. Make sure you're in an R file:
   ```vim
   :set filetype?
   " Should show: filetype=r or filetype=rmd
   ```

**Issue:** Code executes in wrong place

**Solution:**
```vim
:RShowTerminal
" Verify association is correct
" Should show buffer name matching your docker terminal
```

**Issue:** Files not found in container

In your `make r` Makefile target, ensure:
```makefile
r:
    docker run -it --rm \
        -v $(PWD):/workspace \
        -w /workspace \
        png1 R --no-save --quiet
```

Test in R terminal:
```r
getwd()         # Should show: /workspace
list.files()    # Should show your project files
```

## Tips

1. **Use tmux for persistent sessions:**
   ```bash
   tmux new -s zzcollab
   # Your work session persists even if connection drops
   ```

2. **Quick terminal switching in Vim:**
   ```vim
   :RSwitchToTerminal     " Jump to R terminal
   Ctrl-W p               " Jump back to last window
   ```

3. **Check what's running:**
   ```vim
   :RListTerminals
   " See all R files and their associated terminals
   ```

4. **Multiple R files, one container:**
   ```vim
   " Open file1.R → <Space>dr → select docker terminal
   " Open file2.R → <Space>dr → select SAME docker terminal
   " Both files now share the png1 container environment
   ```

## Summary

**Recommended Workflow:**
1. `vim analysis.R`
2. `ZR` in Vim (launches Docker R via `make r`)
3. `<CR>` to execute code as needed

**Alternative Workflow (external terminal):**
1. `make r` in one terminal
2. `vim analysis.R` in another terminal
3. `<Space>dr` once in Vim
4. `<CR>` to execute code as needed

That's it! `ZR` is the simplest way to get started with Docker R development.
