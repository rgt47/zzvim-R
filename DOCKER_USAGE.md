# Docker Integration for zzvim-R

This document explains how to use zzvim-R with Docker containers for isolated, reproducible R environments.

## Overview

The Docker integration allows you to:
- Run R in isolated Docker containers
- Use specific R versions and package configurations
- Share code with containers via volume mounts
- Force-associate buffers with existing Docker terminals

## Quick Start

### Basic Usage

1. **Launch R in Docker container via 'make r':**
   ```vim
   ZR
   " or
   :RDockerTerminal
   ```

2. **Execute R code** (works the same as regular terminals):
   ```vim
   <CR>  " Execute current line/function/block
   ```

3. **Force-associate with existing Docker terminal:**
   ```vim
   <LocalLeader>dr
   " or
   :RDockerTerminalForce
   ```

## Configuration

**ZR now runs `make r` instead of building docker commands.**

Configure your Docker setup in your Makefile:

```makefile
# Example Makefile target
r:
	docker run -it --rm \
		-v $(PWD):/workspace \
		-v ~/prj/d07/zzcollab:/zzcollab \
		-w /workspace \
		png1 R --no-save --quiet
```

You can customize:
- Docker image (png1, rocker/tidyverse, etc.)
- Volume mounts (-v flags)
- Environment variables (-e flags)
- Working directory (-w flag)
- R startup options (R --no-save --quiet, R --vanilla, etc.)

## Common Workflows

### Workflow 1: New Docker Terminal for Each File

1. Open R file: `vim analysis.R`
2. Launch Docker R: `ZR`
3. Execute code: `<CR>` on any line
4. Terminal automatically named `R-analysis`

### Workflow 2: Manually Created Docker Terminal

If you already have a Docker terminal running:

1. Manually start Docker: `:vertical term make r`
2. Open R file: `vim analysis.R`
3. Force-associate: `<LocalLeader>dr`
4. Execute code: `<CR>` works with existing terminal

### Workflow 3: Multiple Files with Shared Docker Environment

**Option A: Separate containers per file**
- Open `file1.R` → `ZR` → get `R-file1`
- Open `file2.R` → `ZR` → get `R-file2`
- Each file has isolated environment

**Option B: Shared container** (requires manual setup)
- Start one Docker terminal manually (`:term make r`)
- For each file: open file → `<LocalLeader>dr` → select same terminal

### Workflow 4: Project-Specific Package Libraries

```vim
" In .vimrc or project-local config
let g:zzvim_r_docker_options = '-v ' . getcwd() . ':/workspace -v ' . getcwd() . '/rlibs:/rlibs -w /workspace -e R_LIBS_USER=/rlibs'
```

Then in R:
```r
# Packages install to /rlibs which persists across container restarts
install.packages("dplyr")
```

## Key Mappings

| Mapping | Command | Description |
|---------|---------|-------------|
| `ZR` | `:RDockerTerminal` | Launch Docker R via 'make r' |
| `<LocalLeader>dr` | `:RDockerTerminalForce` | Force-associate with existing Docker terminal |
| `<LocalLeader>r` | `:ROpenTerminal` | Launch regular (non-Docker) R terminal |
| `<CR>` | - | Execute code in associated terminal (Docker or regular) |

## Advanced Examples

### Example 1: Specific R Version with Custom Packages

```vim
" .vimrc configuration
let g:zzvim_r_docker_image = 'rocker/r-ver:4.1.0'
let g:zzvim_r_docker_options = '-v ' . getcwd() . ':/workspace -v ~/custom-rlibs:/rlibs -w /workspace -e R_LIBS_USER=/rlibs'
```

### Example 2: Database Connection

```vim
" Mount credentials and connect to host network
let g:zzvim_r_docker_options = '--network=host -v ' . getcwd() . ':/workspace -v ~/.pgpass:/root/.pgpass -w /workspace'
```

### Example 3: GPU Support

```vim
" Use NVIDIA runtime for GPU-accelerated R packages
let g:zzvim_r_docker_options = '--gpus all -v ' . getcwd() . ':/workspace -w /workspace'
let g:zzvim_r_docker_image = 'nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04'
```

## Troubleshooting

### Docker not found

**Error:** `Docker is not installed or not in PATH`

**Solution:**
- Install Docker: https://docs.docker.com/get-docker/
- Ensure Docker is in PATH: `which docker`
- For Docker Desktop, ensure it's running

### Permission denied on volume mounts

**Error:** Permission issues accessing files in container

**Solution:**
```vim
" Add user mapping to Docker options
let g:zzvim_r_docker_options = '-v ' . getcwd() . ':/workspace -w /workspace -u ' . system('id -u') . ':' . system('id -g')
```

### Container exits immediately

**Problem:** Terminal closes right after opening

**Solution:**
- Ensure Docker image exists: `docker pull rocker/tidyverse:latest`
- Check Docker options for syntax errors
- Verify R command is correct in image

### Cannot associate with existing terminal

**Problem:** `<LocalLeader>dr` doesn't find terminal

**Solution:**
- Ensure terminal buffer name matches expected format (e.g., `R-filename`)
- Use `:RListTerminals` to see all associations
- Terminal must be running (not stopped)

### File not found in container

**Problem:** R can't find files in current directory

**Solution:**
```vim
" Ensure working directory is mounted and set
let g:zzvim_r_docker_options = '-v ' . getcwd() . ':/workspace -w /workspace'
```

## Tips and Best Practices

1. **Use named volumes for packages:**
   ```vim
   let g:zzvim_r_docker_options = '-v rlibs:/usr/local/lib/R/site-library -v ' . getcwd() . ':/workspace -w /workspace'
   ```

2. **Pin R versions for reproducibility:**
   ```vim
   let g:zzvim_r_docker_image = 'rocker/r-ver:4.3.1'  " Specific version, not :latest
   ```

3. **Use .Rprofile in project:**
   ```r
   # .Rprofile in project root
   options(repos = c(CRAN = "https://cloud.r-project.org"))
   .libPaths("/rlibs")
   ```

4. **Clean up stopped containers:**
   The `--rm` flag is used by default, so containers are automatically removed on exit.

5. **Check terminal status:**
   ```vim
   :RShowTerminal     " See current buffer's terminal
   :RListTerminals    " See all associations
   ```

## Integration with Existing Workflows

All existing zzvim-R features work identically with Docker terminals:

- Smart code execution: `<CR>`
- Chunk navigation: `<LocalLeader>j/k`
- Chunk execution: `<LocalLeader>l`
- Object inspection: `<LocalLeader>h/s/d/p`, etc.
- HUD displays: `<LocalLeader>m/e/z/v/x/a/0`
- Visual selection: Select code → `<CR>`

The only difference is the R environment runs inside a Docker container instead of on the host system.

## Comparison: Docker vs Regular Terminals

| Feature | Regular Terminal | Docker Terminal |
|---------|-----------------|-----------------|
| Setup | Requires R installed | Requires Docker + image |
| Isolation | System R version | Containerized environment |
| Reproducibility | Depends on system | Fully reproducible |
| Performance | Native speed | Slight overhead |
| Package conflicts | System-wide | Container-isolated |
| Cleanup | Manual | Automatic with --rm |
| File access | Direct | Via volume mounts |

Choose Docker when you need:
- Specific R versions
- Isolated package environments
- Reproducible analysis
- Multiple R versions simultaneously

Choose regular terminals when you need:
- Maximum performance
- Simpler setup
- Direct file system access
- No containerization overhead
