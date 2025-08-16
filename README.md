# zzvim-R

Advanced R integration for Vim and Neovim with smart code execution and multi-terminal support.

## Features

- **Smart Code Execution**: Automatically detects R functions, control structures, and pipe chains
- **Multi-Terminal Sessions**: Buffer-specific R terminals - each R file gets its own R session  
- **Silent Execution**: No "Press ENTER" prompts for streamlined workflows
- **R Markdown Support**: Navigate and execute chunks with `<LocalLeader>j/k/l`
- **Object Inspection**: Quick data analysis with `<LocalLeader>h/s/d/p` shortcuts
- **Visual Selection**: Send any selected code block to R
- **Pattern Recognition**: Handles complex R constructs including nested braces and pipes
- **Optional Modern IDE Features**: CoC integration for LSP completion and diagnostics
- **AI-Assisted Development**: GitHub Copilot support for intelligent code suggestions
- **Progressive Enhancement**: Start simple, add advanced features as needed

## Quick Start

1. Install the plugin (see installation options below)
2. Open an R file in Vim/Neovim
3. Press `<CR>` to send current line/function to R
4. Use `<LocalLeader>r` to open R terminal

## Key Mappings

| Key | Action |
|-----|--------|
| `<CR>` | Smart code submission (context-aware) |
| `<LocalLeader>r` | Open buffer-specific R terminal |
| `<LocalLeader>w` | Open R terminal in vertical split |
| `<LocalLeader>h` | `head()` on word under cursor |
| `<LocalLeader>s` | `str()` on word under cursor |
| `<LocalLeader>d` | `dim()` on word under cursor |
| `<LocalLeader>j/k` | Navigate R Markdown chunks |
| `<LocalLeader>l` | Execute current chunk |

## Installation

### Vim (8.0+) and Neovim

#### Vim-Plug
```vim
" Add to your ~/.vimrc or ~/.config/nvim/init.vim
Plug 'your-username/zzvim-r.vim'

" Then run
:PlugInstall
```

#### Vundle
```vim
" Add to your ~/.vimrc
Plugin 'your-username/zzvim-r.vim'

" Then run
:PluginInstall
```

#### Pathogen
```bash
cd ~/.vim/bundle
git clone https://github.com/your-username/zzvim-r.vim.git
```

#### Manual Installation
```bash
# Vim
mkdir -p ~/.vim/pack/plugins/start/
git clone https://github.com/your-username/zzvim-r.vim.git ~/.vim/pack/plugins/start/zzvim-r.vim

# Neovim
mkdir -p ~/.local/share/nvim/site/pack/plugins/start/
git clone https://github.com/your-username/zzvim-r.vim.git ~/.local/share/nvim/site/pack/plugins/start/zzvim-r.vim

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

This enables advanced features like completion, diagnostics, and go-to-definition.

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

| Configuration | Memory Usage | Features | Best For |
|---------------|-------------|----------|----------|
| Base zzvim-R | ~2MB | Smart patterns, terminal integration | Performance-critical, simple setups |
| + CoC | ~15MB | LSP features, completion, diagnostics | Cross-editor compatibility |
| + nvim-cmp | ~10MB | Native LSP + advanced completion | Modern Neovim users |
| + Native LSP | ~5MB | Basic LSP features | Minimal Neovim setup |
| + Any option + Copilot | +5MB | Full IDE + AI assistance | Maximum productivity |

*Compare to: RStudio (200-500MB), VS Code (100-300MB), R.nvim (50-100MB)*

## Why zzvim-R?

- **Smart & Fast**: Intelligent R code detection with instant execution
- **Lightweight**: Minimal memory footprint compared to heavy IDEs
- **Terminal-Native**: Works seamlessly in SSH environments and containers
- **Framework Flexibility**: Choose from CoC, nvim-cmp, or native LSP
- **Editor Agnostic**: Works with both Vim and Neovim (unlike R.nvim)
- **Standard Protocols**: LSP-based completion (vs. R.nvim's custom TCP)
- **Progressive Enhancement**: Start simple, add features as needed
- **Educational**: Learn VimScript while using a practical tool
- **Modern R**: Optimized for tidyverse, pipes, and contemporary workflows
- **Best of Both Worlds**: Vim efficiency with optional modern IDE capabilities

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

- **Issues**: [GitHub Issues](https://github.com/your-username/zzvim-r.vim/issues)
- **Documentation**: `:help zzvim-r` (comprehensive help file)
- **Compatibility**: Works with R scripts (.R), R Markdown (.Rmd), and Quarto (.qmd)

## License

GPL-3.0 - See [LICENSE](LICENSE) file for details.