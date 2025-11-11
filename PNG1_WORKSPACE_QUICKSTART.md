# png1 Workspace Quick Start Guide

**Your Setup:**
- Vim config: `~/.vimrc`
- LocalLeader: `<Space>`
- **zzcollab codebase:** `~/prj/d07/zzcollab` (R package/library code)
- **png1 workspace:** `~/prj/png1` (analysis work)
- Docker image: `png1`
- Launch: `make r` (from workspace directory)

## The Simple Workflow

### Step 1: Open R file in Vim
```bash
cd ~/prj/png1
vim analysis.R
```

### Step 2: Launch Docker R and execute

**In Vim:**
```vim
ZR            " Launch Docker R via 'make r' (Shift+Z then Shift+R)
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

## Alternative: External Terminal Workflow

If you prefer to launch Docker R externally before opening Vim:

```bash
# Terminal 1:
cd ~/prj/png1
make r                # Launches png1 with R

# Terminal 2:
cd ~/prj/png1
vim analysis.R

# In Vim:
<Space>dr             # Force-associate with make r terminal
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

## Launching Docker R from Vim

Instead of using external terminals, you can launch Docker R directly from Vim:

```vim
ZR            " Launches png1 via 'make r' (Shift+Z then Shift+R)
```

This is the recommended workflow - simpler and faster than external terminals.

## Key Mappings (LocalLeader = Space)

| Key | Action |
|-----|--------|
| `ZR` | **Launch Docker R via make r** ⭐ |
| `<Space>dr` | Force-associate with existing Docker terminal |
| `<CR>` | Execute current line/function/block |
| `<Space>h` | head(object under cursor) |
| `<Space>s` | str(object) |
| `<Space>m` | Memory HUD |
| `<Space>e` | Data frames HUD |
| `<Space>0` | Full HUD dashboard |

## Complete Example Session

**Open your R file:**
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
" Launch Docker R
ZR                     " Shift+Z then Shift+R

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

In Vim:
```vim
ZR                        " Launch Docker R
<CR>                      " Execute code
```

### Scenario 2: Developing zzcollab functions

**Edit zzcollab code:**
```bash
cd ~/prj/d07/zzcollab
vim R/new_function.R
```

**Test in png1 workspace:**
```bash
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

In Vim:
```vim
ZR                        " Launch Docker R
<CR>                      " Execute - tests your zzcollab code with png1 data!
```

### Scenario 3: Multiple analysis files in png1

Open multiple files in separate Vim tabs or windows:

```bash
cd ~/prj/png1
vim -p analysis1.R analysis2.R
```

In first tab:
```vim
ZR                        " Launch Docker R for analysis1
<CR>                      " Execute code
```

In second tab (gt to switch):
```vim
ZR                        " Launch Docker R for analysis2 (separate container)
<CR>                      " Execute code
```

Or share one container:
```vim
" In first tab:
ZR                        " Launch Docker R

" In second tab:
<Space>dr                 " Select existing terminal from first tab
                          " Both tabs share the same R environment
```

## Quick Reference Card

```
WORKSPACE PATHS
---------------
Host: ~/prj/png1         → Container: /workspace  (working dir)
Host: ~/prj/d07/zzcollab → Container: /zzcollab   (code library)

DOCKER TERMINAL
---------------
ZR           Launch png1 via make r ⭐
<Space>dr    Force-associate with existing Docker terminal

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
vim analysis.R                 # Edit R code
ZR                             # Launch Docker R
<CR>                           # Execute code as needed
```

## Configuration Summary

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
- **Launch Docker R:** `ZR` in Vim (runs `make r` automatically)
- **Execute:** `<CR>` on any code

The key insight: `ZR` launches Docker R with both directories mounted via your Makefile, so you can use zzcollab functions while working with png1 data!
