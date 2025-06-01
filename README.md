# zzvim-R - Enhanced R Development Plugin for Vim

A lightweight, powerful plugin for R development in Vim/Neovim with a clean, 
elegant architecture.

## Features

- **Terminal Integration**: Persistent R terminal session management per Vim tab
- **Code Execution**: Send lines, visual selections, and R Markdown chunks to R
- **Navigation**: Quick navigation between R Markdown code chunks
- **Enhanced Object Inspection**: Inspect objects, browse workspace, view structure
- **Package Management**: Install, load, and update R packages
- **Data Import/Export**: Quick CSV and RDS file operations
- **Directory Management**: Navigate and manage working directories
- **Enhanced Help System**: Access help with examples, search docs, find functions
- **Configurability**: Extensive customization options with sensible defaults
- **Support**: Works with R, R Markdown, Quarto, and Sweave files

## Requirements

- Vim 8.0+ with terminal support
- Neovim 0.5.0+ with terminal support
- R executable in PATH
- Optional: tidyverse packages for enhanced inspection functions

## Installation

### For Vim

Using vim-plug:
```vim
Plug 'rgt47/zzvim-r'
```

Using Vundle:
```vim
Plugin 'rgt47/zzvim-r'
```

Manual installation:
```bash
git clone https://github.com/rgt47/zzvim-r.git ~/.vim/pack/plugins/start/zzvim-r
```

### For Neovim

Using lazy.nvim (the most popular Neovim plugin manager):
```lua
{
  "rgt47/zzvim-r",
  ft = {"r", "rmd", "rnw", "qmd"},  -- Load only for R-related files
},
```

Using vim-plug in Neovim:
```vim
Plug 'rgt47/zzvim-r'
```

Manual installation for Neovim:
```bash
git clone https://github.com/rgt47/zzvim-r.git ~/.config/nvim/pack/plugins/start/zzvim-r
```

## Quick Start

1. Open an R file (`.r`, `.rmd`, `.qmd`)
2. Press `<LocalLeader>r` to open R terminal
3. Use `<CR>` to send current line or visual selection to R
4. Navigate chunks with `<LocalLeader>j/k`, execute with `<LocalLeader>l`
5. Use inspection shortcuts like `<LocalLeader>h` for head()

## Key Mappings

### Core Operations
- `<LocalLeader>r` - Open R terminal
- `<CR>` - Send line/selection to R

### Chunk Navigation (R Markdown)
- `<LocalLeader>j` - Next chunk
- `<LocalLeader>k` - Previous chunk
- `<LocalLeader>l` - Execute current chunk
- `<LocalLeader>t` - Execute all previous chunks

### Session Control
- `<LocalLeader>q` - Send Q (quit browser/debugger)
- `<LocalLeader>c` - Send Ctrl-C (interrupt)

### Object Inspection (Single-Letter)
- `<LocalLeader>h` - head()
- `<LocalLeader>s` - str()
- `<LocalLeader>d` - dim()
- `<LocalLeader>n` - names()
- `<LocalLeader>p` - print()
- `<LocalLeader>f` - length()
- `<LocalLeader>g` - glimpse()
- `<LocalLeader>b` - summary()
- `<LocalLeader>y` - help()

### Object Browser & Workspace
- `<LocalLeader>wb` - Object browser (ls.str())
- `<LocalLeader>wl` - Workspace listing (ls())
- `<LocalLeader>wc` - Class & type info of object
- `<LocalLeader>wd` - Detailed object structure

### Package Management
- `<LocalLeader>xi` - Install package
- `<LocalLeader>xl` - Load package
- `<LocalLeader>xu` - Update package

### Data Import/Export
- `<LocalLeader>zr` - Read CSV file
- `<LocalLeader>zw` - Write CSV file
- `<LocalLeader>zl` - Load RDS file
- `<LocalLeader>zs` - Save RDS file

### Directory Management
- `<LocalLeader>vd` - Print working directory
- `<LocalLeader>vc` - Change directory
- `<LocalLeader>vl` - List directory contents
- `<LocalLeader>vh` - Change to home directory

### Enhanced Help
- `<LocalLeader>ue` - Help with examples
- `<LocalLeader>ua` - Search help (apropos)
- `<LocalLeader>uf` - Find function definition

### Utilities
- `<LocalLeader>o` - Add pipe operator (%>%)

## Commands

- `:ROpenTerminal` - Open R terminal
- `:RSubmitLine` - Send current line to R
- `:RSubmitSelection` - Send visual selection to R
- `:RPackage [action] [name]` - Manage R packages
- `:RData [action] [file]` - Import/export data files
- `:RDirectory [action] [path]` - Manage working directory
- `:RTerminalStatus` - Display terminal status
- `:RToggleDebug` - Toggle debug level

## Configuration

```vim
" R command for terminal sessions
let g:zzvim_r_command = 'R --no-save --quiet'

" Width of R terminal in vertical split
let g:zzvim_r_terminal_width = 100

" Disable default mappings (set to 1 to disable)
let g:zzvim_r_disable_mappings = 0

" Debug logging level (0-4)
let g:zzvim_r_debug = 0

" Path for debug log file
let g:zzvim_r_log_file = '~/zzvim_r.log'

" R Markdown chunk patterns
let g:zzvim_r_chunk_start = '^```{[rR]'
let g:zzvim_r_chunk_end = '^```\s*$'
```


## Technical Details

### Architecture

The plugin uses a layered architecture with clear separation of concerns:

1. **Core Engine Layer** (`plugin/zzvim_r.vim`):
   - Configuration management
   - Core engine functions (terminal, text, execute, package, data, directory)
   - Command and mapping registration

2. **Public API Layer** (`autoload/zzvim_r.vim`):
   - User-facing functions with comprehensive documentation
   - Lazy-loaded through Vim's autoload mechanism 
   - Delegates to core engines for implementation

3. **Communication Layer**:
   - Plugin functions are imported by autoload as needed
   - Autoload functions validate context before execution
   - Robust error handling throughout

### Key Design Patterns

- **Command Dispatch**: Central `s:engine()` routes operations to handlers
- **Action-based API**: String actions determine behavior in engine functions
- **Lazy Loading**: Autoload mechanism improves startup time
- **Clean Delegation**: Public functions delegate to specialized engines
- **Configuration-driven**: Behavior controlled by settings, not hardcoded values

## Comparison with Other R Plugins

zzvim-R provides **~95% of daily-use functionality** with a clean, modular 
architecture:

- **Modular design**: Organized into logical components
- **No dependencies**: Works out of the box
- **Fast loading**: Autoload pattern for on-demand loading
- **Clean architecture**: Well-documented, easy to extend and customize
- **Focused design**: All essential features, no bloat

## Version History

- **3.0.0**: Major code cleanup and API streamlining with breaking changes
- **2.3.2**: Fixed code style issues, improved error handling, added helper functions
- **2.3.1**: Optimized code structure and architecture, improved documentation
- **2.3.0**: Fixed chunk navigation, eliminated key mapping conflicts
- **2.2.0**: Added enhanced object inspection, package and data management
- **2.1.0**: Initial release with core features

## License

GPL-3.0