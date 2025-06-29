# zzvim-R Debugging Steps for test.R with "1"

## Step 1: Check Plugin Loading
1. Open vim with `vim test.R`
2. Check if plugin loaded: `:echo exists('g:loaded_zzvim_r')`
   - Should return 1 if loaded
3. Check file type: `:echo &filetype`
   - Should return 'r'

## Step 2: Check R Executable
1. In vim: `:echo executable('R')`
   - Should return 1 if R is found in PATH
2. From command line: `which R` or `R --version`

## Step 3: Enable Debug Mode
Add to your vimrc or run in vim:
```vim
let g:zzvim_r_debug = 4
```

## Step 4: Test Terminal Creation
1. Press `<LocalLeader>r` (usually `\r` if backslash is your LocalLeader)
2. Or run: `:call zzvim_r#open_terminal()`
3. Check status: `:call zzvim_r#terminal_status()`

## Step 5: Test Code Execution
1. Position cursor on the line with "1"
2. Press `<CR>` (Enter key)
3. Or run: `:call zzvim_r#submit_line()`

## Step 6: Check for Errors
1. Check vim messages: `:messages`
2. Check debug log: `~/zzvim_r.log` (if debug enabled)

## Common Issues and Solutions

### Issue 1: Plugin Not Loading
- Check if plugin directory is in vim's runtimepath: `:echo &rtp`
- Ensure files exist: `plugin/zzvim_r.vim` and `autoload/zzvim_r.vim`

### Issue 2: R Not Found
- Install R: `brew install r` (macOS) or appropriate package manager
- Ensure R is in PATH: `export PATH="/usr/local/bin:$PATH"`

### Issue 3: Key Mappings Not Working
- Check LocalLeader: `:echo mapleader` and `:echo maplocalleader`
- Set LocalLeader if needed: `let maplocalleader = "\"`
- Check if mappings disabled: `:echo get(g:, 'zzvim_r_disable_mappings', 0)`

### Issue 4: Terminal Not Starting
- Check vim version: `:version` (needs 8.0+ with terminal support)
- Check terminal support: `:echo has('terminal')`
- Try manual terminal: `:terminal R --no-save --quiet`

### Issue 5: Code Not Executing
- Ensure terminal is active: `:call zzvim_r#terminal_status()`
- Check if cursor is on the right line
- Try different content (some R expressions might not show output)

## Expected Behavior
When you press Enter on the line with "1":
1. zzvim-R should send "1" to the R terminal
2. R should evaluate it and show: `[1] 1`
3. Cursor should move to the next line