# Docker Integration Test Scenarios

This document outlines test scenarios for the Docker integration feature in zzvim-R.

## Prerequisites

- Docker installed and running
- Docker image available (e.g., `rocker/tidyverse:latest`)
- zzvim-R plugin loaded in Vim/Neovim

## Test Scenario 1: Basic Docker Terminal Launch

**Purpose:** Verify Docker terminal creation works

**Steps:**
1. Open test file: `vim test_docker.R`
2. Press `<LocalLeader>R` (typically `\R`)
3. Verify terminal opens in vertical split
4. Check R prompt appears in Docker container
5. Press `<LocalLeader>q` to return to editor
6. Place cursor on line: `x <- 1:10`
7. Press `<CR>` to execute
8. Switch to terminal and verify `x` is created

**Expected Results:**
- Terminal opens with Docker R session
- Terminal named `R-test_docker`
- Code executes in Docker container
- Working directory is `/workspace`

## Test Scenario 2: Force-Associate with Existing Terminal

**Purpose:** Verify force-association with existing Docker terminal

**Steps:**
1. Manually create Docker terminal: `:vertical term docker run -it --rm -v $(pwd):/workspace -w /workspace rocker/tidyverse R`
2. Rename terminal: `:file R-test_docker`
3. Switch back to editor window
4. Open test file: `vim test_docker.R`
5. Press `<LocalLeader>dr` (force-associate)
6. Execute code with `<CR>`

**Expected Results:**
- Plugin finds existing terminal
- Associates buffer with that terminal
- Message: "Force-associated with existing Docker terminal: R-test_docker"
- Code executes in existing terminal

## Test Scenario 3: Custom Docker Image

**Purpose:** Test custom Docker image configuration

**Configuration in .vimrc:**
```vim
let g:zzvim_r_docker_image = 'rocker/r-ver:4.3.0'
```

**Steps:**
1. Open Vim with above configuration
2. Open test file: `vim test_docker.R`
3. Press `<LocalLeader>R`
4. In R terminal, run: `R.version.string`

**Expected Results:**
- Docker pulls rocker/r-ver:4.3.0 image if not cached
- R version shows 4.3.0
- Terminal works correctly

## Test Scenario 4: Volume Mount Verification

**Purpose:** Verify files are accessible in container

**Configuration in .vimrc:**
```vim
let g:zzvim_r_docker_options = '-v ' . getcwd() . ':/workspace -w /workspace'
```

**Steps:**
1. Create test file in project: `echo "test" > testfile.txt`
2. Open R file: `vim test_docker.R`
3. Press `<LocalLeader>R`
4. In R terminal, run: `list.files()`
5. Run: `readLines("testfile.txt")`

**Expected Results:**
- `list.files()` shows project files including `testfile.txt`
- `readLines()` successfully reads the file
- Container has read/write access to mounted directory

## Test Scenario 5: Multi-File Workflow

**Purpose:** Test buffer-specific terminal isolation

**Steps:**
1. Open first file: `vim file1.R`
2. Press `<LocalLeader>R` → creates `R-file1` terminal
3. Execute: `x <- 100`
4. Open second file in new buffer: `:e file2.R`
5. Press `<LocalLeader>R` → creates `R-file2` terminal
6. Execute: `x <- 200`
7. Switch back to file1.R: `:b file1.R`
8. Check terminal: Should show `x = 100`
9. Switch to file2.R: `:b file2.R`
10. Check terminal: Should show `x = 200`

**Expected Results:**
- Each buffer has its own Docker terminal
- Terminals are isolated (different R sessions)
- Switching buffers automatically uses correct terminal

## Test Scenario 6: All Code Execution Methods

**Purpose:** Verify all execution methods work with Docker

**Steps:**
1. Open `test_docker.R`
2. Press `<LocalLeader>R` to launch Docker terminal
3. Test execution methods:
   - Single line: Place cursor on `x <- 1:10`, press `<CR>`
   - Function block: Place cursor on `calculate_mean <- function(...)`, press `<CR>`
   - Visual selection: Select multiple lines, press `<CR>`
   - If in .Rmd: `<LocalLeader>l` to execute chunk

**Expected Results:**
- All execution methods work identically to regular terminals
- Code executes in Docker container
- Results appear in terminal

## Test Scenario 7: Object Inspection Commands

**Purpose:** Test object inspection with Docker terminals

**Steps:**
1. Open `test_docker.R`
2. Press `<LocalLeader>R`
3. Execute: `df <- data.frame(x=1:5, y=letters[1:5])`
4. Place cursor on `df`
5. Test inspection mappings:
   - `<LocalLeader>h` - head(df)
   - `<LocalLeader>s` - str(df)
   - `<LocalLeader>d` - dim(df)
   - `<LocalLeader>p` - print(df)

**Expected Results:**
- All inspection commands work
- Output appears in Docker terminal
- Commands execute in containerized R session

## Test Scenario 8: HUD Functions with Docker

**Purpose:** Verify HUD displays work with Docker terminals

**Steps:**
1. Open `test_docker.R`
2. Press `<LocalLeader>R`
3. Execute some code to create objects:
   ```r
   x <- 1:100
   df <- data.frame(a=1:50, b=51:100)
   my_list <- list(a=1, b=2, c=3)
   ```
4. Test HUD functions:
   - `<LocalLeader>m` - Memory HUD
   - `<LocalLeader>e` - Data Frame HUD
   - `<LocalLeader>z` - Package HUD
   - `<LocalLeader>0` - Full dashboard

**Expected Results:**
- All HUDs display correctly
- Show objects/packages in Docker container
- Not affected by host R environment

## Test Scenario 9: Error Handling - Docker Not Installed

**Purpose:** Test error handling when Docker unavailable

**Steps:**
1. Temporarily rename Docker binary or ensure it's not in PATH
2. Open R file: `vim test_docker.R`
3. Press `<LocalLeader>R`

**Expected Results:**
- Error message: "zzvim-R: Docker is not installed or not in PATH"
- No terminal created
- Plugin remains functional for regular terminals

## Test Scenario 10: Terminal Status Commands

**Purpose:** Verify terminal association commands work with Docker

**Steps:**
1. Open `test_docker.R`
2. Press `<LocalLeader>R`
3. Run commands:
   - `:RShowTerminal` - Show current association
   - `:RListTerminals` - List all associations
   - `:RSwitchToTerminal` - Switch to Docker terminal

**Expected Results:**
- `:RShowTerminal` shows Docker terminal association
- `:RListTerminals` displays Docker terminals
- `:RSwitchToTerminal` successfully switches focus

## Test Scenario 11: Container Persistence

**Purpose:** Verify container cleanup with --rm flag

**Steps:**
1. Open R file and launch Docker terminal: `<LocalLeader>R`
2. Note container name from terminal
3. Close terminal: `:q` in terminal window
4. Check running containers: `docker ps`
5. Check all containers: `docker ps -a`

**Expected Results:**
- Container not in `docker ps` (stopped)
- Container not in `docker ps -a` (removed by --rm flag)
- Clean automatic cleanup

## Test Scenario 12: Ex Commands

**Purpose:** Test Ex command versions of Docker functions

**Steps:**
1. Open `test_docker.R`
2. Run: `:RDockerTerminal`
3. Verify terminal opens
4. Close terminal
5. Create terminal manually with correct name
6. Run: `:RDockerTerminalForce`
7. Verify association

**Expected Results:**
- `:RDockerTerminal` creates new Docker terminal
- `:RDockerTerminalForce` associates with existing
- Both commands work identically to key mappings

## Test Scenario 13: Tidyverse Image Features

**Purpose:** Test tidyverse-specific functionality

**Configuration:**
```vim
let g:zzvim_r_docker_image = 'rocker/tidyverse:latest'
```

**Steps:**
1. Open R file
2. Press `<LocalLeader>R`
3. Execute code using tidyverse:
   ```r
   library(dplyr)
   library(ggplot2)

   df <- mtcars %>%
     filter(mpg > 20) %>%
     arrange(desc(hp))
   ```

**Expected Results:**
- Tidyverse packages available
- Code executes without installation
- Pipe operator `%>%` works

## Test Scenario 14: Cross-Platform Paths

**Purpose:** Test volume mounting on different operating systems

**Steps (run on Linux, macOS, Windows):**
1. Set up Docker with appropriate volume syntax for OS
2. Open R file
3. Press `<LocalLeader>R`
4. In R, run: `getwd()`
5. In R, run: `list.files()`

**Expected Results:**
- Working directory correctly set to `/workspace`
- Files from host visible in container
- Paths work correctly for the OS

## Test Scenario 15: Rapid Terminal Switching

**Purpose:** Test stability with rapid operations

**Steps:**
1. Open file: `vim test_docker.R`
2. Press `<LocalLeader>R` quickly
3. Immediately press `<LocalLeader>dr`
4. Execute code: `<CR>`
5. Switch to terminal and back rapidly
6. Close and recreate terminal multiple times

**Expected Results:**
- No race conditions
- Associations remain correct
- No orphaned terminals
- Clean error messages if operations fail

## Troubleshooting Common Issues

### Issue: Terminal doesn't appear
- Check Docker is running: `docker ps`
- Verify image exists: `docker images | grep rocker`
- Check terminal split size configuration

### Issue: Files not visible in container
- Verify volume mount in `g:zzvim_r_docker_options`
- Check current directory: `getcwd()` in Vim matches mount source
- Ensure Docker has permission to mount directory

### Issue: Force-associate doesn't find terminal
- Terminal must be named to match pattern (e.g., `R-filename`)
- Use `:file R-filename` to rename terminal
- Check terminal is running, not stopped

### Issue: Package not found in container
- Verify correct Docker image selected
- Some images (r-ver) don't include packages
- Use tidyverse image for common packages
- Or install in container: `install.packages("package")`

## Success Criteria

All test scenarios should:
- Complete without errors
- Show expected results
- Handle edge cases gracefully
- Provide clear error messages when appropriate
- Maintain consistent behavior across Vim and Neovim
