# zzvim-R

R integration plugin for Vim and Neovim providing code execution, terminal management, and R Markdown support.

## Features

- **Code Execution**: Detects R functions, control structures, and pipe chains for automatic code block submission
- **Multi-Terminal Sessions**: Buffer-specific R terminals with isolated session management
- **Non-Interactive Submission**: Code execution without prompt dialogs
- **R Markdown Support**: Chunk navigation and execution with `<LocalLeader>j/k/l`
- **Object Inspection**: Functions for workspace examination with `<LocalLeader>h/s/d/p` shortcuts
- **Workspace Display**: Tabbed view of workspace information including memory usage, data frames, and packages
- **Data Frame Display**: Formatted display of data frame contents with `<LocalLeader>v`
- **Workspace Monitoring**: Display of object memory usage, loaded packages, and environment variables
- **Visual Selection**: Code submission from selected regions
- **Pattern Support**: Recognition of R constructs including nested delimiters and infix operators
- **LSP Integration**: Optional support for CoC or native LSP completion and diagnostics
- **Copilot Support**: Integration with GitHub Copilot for code suggestions
- **Configurable Behavior**: Customizable feature activation and key mappings

## Quick Start

1. Install the plugin (see installation options below)
2. Open an R file in Vim/Neovim
3. Press `<CR>` to send current line/function to R
4. Use `<LocalLeader>r` to open R terminal

## Key Mappings

| Key | Action |
|-----|--------|
| `<CR>` | Smart code submission (context-aware) |
| **R Terminal Launch** |
| `<LocalLeader>r` | Container R (via `make r`, with renv) |
| `<LocalLeader>rr` | Host R with renv (normal startup) |
| `<LocalLeader>rh` | Host R without renv (vanilla mode) |
| `<LocalLeader>w` | Open R terminal in vertical split |
| **HUD & Workspace** |
| `<LocalLeader>0` | HUD Dashboard - open all 5 workspace tabs |
| `<LocalLeader>m` | Memory Usage HUD |
| `<LocalLeader>e` | Data Frames HUD |  
| `<LocalLeader>z` | Package Status HUD |
| `<LocalLeader>v` | RStudio-style Data Viewer |
| **Object Inspection** |
| `<LocalLeader>h` | `head()` on word under cursor |
| `<LocalLeader>s` | `str()` on word under cursor |
| `<LocalLeader>d` | `dim()` on word under cursor |
| **R Markdown** |
| `<LocalLeader>j/k` | Navigate R Markdown chunks |
| `<LocalLeader>l` | Execute current chunk |

## Installation

### Vim (8.0+) and Neovim

#### Vim-Plug
```vim
" Add to your ~/.vimrc or ~/.config/nvim/init.vim
Plug 'rgt47/zzvim-R'

" Then run
:PlugInstall
```

#### Vundle
```vim
" Add to your ~/.vimrc
Plugin 'rgt47/zzvim-R'

" Then run
:PluginInstall
```

#### Pathogen
```bash
cd ~/.vim/bundle
git clone https://github.com/rgt47/zzvim-R.git
```

#### Manual Installation
```bash
# Vim
mkdir -p ~/.vim/pack/plugins/start/
git clone https://github.com/rgt47/zzvim-R.git ~/.vim/pack/plugins/start/zzvim-R

# Neovim
mkdir -p ~/.local/share/nvim/site/pack/plugins/start/
git clone https://github.com/rgt47/zzvim-R.git ~/.local/share/nvim/site/pack/plugins/start/zzvim-R

# Generate help tags
vim -c 'helptags ALL' -c 'quit'
```

## Requirements

- **Vim**: 8.0+ with `+terminal` feature
- **Neovim**: Any recent version
- **R**: Installed and available in PATH
- **OS**: Linux, macOS, Windows

Check compatibility:
```vim
:echo has('terminal')     " Should return 1
:echo executable('R')     " Should return 1
```

### R Language Server Setup (for LSP features)

If you plan to use any LSP-based completion option, install the R language server:

```r
# Run in R console
install.packages("languageserver")
```

This provides code completion, diagnostic messages, and definition navigation.

## Configuration

Basic configuration in your `~/.vimrc` or `~/.config/nvim/init.vim`:

```vim
" Optional: Customize R command
let g:zzvim_r_command = 'R --no-save --quiet'

" Optional: Set terminal size for splits  
let g:zzvim_r_terminal_width = 100   " Vertical split width
let g:zzvim_r_terminal_height = 15   " Horizontal split height

" Optional: Disable default mappings (define your own)
let g:zzvim_r_disable_mappings = 0
```

## Optional Enhancements

Choose your preferred completion framework - zzvim-R works with multiple options:

### Option 1: CoC Integration (Vim + Neovim)

For users who prefer CoC or need Vim compatibility:

```vim
" Add to your .vimrc or init.vim
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Install R language server
:CocInstall coc-r-lsp

" Optional: Additional useful extensions
:CocInstall coc-snippets coc-pairs
```

### Option 2: nvim-cmp (Neovim Only)

For Neovim users who prefer the native completion framework:

```lua
-- Add to your init.lua
{
  "hrsh7th/nvim-cmp",
  dependencies = {
    "neovim/nvim-lspconfig",
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer", 
    "hrsh7th/cmp-path",
    "L3MON4D3/LuaSnip",  -- Optional: snippet support
    "saadparwaiz1/cmp_luasnip",
  },
  config = function()
    local cmp = require('cmp')
    cmp.setup({
      snippet = {
        expand = function(args)
          require('luasnip').lsp_expand(args.body)
        end,
      },
      sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
        { name = 'buffer' },
        { name = 'path' },
      })
    })
    
    -- Setup R Language Server
    require('lspconfig').r_language_server.setup{
      capabilities = require('cmp_nvim_lsp').default_capabilities()
    }
  end,
}
```

### Option 3: Native LSP Only (Neovim Only)

For minimal setup with just LSP features:

```lua
-- Add to your init.lua
require('lspconfig').r_language_server.setup{}
```

### Completion Framework Comparison

| Framework | Editor Support | Setup | Memory | Features |
|-----------|---------------|-------|---------|----------|
| **CoC** | Vim + Neovim | Medium | ~15MB | Full LSP + extensions |
| **nvim-cmp** | Neovim only | Medium | ~10MB | Native LSP + advanced completion |
| **Native LSP** | Neovim only | Minimal | ~5MB | Basic LSP features |

**All options provide:**
- Real-time code completion for R objects and functions
- Function signatures and parameter hints
- Go-to-definition and find references
- Real-time error diagnostics and syntax checking

### AI-Assisted Development (Copilot Integration)

For AI-powered code suggestions and generation:

```vim
" Add to your .vimrc
Plug 'github/copilot.vim'

" After installation, authenticate
:Copilot setup

" Enable for R files (add to .vimrc)
let g:copilot_filetypes = {'r': v:true, 'rmd': v:true, 'qmd': v:true}
```

**AI capabilities:**
- Intelligent code completion and suggestions
- Statistical analysis pattern recognition
- Automatic documentation generation
- Data manipulation workflow assistance

### Performance Comparison

| Configuration | Memory Usage | Features | Characteristics |
|---------------|-------------|----------|----------|
| Base zzvim-R | ~2MB | Code execution, terminal integration | Minimal dependencies |
| + CoC | ~15MB | LSP services, completion, diagnostics | Vim and Neovim compatible |
| + nvim-cmp | ~10MB | Native LSP completion | Neovim-specific |
| + Native LSP | ~5MB | LSP services | Minimal Neovim setup |
| + Any option + Copilot | +5MB | AI-assisted completion | Optional enhancement |

Reference memory usage of comparable tools: RStudio (200-500MB), VS Code (100-300MB), R.nvim (50-100MB)

## Technical Characteristics

- **Architecture**: Single-file plugin (2,500 lines VimScript) with pattern-based code detection
- **Resource Usage**: Approximately 2-10 MB depending on optional components
- **Remote Access**: Compatible with SSH sessions and containerized environments
- **Editor Support**: Compatible with Vim 8.0+ and Neovim
- **Completion Options**: Optional integration with CoC, nvim-cmp, or native LSP
- **Code Detection**: Pattern recognition for R syntax including functions, control structures, and pipes
- **Documentation**: Inline comments (400+), help file, and usage guides
- **Dependencies**: Requires R, Vim terminal support; no external Python or Node.js dependencies

## Usage Examples

### Basic Usage
```r
# Position cursor on any line and press <CR>
library(tidyverse)
data <- read.csv("file.csv")

# Smart function detection - press <CR> anywhere in function
my_function <- function(x) {
    result <- x * 2
    return(result)
}

# Multi-line pipes work automatically
cleaned_data <- raw_data %>%
  filter(!is.na(value)) %>%
  mutate(new_col = value * 2) %>%
  arrange(desc(new_col))
```

### Object Inspection
```r
# Load data and inspect with shortcuts
data(mtcars)

# Position cursor on 'mtcars' and use:
# <LocalLeader>h for head(mtcars)
# <LocalLeader>s for str(mtcars)  
# <LocalLeader>d for dim(mtcars)
# <LocalLeader>p for print(mtcars)
mtcars
```

### Workspace Display Functions

Workspace information can be displayed in tabbed format:

```r
# Load sample data and packages
library(dplyr)
library(ggplot2)
data(iris)
data(mtcars)

# Press <LocalLeader>0 to open workspace tabs
# Displays 5 tabs with workspace state:
```

**Available Display Functions:**
- `<LocalLeader>0` - Open all workspace tabs
- `<LocalLeader>m` - Object memory usage
- `<LocalLeader>e` - Data frame listing with dimensions
- `<LocalLeader>z` - Loaded package information
- `<LocalLeader>x` - Environment variables
- `<LocalLeader>a` - R session options

**Tab Navigation:**
- `gt` / `gT` - Navigate between tabs
- `:q` - Close individual tabs
- `<LocalLeader>0` - Update all tabs with current workspace state

**Data Frame Display:**
```r
# Display data frame contents in formatted table
# <LocalLeader>v - Position cursor on data frame name, executes display
```

**Common Use Cases:**
- Display memory usage of workspace objects
- View dimensions of loaded data frames
- Verify loaded packages and versions
- Check system environment configuration
- Monitor R session options

### R Markdown
```markdown
```{r setup}
# Use <LocalLeader>l to execute this chunk
# Use <LocalLeader>j to jump to next chunk
library(ggplot2)
```

```{r analysis}  
# Use <LocalLeader>t to run all previous chunks first
plot <- ggplot(mtcars, aes(mpg, hp)) + geom_point()
print(plot)
```
```

## Documentation

For complete documentation with all commands, advanced workflows, and troubleshooting:

```vim
:help zzvim-r
```

## Support

- **Issues**: [GitHub Issues](https://github.com/rgt47/zzvim-R/issues)
- **Documentation**: `:help zzvim-r` (comprehensive help file)
- **Compatibility**: Works with R scripts (.R), R Markdown (.Rmd), and Quarto (.qmd)

## License

GPL-3.0 - See [LICENSE](LICENSE) file for details.