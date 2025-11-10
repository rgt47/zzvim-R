# Workflow Example: zzcollab with png1 Docker Container

## Scenario

- **Workspace:** `~/prj/d07/zzcollab`
- **Docker image:** `png1` (custom-built)
- **Makefile target:** `make r` launches the png1 container with R
- **Goal:** Edit R files in Vim and execute code in the running png1 container

## Prerequisites

1. Docker image `png1` is built and available:
   ```bash
   docker images | grep png1
   ```

2. Makefile in `~/prj/d07/zzcollab` has target `r` that launches container:
   ```makefile
   # Example Makefile
   r:
       docker run -it --rm \
           -v $(PWD):/workspace \
           -w /workspace \
           png1 R --no-save --quiet
   ```

3. zzvim-R plugin installed and loaded

## Step-by-Step Workflow

### Option 1: Manual Docker Launch + Force-Associate (Recommended for existing Makefile)

This approach uses your existing `make r` command and force-associates Vim with it.

#### Step 1: Launch png1 container with Makefile

In your first terminal:

```bash
cd ~/prj/d07/zzcollab
make r
```

This opens an R session in the png1 container. You should see:
```
R version X.X.X ...
>
```

#### Step 2: Open Vim in a second terminal/tmux pane

In your second terminal (or tmux split):

```bash
cd ~/prj/d07/zzcollab
vim analysis.R
```

#### Step 3: Get the Docker terminal buffer name

In Vim, check what terminals exist:

```vim
" List all terminals
:RListTerminals

" Or check if the container terminal is visible
:ls!
```

You should see your `make r` terminal, but it probably has a generic name like `!bash` or similar.

#### Step 4: Rename the Docker terminal for association

Switch to the terminal window running `make r` and rename it:

```vim
" In the terminal buffer running R:
:file R-analysis

" This names it to match the R file you're editing
```

**Alternative:** If you want zzvim-R to automatically find it, name the terminal using the expected pattern before opening Vim:

From the terminal running make:
```bash
# In the shell before running make r, start vim terminal with specific name
vim -c "terminal ++curwin ++close make r" -c "file R-analysis"
```

#### Step 5: Force-associate your R buffer with the Docker terminal

Back in your Vim window with `analysis.R`:

```vim
" Press this key combination (LocalLeader is usually backslash \)
<LocalLeader>dr

" Or use the Ex command:
:RDockerTerminalForce
```

You should see:
```
Force-associated with existing Docker terminal: R-analysis
```

#### Step 6: Execute R code

Now you can execute R code normally:

```vim
" Place cursor on any line and press Enter
<CR>

" Or select multiple lines visually and press Enter
V  (select lines)
<CR>
```

The code executes in your `make r` container!

---

### Option 2: Direct zzvim-R Docker Launch (Alternative Method)

This approach bypasses the Makefile and uses zzvim-R's Docker integration directly.

#### Step 1: Configure Vim to use png1 image

Add to your `~/.vimrc` or create `~/prj/d07/zzcollab/.vimrc`:

```vim
" Use png1 Docker image
let g:zzvim_r_docker_image = 'png1'

" Configure volume mounts (adjust as needed for png1)
let g:zzvim_r_docker_options = '-v ' . getcwd() . ':/workspace -w /workspace'

" R command (adjust if png1 expects different command)
let g:zzvim_r_docker_command = 'R --no-save --quiet'
```

#### Step 2: Open R file in Vim

```bash
cd ~/prj/d07/zzcollab
vim analysis.R
```

#### Step 3: Launch Docker terminal directly from Vim

```vim
" Press LocalLeader + Shift+R (usually \R)
<LocalLeader>R

" Or use Ex command:
:RDockerTerminal
```

This launches png1 container automatically with the configured settings.

#### Step 4: Execute R code

```vim
" Execute current line or code block
<CR>

" Execute visual selection
V  (select lines)
<CR>

" Execute R Markdown chunk (in .Rmd files)
<LocalLeader>l
```

---

### Option 3: Project-Local Configuration with Makefile Integration

Create a setup that combines both approaches for maximum flexibility.

#### Step 1: Create project-specific Vim configuration

Create `~/prj/d07/zzcollab/.vimrc`:

```vim
" Project-specific zzvim-R configuration for zzcollab

" Use png1 Docker image
let g:zzvim_r_docker_image = 'png1'

" Mount zzcollab directory into container
let g:zzvim_r_docker_options = '-v ' . expand('~/prj/d07/zzcollab') . ':/workspace -w /workspace'

" Standard R command
let g:zzvim_r_docker_command = 'R --no-save --quiet'

" Optional: Add custom Makefile integration command
command! -bar RMake call system('make r &')
```

#### Step 2: Source project config when entering zzcollab

Add to your main `~/.vimrc`:

```vim
" Auto-source project-local vimrc when entering zzcollab
augroup project_zzcollab
    autocmd!
    autocmd BufRead,BufNewFile ~/prj/d07/zzcollab/*.R,~/prj/d07/zzcollab/*.Rmd source ~/prj/d07/zzcollab/.vimrc
augroup END
```

#### Step 3: Two ways to work

**Method A: Use Makefile in separate terminal**
```bash
# Terminal 1:
cd ~/prj/d07/zzcollab
make r

# Terminal 2:
cd ~/prj/d07/zzcollab
vim analysis.R
# In vim: <LocalLeader>dr to force-associate
```

**Method B: Direct launch from Vim**
```bash
cd ~/prj/d07/zzcollab
vim analysis.R
# In vim: <LocalLeader>R to launch png1 container
```

---

## Complete Example Session

Here's a complete example with typical zzcollab workflow:

### Terminal Setup (using tmux or split terminal)

```bash
# Terminal 1 (left pane) - Docker container
cd ~/prj/d07/zzcollab
make r
# Now you have R prompt in png1 container

# Terminal 2 (right pane) - Vim editor
cd ~/prj/d07/zzcollab
vim src/analysis.R
```

### In Vim (Terminal 2)

```vim
" 1. Get terminal buffer ID from terminal 1
"    Switch to terminal 1 briefly and note the buffer name or number
"    Let's say it's buffer #5

" 2. Back in Vim, rename the terminal for proper association
"    Switch to buffer 5 (the docker terminal):
:b 5
:file R-analysis
" Press Ctrl-W p to go back to analysis.R

" 3. Force-associate analysis.R with the Docker terminal
<LocalLeader>dr
" You'll see: "Force-associated with existing Docker terminal: R-analysis"

" 4. Now execute code normally
```

Example R code in `src/analysis.R`:

```r
# Load libraries (press <CR> on this line)
library(tidyverse)

# Create data (press <CR> on this line)
data <- tibble(
    x = 1:10,
    y = rnorm(10)
)

# View data (place cursor on 'data', press <LocalLeader>h)
data

# Create plot (select these lines with V, then <CR>)
ggplot(data, aes(x, y)) +
    geom_point() +
    geom_smooth(method = "lm")

# Define function (cursor anywhere in function, press <CR> - sends whole function)
analyze_data <- function(df) {
    df %>%
        summarize(
            mean_x = mean(x),
            mean_y = mean(y),
            cor = cor(x, y)
        )
}

# Call function (press <CR>)
results <- analyze_data(data)
```

Each `<CR>` sends the code to the png1 container running via `make r`.

---

## Troubleshooting

### Problem: "No terminals found" when pressing `<LocalLeader>dr`

**Solution:**
```vim
" Check what terminals exist
:RListTerminals

" If empty, verify the docker container terminal is in a Vim buffer
:ls!

" Look for the buffer running R, note its number (e.g., #5)
" Switch to it and rename:
:b 5
:file R-analysis
```

### Problem: Terminal name doesn't match

zzvim-R looks for terminals named `R-{filename}`. If your file is `analysis.R`, the terminal should be named `R-analysis`.

**Solution:**
```vim
" In the Docker terminal buffer:
:file R-analysis

" Then force-associate:
<LocalLeader>dr
```

### Problem: Code doesn't execute in png1 container

**Check association:**
```vim
:RShowTerminal
```

Should show: "Current buffer associated with terminal: R-analysis"

**Check terminal is running:**
```vim
:RListTerminals
```

Look for `[running]` status next to your terminal.

### Problem: Volume mount issues - files not visible in container

Your Makefile should mount the workspace directory:

```makefile
r:
    docker run -it --rm \
        -v $(PWD):/workspace \
        -w /workspace \
        png1 R --no-save --quiet
```

Verify in the R session:
```r
getwd()  # Should show /workspace
list.files()  # Should show your project files
```

---

## Advanced: Integration with tmux

### tmux workflow script

Create `~/prj/d07/zzcollab/dev-session.sh`:

```bash
#!/bin/bash
# Start zzcollab development session with tmux

SESSION="zzcollab"

# Create new tmux session
tmux new-session -d -s $SESSION -c ~/prj/d07/zzcollab

# Window 1: Docker R container
tmux rename-window -t $SESSION:1 'docker'
tmux send-keys -t $SESSION:1 'make r' C-m

# Wait for container to start
sleep 2

# Window 2: Vim editor
tmux new-window -t $SESSION:2 -n 'vim' -c ~/prj/d07/zzcollab
tmux send-keys -t $SESSION:2 'vim src/analysis.R' C-m

# Window 3: Shell for git, etc.
tmux new-window -t $SESSION:3 -n 'shell' -c ~/prj/d07/zzcollab

# Attach to session
tmux select-window -t $SESSION:2
tmux attach-session -t $SESSION
```

Usage:
```bash
chmod +x ~/prj/d07/zzcollab/dev-session.sh
~/prj/d07/zzcollab/dev-session.sh
```

Then in Vim window:
- `<LocalLeader>dr` to associate with Docker window
- `<CR>` to execute code

---

## Recommended Setup for zzcollab Project

Based on your workflow, here's the recommended configuration:

### 1. Create `~/prj/d07/zzcollab/.vimrc`:

```vim
" zzcollab project-specific zzvim-R configuration

" Use png1 Docker image
let g:zzvim_r_docker_image = 'png1'

" Mount zzcollab as /workspace
let g:zzvim_r_docker_options = '-v ' . expand('~/prj/d07/zzcollab') . ':/workspace -w /workspace'

" R command
let g:zzvim_r_docker_command = 'R --no-save --quiet'

" Custom terminal naming function for zzcollab
function! s:SetupZZCollabTerminal()
    " If in a terminal buffer, rename to match expected pattern
    if &buftype == 'terminal'
        let fname = expand('#:t:r')
        if !empty(fname)
            execute 'file R-' . fname
        endif
    endif
endfunction

" Auto-setup command
command! ZZCollabSetup call s:SetupZZCollabTerminal()
```

### 2. Add to your main `~/.vimrc`:

```vim
" Auto-load zzcollab configuration
if filereadable(expand('~/prj/d07/zzcollab/.vimrc'))
    autocmd BufRead,BufNewFile ~/prj/d07/zzcollab/*.{R,Rmd,r}
        \ source ~/prj/d07/zzcollab/.vimrc
endif
```

### 3. Typical workflow:

```bash
# Terminal 1:
cd ~/prj/d07/zzcollab
make r

# Terminal 2:
cd ~/prj/d07/zzcollab
vim analysis.R
```

In Vim:
```vim
" One-time setup after opening file:
<LocalLeader>dr

" Then work normally:
<CR>  " Execute code
<LocalLeader>h  " Inspect objects
<LocalLeader>m  " Memory HUD
" etc.
```

---

## Summary

For your zzcollab + png1 setup:

1. **Simplest approach:**
   - Run `make r` in one terminal
   - Open Vim in another terminal
   - Press `<LocalLeader>dr` to force-associate
   - Use `<CR>` to execute code

2. **Most flexible approach:**
   - Create project-local `.vimrc` with png1 configuration
   - Choose between `make r` or `<LocalLeader>R` to launch container
   - All zzvim-R features work identically

3. **Key mapping to remember:**
   - `<LocalLeader>dr` = Force-associate with existing Docker terminal
   - This is your main tool for connecting to `make r` containers

The force-association feature was specifically designed for your use case where you have an existing container launch method (Makefile) and want to connect Vim to it!
