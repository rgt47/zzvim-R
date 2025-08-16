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