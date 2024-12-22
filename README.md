# zzvim-R.vim

A Vim plugin for seamless R development within Vim, providing integration between Vim and R terminal sessions. Work efficiently with R scripts, R Markdown, and Quarto documents.

## Features

- Send commands directly from Vim to an R terminal
- Navigate and execute R Markdown chunks
- Quick access to common R functions
- Support for multiple R terminal sessions
- Pipe operator (`|>`) integration
- Visual selection support
- Comprehensive chunk management

## Requirements

- Vim 8.1 or newer with `+terminal` feature
- R installed and available in your PATH

## Installation

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'your-username/zzvim-r.vim'
```

Using Vundle:
```vim
Plugin 'your-username/zzvim-r.vim'
```

Manual installation:
```bash
git clone https://github.com/your-username/zzvim-r.vim.git ~/.vim/pack/plugins/start/zzvim-r.vim
```

## Configuration

Add any of these settings to your `vimrc` to customize the plugin:

```vim
" Default terminal name for R sessions
let g:zzvim_r_default_terminal = 'R'

" Disable default mappings if you prefer to define your own
let g:zzvim_r_disable_mappings = 0

" Customize the submit line mapping
let g:zzvim_r_map_submit = '<CR>'
```

## Default Mappings

### Normal Mode

| Mapping           | Description                    |
|------------------|--------------------------------|
| `<CR>`           | Submit current line to R       |
| `<localleader>o` | Add pipe operator and new line |
| `<localleader>j` | Move to next chunk             |
| `<localleader>k` | Move to previous chunk         |
| `<localleader>l` | Select and submit chunk        |
| `<localleader>'` | Submit all previous chunks     |
| `<localleader>q` | Send 'Q' to R terminal         |
| `<localleader>c` | Send Ctrl-C to R terminal      |

### R Function Shortcuts

| Mapping           | Function                       |
|------------------|--------------------------------|
| `<localleader>d` | Run `dim()` on word           |
| `<localleader>h` | Run `head()` on word          |
| `<localleader>s` | Run `str()` on word           |
| `<localleader>p` | Run `print()` on word         |
| `<localleader>n` | Run `names()` on word         |
| `<localleader>f` | Run `length()` on word        |
| `<localleader>g` | Run `glimpse()` on word       |
| `<localleader>b` | Run `dt()` on word            |

### Visual Mode

| Mapping           | Description                    |
|------------------|--------------------------------|
| `<localleader>z` | Submit visual selection        |

## Commands

The plugin provides the following commands:

- `:RSubmitLine` - Submit current line to R
- `:RNextChunk` - Move to next chunk
- `:RPrevChunk` - Move to previous chunk
- `:RSelectChunk` - Select current chunk
- `:RSubmitChunks` - Submit all previous chunks

## Usage Examples

### Basic R Script Usage

```r
# Write your R code
x <- c(1, 2, 3, 4, 5)
mean(x)

# Press Enter to send each line to R
# Use <localleader>h with cursor on 'x' to run head(x)
```

### R Markdown Chunk Navigation

````markdown
```{r}
# Use <localleader>j and <localleader>k to navigate between chunks
data <- read.csv("data.csv")
```

```{r}
# Use <localleader>l to select and execute the current chunk
summary(data)
```
````

### Using Pipe Operator

```r
data %>%
  filter(year > 2000) %>%
  group_by(category) %>%
  summarize(mean_value = mean(value))

# Use <localleader>o to add a pipe operator and create a new line
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Vim License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by various R development tools and Vim plugins
- Thanks to the Vim and R communities for their valuable feedback

## Troubleshooting

### Common Issues

1. **No R terminal available**
   - Make sure you have started an R terminal session before trying to send commands

2. **Commands not being sent to R**
   - Verify that Vim was compiled with terminal support
   - Check that R is properly installed and in your PATH
   - Ensure there is an active R terminal session

3. **Multiple terminals**
   - If multiple terminal sessions are open, the plugin will prompt you to choose which terminal to send commands to

For more detailed help, use `:help zzvim-r` within Vim.
