# png1 + zzcollab Setup Summary

## Directory Structure

```
~/prj/
├── png1/                    # Your workspace (analysis work) ⭐
│   ├── Makefile            # Contains 'make r' to launch png1
│   ├── analysis.R          # Your analysis scripts
│   ├── data/               # Your data files
│   ├── output/             # Results and outputs
│   └── ...
│
└── d07/zzcollab/           # R code library
    ├── R/                  # R functions you've written
    ├── DESCRIPTION
    └── ...
```

## Key Concept

- **Work from:** `~/prj/png1` (your analysis workspace)
- **Code library:** `~/prj/d07/zzcollab` (R functions/package)
- **Container mounts both:** Access zzcollab code while working in png1

## Configuration Files

### Create/Update `~/prj/png1/Makefile`

```makefile
# Launch R in png1 container
# Mounts both workspace and zzcollab library
r:
	docker run -it --rm \
		-v $(PWD):/workspace \
		-v $(HOME)/prj/d07/zzcollab:/zzcollab \
		-w /workspace \
		png1 R --no-save --quiet
```

## Daily Workflow

```bash
cd ~/prj/png1
vim analysis.R
```

### In Vim

```vim
" Launch Docker R
ZR                     " Shift+Z then Shift+R

" Then execute code normally
<CR>                   " On any line
```

## Example R Code in ~/prj/png1/analysis.R

```r
# Access zzcollab functions (mounted at /zzcollab)
source("/zzcollab/R/data_cleaning.R")
source("/zzcollab/R/plotting.R")

# Or if zzcollab is installed as package:
library(zzcollab)

# Load data from workspace (working dir is /workspace)
library(tidyverse)
data <- read_csv("data/survey_results.csv")

# Use zzcollab functions
cleaned <- clean_survey_data(data)  # Function from zzcollab

# Analyze
summary_stats <- cleaned %>%
    group_by(category) %>%
    summarize(mean_score = mean(score))

# Save results in workspace
write_csv(summary_stats, "output/summary.csv")

# Create plots using zzcollab functions
plot_survey_results(summary_stats)  # Function from zzcollab
ggsave("output/results_plot.png")
```

## Container Paths

| Host Path | Container Path | Purpose |
|-----------|----------------|---------|
| `~/prj/png1` | `/workspace` | Working directory (your data & scripts) |
| `~/prj/d07/zzcollab` | `/zzcollab` | Code library (R functions) |

## Verify Setup in R

After launching with `make r`:

```r
# Check working directory
getwd()
# [1] "/workspace"

# Check workspace files
list.files()
# Should show: analysis.R, data/, output/, etc.

# Check zzcollab is accessible
list.files("/zzcollab")
# Should show: R/, DESCRIPTION, etc.

# Test sourcing a function
source("/zzcollab/R/my_function.R")
```

## Key Mappings (LocalLeader = Space)

| Mapping | Action |
|---------|--------|
| `ZR` | **Launch Docker R via make r** ⭐ |
| `<Space>dr` | Force-associate with existing Docker terminal |
| `<CR>` | Execute line/function/block |
| `<Space>h` | head(object) |
| `<Space>s` | str(object) |
| `<Space>d` | dim(object) |
| `<Space>m` | Memory HUD |
| `<Space>e` | Data frames HUD |
| `<Space>0` | Full HUD dashboard |

## Common Scenarios

### Scenario 1: Regular Analysis

```bash
cd ~/prj/png1
vim analysis.R
```

In Vim:
```vim
ZR            " Launch Docker R
<CR>          " Execute code
```

### Scenario 2: Multiple Analysis Files

```bash
cd ~/prj/png1
vim -p analysis1.R analysis2.R
```

In first tab:
```vim
ZR            " Launch Docker R for analysis1
<CR>          " Execute code
```

In second tab (gt to switch):
```vim
ZR            " Launch Docker R for analysis2 (separate container)
<CR>          " Execute code
```

Or share one container:
```vim
" In first tab:
ZR            " Launch Docker R

" In second tab:
<Space>dr     " Select existing terminal from first tab
              " Both tabs share the same R environment
```

### Scenario 3: Testing zzcollab Functions

Edit zzcollab code:
```bash
vim ~/prj/d07/zzcollab/R/new_function.R
```

Test in png1 workspace:
```bash
cd ~/prj/png1
vim test_new_function.R
```

In test file:
```r
source("/zzcollab/R/new_function.R")
test_data <- read_csv("data/test.csv")
result <- new_function(test_data)
```

Execute with `<CR>` - no need to rebuild anything!

## Troubleshooting

### Problem: zzcollab functions not found

```r
# Check zzcollab is mounted
list.files("/zzcollab")

# Try full path
source("/zzcollab/R/my_function.R")

# Check file exists
file.exists("/zzcollab/R/my_function.R")
```

### Problem: Data files not found

```r
# Check working directory
getwd()
# Should be: /workspace

# Check workspace files
list.files()

# Use relative paths
read_csv("data/file.csv")  # Not /workspace/data/file.csv
```

### Problem: Can't launch Docker terminal

```vim
" Check make is available
:!which make

" Test make r outside vim
:!make r

" Check Makefile exists
:!ls -la Makefile

" Try manual launch
:vert term make r
```

## Quick Reference

```
WORKFLOW
--------
cd ~/prj/png1           # 1. Go to workspace
vim analysis.R          # 2. Edit code
ZR                      # 3. Launch Docker R
<CR>                    # 4. Execute

PATHS IN R
----------
source("/zzcollab/R/utils.R")        # zzcollab functions
read_csv("data/input.csv")           # workspace data
write_csv(result, "output/out.csv")  # workspace output

KEY COMMANDS
------------
ZR          → Launch Docker R via make r
<CR>        → Execute code
<Space>h    → head(object)
<Space>m    → Memory HUD
```

## Documentation Files

- **`PNG1_WORKSPACE_QUICKSTART.md`** - Detailed guide
- **`PNG1_CHEATSHEET.txt`** - One-page reference (this is your go-to)
- **`PNG1_SETUP_SUMMARY.md`** - This file (setup overview)

## Next Steps

1. **Add config to ~/.vimrc** (see above)
2. **Update Makefile in ~/prj/png1** (see above)
3. **Test the setup:**
   ```bash
   cd ~/prj/png1
   make r                    # Terminal 1
   vim analysis.R            # Terminal 2
   # In vim: <Space>dr then <CR>
   ```

4. **Keep handy:** `PNG1_CHEATSHEET.txt` for daily reference

You're all set! The key mapping `<Space>dr` force-associates your R file with the running png1 container, then `<CR>` executes code.
