# Docker Quick Reference for zzvim-R

## Key Mappings

| Mapping | Action |
|---------|--------|
| `ZR` | Launch R in Docker via 'make r' (new) |
| `<LocalLeader>dr` | Force-associate with existing Docker terminal |
| `<LocalLeader>r` | Launch regular (non-Docker) R terminal |

## Ex Commands

| Command | Action |
|---------|--------|
| `:RDockerTerminal` | Launch R in Docker via 'make r' |
| `:RDockerTerminalForce` | Force-associate with existing Docker terminal |

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

## Common Workflows

### New Docker Terminal
```vim
vim analysis.R
ZR                  " Launch Docker R via 'make r'
<CR>                " Execute code
```

### Reuse Existing Terminal
```vim
" Terminal already running:
vim analysis.R
<LocalLeader>dr     " Force-associate
<CR>                " Execute in existing terminal
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
