# png1 Workspace Quick Start Guide

**Your Setup:**
- Vim config: `~/.vimrc`
- LocalLeader: `<Space>`
- **zzcollab codebase:** `~/prj/d07/zzcollab` (R package/library code)
- **png1 workspace:** `~/prj/png1` (analysis work)
- Docker image: `png1`
- Launch: `make r` (from workspace directory)

## The 3-Step Workflow

### Step 1: Launch png1 container (Terminal 1)
```bash
cd ~/prj/png1
make r
```

### Step 2: Open R file in Vim (Terminal 2)
```bash
cd ~/prj/png1
vim analysis.R
```

### Step 3: Associate and execute

**In Vim:**
```vim
<Space>dr     " Force-associate (Space + d + r)
<CR>          " Execute code
```

## Directory Structure

```
~/prj/
├── d07/zzcollab/        # R package/library code
│   ├── R/               # Package R functions
│   ├── DESCRIPTION
│   └── ...
│
└── png1/                # Your analysis workspace ⭐
    ├── Makefile         # Contains 'make r' target
    ├── analysis.R       # Your analysis scripts
    ├── data/            # Your data files
    ├── output/          # Results
    └── ...
```

## Typical tmux Workflow

```bash
# Start in workspace
cd ~/prj/png1
tmux

# In tmux:
Ctrl-b %              # Split vertically

# Left pane:
make r                # Launches png1 with R

# Right pane (Ctrl-b →):
vim analysis.R        # Edit your analysis code

# In Vim:
<Space>dr             # One-time association
<CR>                  # Execute code as needed
```

## Using zzcollab Code in png1 Workspace

Your Makefile should mount BOTH directories:

```makefile
r:
    docker run -it --rm \
        -v $(PWD):/workspace \
        -v ~/prj/d07/zzcollab:/zzcollab \
        -w /workspace \
        png1 R --no-save --quiet
```

Then in your R code:
```r
# Load zzcollab functions
source("/zzcollab/R/my_functions.R")

# Or if zzcollab is installed as package in png1:
library(zzcollab)

# Now work with your data
data <- read_csv("data/my_data.csv")
result <- process_data(data)  # Function from zzcollab
```

## Add png1 Config to ~/.vimrc

Add this to your `~/.vimrc`:

```vim
" png1 workspace configuration
autocmd BufRead,BufNewFile ~/prj/png1/*.R,~/prj/png1/*.Rmd
    \ let g:zzvim_r_docker_image = 'png1' |
    \ let g:zzvim_r_docker_options = '-v ' . expand('~/prj/png1') . ':/workspace -v ~/prj/d07/zzcollab:/zzcollab -w /workspace'
```

With this config, you can optionally launch directly from Vim:
```vim
<Space>R      " Launches png1 with both directories mounted
```

## Key Mappings (LocalLeader = Space)

| Key | Action |
|-----|--------|
| `<Space>dr` | **Force-associate with make r terminal** |
| `<Space>R` | Launch new Docker terminal (alternative) |
| `<CR>` | Execute current line/function/block |
| `<Space>h` | head(object under cursor) |
| `<Space>s` | str(object) |
| `<Space>m` | Memory HUD |
| `<Space>e` | Data frames HUD |
| `<Space>0` | Full HUD dashboard |

## Complete Example Session

**Terminal 1 (or left tmux pane):**
```bash
cd ~/prj/png1
make r
```

You see:
```
R version X.X.X ...
>
```

**Terminal 2 (or right tmux pane):**
```bash
cd ~/prj/png1
vim analysis.R
```

**In Vim editing `~/prj/png1/analysis.R`:**

```r
# Load zzcollab functions
source("/zzcollab/R/helpers.R")

# Load data from png1 workspace
library(tidyverse)
data <- read_csv("/workspace/data/survey_data.csv")

# Use zzcollab function
cleaned_data <- clean_survey_data(data)  # From zzcollab

# Analyze in workspace
summary_stats <- cleaned_data %>%
    group_by(category) %>%
    summarize(
        mean_score = mean(score),
        n = n()
    )

# Save results in workspace
write_csv(summary_stats, "/workspace/output/summary.csv")
```

**Execute the code:**
```vim
" First time: Associate with docker terminal
<Space>dr              " Once per file

" Execute line by line or blocks
<CR>                   " On any line
```

## Working Directory in Container

In your png1 container:
```r
getwd()
# [1] "/workspace"  (which is ~/prj/png1 on host)

list.files()
# Shows: analysis.R, data/, output/, etc. (from ~/prj/png1)

list.files("/zzcollab")
# Shows: R/, DESCRIPTION, etc. (from ~/prj/d07/zzcollab)
```

## Makefile Example for png1 Workspace

`~/prj/png1/Makefile`:
```makefile
# Launch R in png1 container
# Mounts both workspace and zzcollab code
r:
	docker run -it --rm \
		-v $(PWD):/workspace \
		-v $(HOME)/prj/d07/zzcollab:/zzcollab \
		-w /workspace \
		png1 R --no-save --quiet

# Alternative: Install zzcollab as package first
r-with-lib:
	docker run -it --rm \
		-v $(PWD):/workspace \
		-v $(HOME)/prj/d07/zzcollab:/zzcollab \
		-w /workspace \
		-e R_LIBS_USER=/workspace/rlibs \
		png1 \
		bash -c "cd /zzcollab && R CMD INSTALL . && cd /workspace && R --no-save --quiet"
```

## Troubleshooting

**"Files not found" in R**
```r
# Check working directory
getwd()
# Should be: /workspace

# Check png1 files are visible
list.files()
# Should show your analysis.R, data/, etc.

# Check zzcollab code is visible
list.files("/zzcollab")
# Should show R/, DESCRIPTION, etc.
```

**Makefile volume mounts**

Your `make r` target must mount both:
```makefile
-v $(PWD):/workspace              # png1 workspace → /workspace
-v ~/prj/d07/zzcollab:/zzcollab   # zzcollab code → /zzcollab
```

**Cannot source zzcollab functions**
```r
# Try full path
source("/zzcollab/R/my_function.R")

# Check if file exists
file.exists("/zzcollab/R/my_function.R")

# List available files
list.files("/zzcollab/R")
```

## Workflow Scenarios

### Scenario 1: Analysis with zzcollab functions

```bash
# Terminal 1:
cd ~/prj/png1
make r

# Terminal 2:
cd ~/prj/png1
vim analysis.R
```

In `analysis.R`:
```r
# Source zzcollab utilities
source("/zzcollab/R/data_utils.R")
source("/zzcollab/R/plot_utils.R")

# Work with png1 data
data <- load_survey_data()  # Function from zzcollab
plot_results(data)           # Function from zzcollab
```

### Scenario 2: Developing zzcollab functions

**Edit zzcollab code:**
```bash
# Terminal 3 (or new tmux window):
cd ~/prj/d07/zzcollab
vim R/new_function.R
```

**Test in png1 workspace:**
```bash
# Terminal 2 (png1 workspace):
cd ~/prj/png1
vim test_new_function.R
```

In `test_new_function.R`:
```r
# Load the new function
source("/zzcollab/R/new_function.R")

# Test with png1 data
test_data <- read_csv("data/test.csv")
result <- new_function(test_data)
```

Execute with `<CR>` - tests your zzcollab code with png1 data!

### Scenario 3: Multiple analysis files in png1

```bash
cd ~/prj/png1
make r                    # Terminal 1: One R session

# Open multiple files:
vim analysis1.R           # Terminal 2
vim analysis2.R           # Terminal 3
```

In each Vim:
```vim
<Space>dr                 " Associate with same docker terminal
" All files share the R session - can share variables!
```

## Quick Reference Card

```
WORKSPACE PATHS
---------------
Host: ~/prj/png1         → Container: /workspace  (working dir)
Host: ~/prj/d07/zzcollab → Container: /zzcollab   (code library)

DOCKER TERMINAL
---------------
<Space>dr    Force-associate with make r terminal ⭐
<Space>R     Launch png1 directly from Vim

CODE EXECUTION
--------------
<CR>         Execute line/function/block
V + <CR>     Execute visual selection

OBJECT INSPECTION
-----------------
<Space>h     head()
<Space>s     str()
<Space>d     dim()
<Space>m     Memory HUD
<Space>e     Data frames HUD

TYPICAL WORKFLOW
----------------
cd ~/prj/png1                  # Go to workspace
make r                         # Terminal 1: Launch png1
vim analysis.R                 # Terminal 2: Edit
<Space>dr                      # Associate once
<CR>                           # Execute as needed
```

## Configuration Summary

**~/.vimrc:**
```vim
" png1 workspace with zzcollab access
autocmd BufRead,BufNewFile ~/prj/png1/*.R,~/prj/png1/*.Rmd
    \ let g:zzvim_r_docker_image = 'png1' |
    \ let g:zzvim_r_docker_options = '-v ' . expand('~/prj/png1') . ':/workspace -v ~/prj/d07/zzcollab:/zzcollab -w /workspace'
```

**~/prj/png1/Makefile:**
```makefile
r:
    docker run -it --rm \
        -v $(PWD):/workspace \
        -v $(HOME)/prj/d07/zzcollab:/zzcollab \
        -w /workspace \
        png1 R --no-save --quiet
```

**Typical R file in ~/prj/png1:**
```r
# Load zzcollab functions
source("/zzcollab/R/helpers.R")

# Load workspace data
data <- read_csv("/workspace/data/my_data.csv")
# OR just:
data <- read_csv("data/my_data.csv")  # relative to /workspace

# Process and save
results <- process_data(data)
write_csv(results, "output/results.csv")
```

## Summary

- **Work from:** `~/prj/png1` (your workspace)
- **Code library:** `~/prj/d07/zzcollab` (mounted at `/zzcollab`)
- **Launch:** `make r` in png1 workspace
- **Associate:** `<Space>dr` in Vim
- **Execute:** `<CR>` on any code

The key insight: Your Makefile mounts both directories, so you can use zzcollab functions while working with png1 data!
