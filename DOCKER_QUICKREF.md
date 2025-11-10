# Docker Quick Reference for zzvim-R

## Key Mappings

| Mapping | Action |
|---------|--------|
| `<LocalLeader>R` | Launch R in Docker container (new) |
| `<LocalLeader>dr` | Force-associate with existing Docker terminal |
| `<LocalLeader>r` | Launch regular (non-Docker) R terminal |

## Ex Commands

| Command | Action |
|---------|--------|
| `:RDockerTerminal` | Launch R in Docker container |
| `:RDockerTerminalForce` | Force-associate with existing Docker terminal |

## Configuration (in .vimrc)

```vim
" Docker image (default: rocker/tidyverse:latest)
let g:zzvim_r_docker_image = 'rocker/tidyverse:latest'

" Docker options (default: mount current directory)
let g:zzvim_r_docker_options = '-v ' . getcwd() . ':/workspace -w /workspace'

" R command in container (default: R --no-save --quiet)
let g:zzvim_r_docker_command = 'R --no-save --quiet'
```

## Common Workflows

### New Docker Terminal
```vim
vim analysis.R
<LocalLeader>R      " Launch Docker R
<CR>                " Execute code
```

### Reuse Existing Terminal
```vim
" Terminal already running:
vim analysis.R
<LocalLeader>dr     " Force-associate
<CR>                " Execute in existing terminal
```

### Custom Image
```vim
" In .vimrc:
let g:zzvim_r_docker_image = 'rocker/r-ver:4.3.0'

" Then use normally:
<LocalLeader>R
```

### Mount Additional Directory
```vim
" In .vimrc:
let g:zzvim_r_docker_options = '-v ~/data:/data -v ' . getcwd() . ':/workspace -w /workspace'
```

## All Existing Features Work

After launching Docker terminal, use all normal zzvim-R features:

- `<CR>` - Execute code
- `<LocalLeader>h/s/d/p` - Object inspection
- `<LocalLeader>j/k/l` - Chunk navigation (in .Rmd)
- `<LocalLeader>m/e/z/0` - HUD displays
- Visual selection → `<CR>` - Execute selection

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Docker not in PATH" | Install Docker and ensure it's running |
| Files not found | Check volume mount in `g:zzvim_r_docker_options` |
| Terminal closes immediately | Verify image exists: `docker pull rocker/tidyverse` |
| Force-associate fails | Terminal must be named `R-filename` |

## Documentation

- Full guide: `DOCKER_USAGE.md`
- Test scenarios: `test_files/DOCKER_TEST_SCENARIOS.md`
- Implementation details: `DOCKER_IMPLEMENTATION_SUMMARY.md`
