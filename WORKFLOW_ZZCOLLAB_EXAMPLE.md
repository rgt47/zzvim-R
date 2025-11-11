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

### Option 1: Launch Docker R from Vim (Recommended)

This approach launches Docker R directly from Vim using your Makefile.

#### Step 1: Open your R file in Vim

```bash
cd ~/prj/d07/zzcollab
vim analysis.R
```

#### Step 2: Launch Docker R

In Vim:

```vim
ZR            " Shift+Z then Shift+R - launches 'make r'
```

This opens a vertical split with R running in the png1 container.

#### Step 3: Execute R code

Now you can execute R code normally:

```vim
" Place cursor on any line and press Enter
<CR>

" Or select multiple lines visually and press Enter
V  (select lines)
<CR>
```

The code executes in your png1 container!

---

### Option 2: External Terminal + Force-Associate (Alternative)

If you prefer to launch Docker R in a separate terminal before opening Vim:

#### Step 1: Launch png1 container with Makefile

In your first terminal:

```bash
cd ~/prj/d07/zzcollab
make r
```

This opens an R session in the png1 container.

#### Step 2: Open Vim in a second terminal

In your second terminal:

```bash
cd ~/prj/d07/zzcollab
vim analysis.R
```

#### Step 3: Force-associate with existing Docker terminal

Back in your Vim window with `analysis.R`:

```vim
<Space>dr     " Force-associate with make r terminal
```

You should see:
```
Force-associated with existing Docker terminal
```

#### Step 4: Execute R code

```vim
<CR>          " Execute code
```

The code executes in your `make r` container!

---

## Complete Example Session

Here's a complete example with typical zzcollab workflow:

### Open Vim and launch Docker R

```bash
cd ~/prj/d07/zzcollab
vim src/analysis.R
```

### In Vim

```vim
" 1. Launch Docker R
ZR
" A vertical split opens with R running in png1 container

" 2. Now execute code normally
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

## Summary

For your zzcollab + png1 setup:

1. **Recommended approach (simplest):**
   - Open Vim: `vim analysis.R`
   - Launch Docker R: `ZR` (Shift+Z then Shift+R)
   - Execute code: `<CR>`

2. **Alternative approach (external terminal):**
   - Run `make r` in one terminal
   - Open Vim in another terminal
   - Press `<Space>dr` to force-associate
   - Use `<CR>` to execute code

3. **Key mappings:**
   - `ZR` = Launch Docker R via make r (recommended)
   - `<Space>dr` = Force-associate with existing Docker terminal

The `ZR` mapping makes launching Docker R as simple as two keystrokes, and it automatically runs your Makefile's `r` target!
