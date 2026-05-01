# zzvim-R

[![CI](https://github.com/rgt47/zzvim-R/actions/workflows/test.yml/badge.svg)](https://github.com/rgt47/zzvim-R/actions/workflows/test.yml)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)

R integration plugin for Vim and Neovim. Send code to an R
terminal, navigate R Markdown chunks, inspect workspace objects,
and display plots -- all without leaving the editor.

## Quick start

1. Install the plugin (see below)
2. Open an `.R` file
3. `<LocalLeader>r` to open an R terminal
4. Press `<CR>` on any line -- the plugin detects the full
   expression (function body, pipe chain, control block) and
   sends it to R

## Features

- **Smart code submission**: `<CR>` detects functions, pipe chains,
  control structures, and multi-line expressions automatically
- **Multi-terminal sessions**: each buffer gets its own R process
- **R Markdown / Quarto**: chunk navigation (`j`/`k`), execution
  (`l`), render, and chunk insertion
- **Object inspection**: `head`, `str`, `dim`, `print`, `names`,
  `glimpse` on the word under the cursor
- **Workspace HUD**: memory usage, data frames, packages, and
  environment in a tabbed dashboard (`<LocalLeader>0`)
- **Inline plots**: PDF master + PNG preview displayed in Kitty,
  Ghostty, WezTerm, or iTerm2 terminal panes
- **Docker integration**: auto-detects zzcollab workspaces and
  launches R inside the container via `make r`

## Key mappings

| Key | Action |
|-----|--------|
| `<CR>` | Smart code submission (context-aware) |
| **Terminal** | |
| `<LocalLeader>r` | Container R (Docker, with renv) |
| `<LocalLeader>rr` | Host R with renv |
| `<LocalLeader>rh` | Host R without renv (vanilla) |
| `<LocalLeader>w` | R terminal in vertical split |
| **HUD & workspace** | |
| `<LocalLeader>0` | Dashboard (all 6 workspace tabs) |
| `<LocalLeader>m/e/z` | Memory / Data frames / Packages |
| `<LocalLeader>v` | Data viewer |
| **Inspection** | |
| `<LocalLeader>h/s/d` | `head` / `str` / `dim` |
| `<LocalLeader>p/n/g` | `print` / `names` / `glimpse` |
| **R Markdown** | |
| `<LocalLeader>j/k` | Next / previous chunk |
| `<LocalLeader>l` | Execute current chunk |

Full mapping reference: `:help zzvim-R-mappings`

## Installation

### lazy.nvim (Neovim)

```lua
{ 'rgt47/zzvim-R', ft = { 'r', 'rmd', 'quarto' } }
```

### vim-plug

```vim
Plug 'rgt47/zzvim-R'
```

### mini.deps (Neovim)

```lua
MiniDeps.add({ source = 'rgt47/zzvim-R' })
```

### Native packages (Vim 8+ / Neovim)

```bash
# Vim
git clone https://github.com/rgt47/zzvim-R.git \
  ~/.vim/pack/plugins/start/zzvim-R

# Neovim
git clone https://github.com/rgt47/zzvim-R.git \
  ~/.local/share/nvim/site/pack/plugins/start/zzvim-R

vim -c 'helptags ALL' -c 'quit'
```

<details>
<summary>Other package managers</summary>

**Vundle**
```vim
Plugin 'rgt47/zzvim-R'
```

**Pathogen**
```bash
git clone https://github.com/rgt47/zzvim-R.git ~/.vim/bundle/zzvim-R
```

**dein.vim**
```vim
call dein#add('rgt47/zzvim-R')
```
</details>

## Requirements

- **Vim** 8.0+ with `+terminal`, or any recent **Neovim**
- **R** installed and on `$PATH`
- Linux, macOS, or Windows

## Configuration

```vim
let g:zzvim_r_command = 'R --no-save --quiet'
let g:zzvim_r_terminal_width = 100
let g:zzvim_r_terminal_height = 15
let g:zzvim_r_disable_mappings = 0
```

All configuration variables are documented in `:help zzvim-R-configuration`.

## Optional: LSP completion

Install the R language server for code completion and diagnostics:

```r
install.packages('languageserver')
```

Then configure your preferred LSP client (CoC, nvim-cmp, or native
`lspconfig`). See `:help zzvim-R-lsp` for setup snippets.

## Similar projects

- [R.nvim](https://github.com/R-nvim/R.nvim) -- Neovim-only, Lua,
  successor to Nvim-R (archived 2023). Feature-rich; heavier.
- [vim-slime](https://github.com/jpalardy/vim-slime) -- generic
  REPL bridge. Language-agnostic; no R-aware pattern detection.
- [ESS](https://ess.r-project.org/) -- Emacs Speaks Statistics.
  Different ecosystem.

zzvim-R targets Vim *and* Neovim with a lightweight VimScript
implementation and R-specific intelligence (pattern detection,
chunk navigation, plot display).

## Documentation

The canonical reference is the Vim help file:

```vim
:help zzvim-R
```

Supplementary guides under `docs/`:

| Guide                                       | Purpose                                          |
| ------------------------------------------- | ------------------------------------------------ |
| [`quickstart.md`](docs/quickstart.md)       | 10-step tour for first-time users                |
| [`hud-guide.md`](docs/hud-guide.md)         | The seven HUD panels and the dashboard           |
| [`plot-guide.md`](docs/plot-guide.md)       | PDF + PNG plot pipeline, history, and zoom       |
| [`terminal-graphics.md`](docs/terminal-graphics.md) | Terminal detection and `.Rprofile.local` setup |
| [`ai-tooling.md`](docs/ai-tooling.md)       | Optional integration with AI coding assistants   |
| [`comparison.md`](docs/comparison.md)       | Honest comparison vs R.nvim, ESS, RStudio, VS Code, vim-slime |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Bug reports and feature
requests use [GitHub Issues](https://github.com/rgt47/zzvim-R/issues)
(structured YAML forms).

## License

GPL-3.0. See [LICENSE](LICENSE).
