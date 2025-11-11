# Docker Integration Test Scenarios

This document outlines test scenarios for the Docker integration feature in zzvim-R.

## Prerequisites

- Docker installed and running
- Makefile with 'r' target configured
- zzvim-R plugin loaded in Vim/Neovim

## Test Scenario 1: Basic Docker Terminal Launch via ZR

**Purpose:** Verify Docker terminal creation via `make r` works

**Setup:** Create Makefile in test directory:
```makefile
r:
	docker run -it --rm -v $(PWD):/workspace -w /workspace rocker/tidyverse R --no-save --quiet
```

**Steps:**
1. Open test file: `vim test_docker.R`
2. Press `ZR` (Shift+Z then Shift+R)
3. Verify terminal opens in vertical split
4. Check R prompt appears in Docker container
5. Switch back to editor
6. Place cursor on line: `x <- 1:10`
7. Press `<CR>` to execute
8. Switch to terminal and verify `x` is created

**Expected Results:**
- Terminal opens with Docker R session via `make r`
- Terminal automatically named `R-test_docker`
- Code executes in Docker container
- Working directory is `/workspace`

## Test Scenario 2: Force-Associate with Manually Created Terminal

**Purpose:** Verify force-association with existing Docker terminal

**Steps:**
1. Manually create Docker terminal: `:vertical term make r`
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

## Test Scenario 3: Multi-File Workflow

**Purpose:** Test buffer-specific terminal isolation

**Steps:**
1. Open first file: `vim file1.R`
2. Press `ZR` → creates `R-file1` terminal
3. Execute: `x <- 100`
4. Open second file in new buffer: `:e file2.R`
5. Press `ZR` → creates `R-file2` terminal
6. Execute: `x <- 200`
7. Switch back to file1.R: `:b file1.R`
8. Check terminal: Should show `x = 100`
9. Switch to file2.R: `:b file2.R`
10. Check terminal: Should show `x = 200`

**Expected Results:**
- Each buffer has its own Docker terminal
- Terminals are isolated (different R sessions)
- Switching buffers automatically uses correct terminal

## Test Scenario 4: All Code Execution Methods

**Purpose:** Verify all execution methods work with Docker

**Steps:**
1. Open `test_docker.R`
2. Press `ZR` to launch Docker terminal
3. Test execution methods:
   - Single line: Place cursor on `x <- 1:10`, press `<CR>`
   - Function block: Place cursor on `calculate_mean <- function(...)`, press `<CR>`
   - Visual selection: Select multiple lines, press `<CR>`
   - If in .Rmd: `<LocalLeader>l` to execute chunk

**Expected Results:**
- All execution methods work identically to regular terminals
- Code executes in Docker container
- Results appear in terminal

## Test Scenario 5: Object Inspection Commands

**Purpose:** Test object inspection with Docker terminals

**Steps:**
1. Open `test_docker.R`
2. Press `ZR`
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

## Test Scenario 6: HUD Functions with Docker

**Purpose:** Verify HUD displays work with Docker terminals

**Steps:**
1. Open `test_docker.R`
2. Press `ZR`
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

## Test Scenario 7: Error Handling - Make Not Available

**Purpose:** Test error handling when make unavailable

**Steps:**
1. Temporarily rename make binary or ensure it's not in PATH
2. Open R file: `vim test_docker.R`
3. Press `ZR`

**Expected Results:**
- Error message: "make is not installed or not in PATH"
- No terminal created
- Plugin remains functional for regular terminals

## Test Scenario 8: Terminal Status Commands

**Purpose:** Verify terminal association commands work with Docker

**Steps:**
1. Open `test_docker.R`
2. Press `ZR`
3. Run commands:
   - `:RShowTerminal` - Show current association
   - `:RListTerminals` - List all associations
   - `:RSwitchToTerminal` - Switch to Docker terminal

**Expected Results:**
- `:RShowTerminal` shows Docker terminal association
- `:RListTerminals` displays Docker terminals
- `:RSwitchToTerminal` successfully switches focus

## Test Scenario 9: Container Persistence

**Purpose:** Verify container cleanup with --rm flag

**Steps:**
1. Open R file and launch Docker terminal: `ZR`
2. Note container name from terminal
3. Close terminal: `:q` in terminal window
4. Check running containers: `docker ps`
5. Check all containers: `docker ps -a`

**Expected Results:**
- Container not in `docker ps` (stopped)
- Container not in `docker ps -a` (removed by --rm flag)
- Clean automatic cleanup

## Test Scenario 10: Ex Commands

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
- `:RDockerTerminal` creates new Docker terminal via `make r`
- `:RDockerTerminalForce` associates with existing
- Both commands work identically to key mappings

## Test Scenario 11: Custom Makefile Configuration

**Purpose:** Test different Makefile configurations

**Test A: Multiple Volume Mounts**
```makefile
r:
	docker run -it --rm \
		-v $(PWD):/workspace \
		-v ~/data:/data \
		-v ~/code:/code \
		-w /workspace \
		rocker/tidyverse R --no-save --quiet
```

**Test B: Custom Image**
```makefile
r:
	docker run -it --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		my-custom-r-image R --no-save --quiet
```

**Test C: Environment Variables**
```makefile
r:
	docker run -it --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		-e R_LIBS_USER=/workspace/rlibs \
		rocker/tidyverse R --no-save --quiet
```

**Steps for each test:**
1. Update Makefile
2. Open `vim test.R`
3. Press `ZR`
4. Verify configuration in R terminal

**Expected Results:**
- Each Makefile configuration works correctly
- Volume mounts, images, and environment variables respected
- `make r` command properly executed

## Test Scenario 12: Rapid Terminal Switching

**Purpose:** Test stability with rapid operations

**Steps:**
1. Open file: `vim test_docker.R`
2. Press `ZR` quickly
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
- Verify Makefile exists with 'r' target
- Test `make r` directly in shell
- Check terminal split size configuration

### Issue: Files not visible in container
- Verify volume mount in Makefile (-v flags)
- Check current directory: `getcwd()` in Vim matches mount source
- Ensure Docker has permission to mount directory

### Issue: Force-associate doesn't find terminal
- Terminal must be named to match pattern (e.g., `R-filename`)
- Use `:file R-filename` to rename terminal
- Check terminal is running, not stopped

### Issue: Package not found in container
- Verify correct Docker image in Makefile
- Some images (r-ver) don't include packages
- Use tidyverse image for common packages
- Or install in container: `install.packages("package")`

### Issue: make command fails
- Test `make r` directly in terminal outside Vim
- Check Makefile syntax (tabs vs spaces)
- Verify Docker image exists: `docker images`
- Check Docker daemon is running

## Success Criteria

All test scenarios should:
- Complete without errors
- Show expected results
- Handle edge cases gracefully
- Provide clear error messages when appropriate
- Maintain consistent behavior across Vim and Neovim
