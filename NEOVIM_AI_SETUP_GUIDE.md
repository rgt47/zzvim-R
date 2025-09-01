# Complete AI-Powered Neovim R Development Environment Setup Guide

This guide provides step-by-step instructions to recreate a professional R development environment in Neovim with multiple AI assistants and modern development tools.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Core Installation](#core-installation)
3. [Neovim Configuration Structure](#neovim-configuration-structure)
4. [Plugin Configuration Files](#plugin-configuration-files)
5. [AI Services Setup](#ai-services-setup)
6. [R Development Tools](#r-development-tools)
7. [Testing and Verification](#testing-and-verification)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements
- **macOS/Linux/Windows** with terminal access
- **Git** installed and configured
- **Node.js** (v16+) and **npm** for various plugins
- **Python 3** with pip for language servers
- **R** (v4.0+) installed and in PATH

### Package Managers
- **macOS**: Homebrew (`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`)
- **Linux**: Your distribution's package manager
- **Windows**: Chocolatey or Scoop

## Core Installation

### 1. Install Neovim
```bash
# macOS
brew install neovim

# Linux (Ubuntu/Debian)
sudo apt install neovim

# Linux (Arch)
sudo pacman -S neovim

# Windows
choco install neovim
```

### 2. Install Dependencies
```bash
# Essential tools
brew install git ripgrep fd tree-sitter

# Node.js packages
npm install -g neovim tree-sitter-cli

# Python packages
pip3 install pynvim

# R packages (in R console)
R -e "install.packages(c('languageserver', 'styler'))"
```

## Neovim Configuration Structure

Create the modular configuration directory structure:

```bash
mkdir -p ~/.config/nvim/lua/{config,plugins}
mkdir -p ~/.config/nvim/luasnippets
```

### Main Configuration File: `~/.config/nvim/init.lua`

```lua
-- ============================================================================
-- Neovim Configuration - Modular Setup
-- ============================================================================
-- 
-- This configuration is organized into modules for better maintainability:
--
-- lua/config/
--   ├── options.lua     - Core vim settings and options
--   ├── keymaps.lua     - Key mappings and shortcuts  
--   ├── autocmds.lua    - Auto commands and events
--   └── lazy.lua        - Plugin manager setup
--
-- lua/plugins/
--   ├── completion.lua  - LSP, completion, and snippets
--   ├── ui.lua          - Themes, status line, visual enhancements
--   ├── navigation.lua  - Telescope, flash, movement plugins
--   ├── treesitter.lua  - Syntax highlighting and parsing
--   ├── r-dev.lua       - R development tools
--   ├── editor.lua      - Text manipulation and formatting
--   └── ai.lua          - Copilot and AI assistants
--
-- luasnippets/         - LuaSnip snippet files
--   ├── all.lua         - Global snippets
--   ├── r.lua           - R-specific snippets  
--   ├── rmd.lua         - R Markdown snippets
--   ├── tex.lua         - LaTeX snippets
--   └── text.lua        - Plain text snippets
-- ============================================================================

-- Load core configuration
require("config.options")
require("config.lazy")     -- This loads all plugins from lua/plugins/
require("config.keymaps")
require("config.autocmds")

-- Test function to debug R completion setup
vim.keymap.set('n', '<leader>tc', function()
  print("=== R Completion Test ===")
  
  -- Check if R LSP is attached
  local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
  if #clients > 0 then
    for _, client in ipairs(clients) do
      print("✅ LSP client active: " .. client.name)
      if client.server_capabilities.completionProvider then
        print("  ✅ Completion supported")
      else
        print("  ❌ Completion NOT supported")
      end
    end
  else
    print("❌ No LSP clients attached to current buffer")
    print("Current filetype: " .. vim.bo.filetype)
    if vim.bo.filetype == "r" or vim.bo.filetype == "rmd" then
      print("  This should have R LSP attached")
    else
      print("  ❌ Completion NOT supported")
    end
  end
  
  -- Test if nvim-cmp is working
  local cmp = require('cmp')
  if cmp then
    print("✅ nvim-cmp is loaded")
    local sources = cmp.get_config().sources
    for i, source in ipairs(sources) do
      print("  Source " .. i .. ": " .. source.name .. " (priority: " .. (source.priority or "default") .. ")")
    end
  else
    print("❌ nvim-cmp is not loaded")
  end
end, { desc = 'Test R completion setup' })
```

## Plugin Configuration Files

### 1. Core Options: `~/.config/nvim/lua/config/options.lua`

```lua
-- ============================================================================
-- Core Vim Settings and Options
-- ============================================================================

-- === Leader Key Configuration ===
vim.g.mapleader = ","
vim.g.maplocalleader = " "

-- === Core Settings ===
vim.cmd('syntax enable')
vim.cmd('filetype plugin indent on')
vim.opt.encoding = 'utf-8'
vim.opt.background = 'dark'
vim.opt.shortmess:append('c')

-- === UI Configuration ===
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = true
vim.opt.colorcolumn = '80'
vim.opt.textwidth = 80
vim.opt.scrolloff = 3
vim.opt.splitright = true
vim.opt.wildmenu = true
vim.opt.wildmode = 'list:full'
vim.opt.updatetime = 1000
vim.opt.ttyfast = true
vim.opt.lazyredraw = true
vim.opt.timeout = true
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 50

-- === Terminal Settings ===
if vim.fn.has('termguicolors') == 1 then
  vim.opt.termguicolors = true
end

-- === File Management ===
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.writebackup = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand('~/.vim/undodir')
vim.opt.autoread = true
vim.opt.hidden = true

-- === Search and Replace ===
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.gdefault = true

-- === Indentation and Tabs ===
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2

-- === Clipboard Configuration ===
vim.opt.clipboard:prepend({'unnamed', 'unnamedplus'})

-- === Python Configuration ===
vim.g.python3_host_prog = '/opt/homebrew/bin/python3'

-- === Tree-sitter CLI Configuration ===
-- Ensure Neovim can find tree-sitter CLI
vim.env.PATH = vim.env.PATH .. ':/opt/homebrew/bin'

-- === Spell Check Configuration ===
vim.opt.spelllang = 'en_us'
```

### 2. Plugin Manager: `~/.config/nvim/lua/config/lazy.lua`

```lua
-- ============================================================================
-- Lazy.nvim Plugin Manager Setup
-- ============================================================================

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy with plugin specs from lua/plugins/
require("lazy").setup("plugins", {
  defaults = {
    lazy = false, -- should plugins be lazy-loaded?
    version = false, -- always use the latest git commit
  },
  install = {
    colorscheme = { "gruvbox-material" },
  },
  checker = {
    enabled = true, -- check for plugin updates
    notify = false, -- don't notify about updates
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
```

### 3. AI Assistants: `~/.config/nvim/lua/plugins/ai.lua`

```lua
-- ============================================================================
-- AI and Coding Assistant Plugins
-- ============================================================================

return {
  -- GitHub Copilot
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      vim.g.copilot_enabled = 1
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_idle_delay = 2000
      vim.g.copilot_filetypes = { r = true, rmd = true }
      -- Copilot key mappings
      vim.keymap.set('i', '<C-l>', 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false
      })
    end,
  },

  -- CodeCompanion (Gemini AI)
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "hrsh7th/nvim-cmp", -- For slash commands
      "nvim-telescope/telescope.nvim", -- For actions
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("codecompanion").setup({
        strategies = {
          chat = {
            adapter = "gemini",
          },
          inline = {
            adapter = "gemini",
          },
          agent = {
            adapter = "gemini",
          },
        },
        adapters = {
          http = {
            gemini = function()
              return require("codecompanion.adapters").extend("gemini", {
                env = {
                  api_key = "GEMINI_API_KEY",
                },
                schema = {
                  model = {
                    default = "gemini-1.5-flash-latest", -- Higher rate limits than Pro
                  },
                  max_tokens = {
                    default = 4096,
                  },
                  temperature = {
                    default = 0.1,
                  },
                },
                handlers = {
                  on_error = function(err)
                    vim.notify("CodeCompanion Gemini Error: " .. tostring(err), vim.log.levels.ERROR)
                  end,
                },
              })
            end,
          },
        },
        display = {
          action_palette = {
            width = 95,
            height = 10,
          },
          chat = {
            window = {
              layout = "vertical", -- float|vertical|horizontal|buffer
            },
            show_settings = true,
          },
        },
      })
    end,
  },
}
```

### 4. R Development: `~/.config/nvim/lua/plugins/r-dev.lua`

```lua
-- ============================================================================
-- R Development and Analysis Plugins
-- ============================================================================

return {
  -- R development
  {
    "rgt47/zzvim-R",
    ft = {"r", "rmd", "qmd"},
  },
  
  -- LaTeX/VimTeX for R Markdown and academic writing
  {
    "lervag/vimtex",
    ft = { "tex", "rmd", "qmd" },
    config = function()
      vim.g.vimtex_view_method = "skim"
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_quickfix_mode = 0
      
      -- Configure for R Markdown
      vim.g.vimtex_syntax_conceal = {
        accents = 1,
        ligatures = 1,
        cites = 1,
        fancy = 1,
        spacing = 1,
        greek = 1,
        math_bounds = 1,
        math_delimiters = 1,
        math_fracs = 1,
        math_super_sub = 1,
        math_symbols = 1,
        sections = 0,
        styles = 1,
      }
    end,
  },
}
```

### 5. LSP and Completion: `~/.config/nvim/lua/plugins/completion.lua`

```lua
-- ============================================================================
-- LSP, Completion, and Language Support
-- ============================================================================

return {
  -- LSP and completion
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      -- Setup completion with enhanced configuration
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local cmp_lsp = require("cmp_nvim_lsp")
      
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = {
          completeopt = "menu,menuone,noinsert"
        },
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip", priority = 750 },
          { name = "buffer", priority = 500 },
          { name = "path", priority = 250 },
        }),
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.abort(),
          ['<CR>'] = cmp.mapping.confirm({ 
            behavior = cmp.ConfirmBehavior.Replace,
            select = true 
          }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.locally_jumpable(1) then
              luasnip.jump(1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })

      -- Setup cmdline completion
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })

      -- Setup R LSP with enhanced capabilities
      local capabilities = cmp_lsp.default_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      
      require("lspconfig").r_language_server.setup({
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          -- Enable completion triggered by <c-x><c-o>
          vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
          
          -- Print confirmation that LSP is attached
          print("R LSP attached to buffer " .. bufnr)
        end,
        settings = {
          r = {
            lsp = {
              diagnostics = true,
              rich_documentation = false,
              debug = false
            }
          }
        },
        filetypes = { "r", "rmd", "qmd" },
        root_dir = function(fname)
          return require("lspconfig.util").find_git_ancestor(fname) or vim.fn.getcwd()
        end,
      })
    end,
  },

  -- Formatting and linting
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          r = { "styler" },
          rmd = { "styler" },
          qmd = { "styler" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
      })
    end,
  },

  -- Enhanced diagnostics display
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("trouble").setup({
        -- Configuration for diagnostics panel
      })
    end,
  },

  -- Snippet engine
  {
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
```

### 6. UI and Themes: `~/.config/nvim/lua/plugins/ui.lua`

```lua
-- ============================================================================
-- UI Enhancement and Theme Plugins
-- ============================================================================

return {
  -- Modern Gruvbox theme
  {
    "sainnhe/gruvbox-material",
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = 'hard'
      vim.g.gruvbox_material_better_performance = 1
      vim.g.gruvbox_material_enable_italic = 1
      vim.cmd('colorscheme gruvbox-material')
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'gruvbox-material',
          section_separators = { left = '', right = '' },
          component_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = {'filename'},
          lualine_x = {'encoding', 'fileformat', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
        extensions = {'trouble', 'lazy'}
      })
    end,
  },

  -- File icons
  {
    "nvim-tree/nvim-web-devicons",
    config = function()
      require("nvim-web-devicons").setup()
    end,
  },
}
```

### 7. Navigation and Search: `~/.config/nvim/lua/plugins/navigation.lua`

```lua
-- ============================================================================
-- Navigation, Search, and Movement Plugins
-- ============================================================================

return {
  -- Telescope (fuzzy finder)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { 
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      local builtin = require('telescope.builtin')
      -- FZF-style mappings
      vim.keymap.set('n', '<leader>z', builtin.find_files, { desc = 'Find files' })
      vim.keymap.set('n', '<leader>b', builtin.buffers, { desc = 'Find buffers' })
      vim.keymap.set('n', '<leader>/', builtin.current_buffer_fuzzy_find, { desc = 'Buffer lines' })
      vim.keymap.set('n', '<leader>r', builtin.live_grep, { desc = 'Live grep' })
      vim.keymap.set('n', "<leader>'", builtin.marks, { desc = 'Marks' })
    end,
  },

  -- Modern vim-sneak replacement
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {
      label = true,
      search = { multi_window = false },
      jump = { autojump = true },
    },
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
    },
  },
}
```

### 8. Treesitter: `~/.config/nvim/lua/plugins/treesitter.lua`

```lua
-- ============================================================================
-- Treesitter for Advanced Syntax Highlighting
-- ============================================================================

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        -- Install parsers for R ecosystem
        ensure_installed = { 
          "r", 
          "markdown", 
          "markdown_inline",
          "latex",
          "bibtex",
          "yaml",
          "toml",
          "json",
          "csv",
          "lua", 
          "vim", 
          "vimdoc",
          "bash",
          "python",
          "sql"
        },
        
        -- Enable syntax highlighting
        highlight = { 
          enable = true,
          additional_vim_regex_highlighting = { "r", "markdown" },
        },
        
        -- Enable better indentation (especially for R)
        indent = { 
          enable = true,
          disable = { "yaml" }, -- YAML indentation can be problematic
        },
        
        -- Auto-install missing parsers when entering buffer
        auto_install = true,
      })
    end,
  },
}
```

### 9. Key Mappings: `~/.config/nvim/lua/config/keymaps.lua`

```lua
-- ============================================================================
-- Key Mappings (Converted from .vimrc)
-- ============================================================================

-- === Core Editor Mappings ===
-- Movement optimizations (swap ; and :)
vim.keymap.set({'n', 'v'}, ':', ';', { desc = 'Repeat f/F/t/T motion' })
vim.keymap.set({'n', 'v'}, ';', ':', { desc = 'Command mode' })

-- === Enhanced Movement ===
vim.keymap.set({'n', 'x'}, 'zh', '14H', { desc = 'Jump to 14 lines from top' })
vim.keymap.set({'n', 'x'}, 'zl', '14L', { desc = 'Jump to 14 lines from bottom' })
vim.keymap.set({'n', 'x'}, 'zj', '5j', { desc = 'Jump 5 lines down' })
vim.keymap.set({'n', 'x'}, 'zk', '5k', { desc = 'Jump 5 lines up' })

-- === CodeCompanion (Gemini AI) Mappings ===
vim.keymap.set("n", "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Toggle Gemini chat" })
vim.keymap.set("v", "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Chat about selection" })
vim.keymap.set("n", "<leader>ca", "<cmd>CodeCompanionActions<cr>", { desc = "Gemini actions" })
vim.keymap.set("v", "<leader>ca", "<cmd>CodeCompanionActions<cr>", { desc = "Gemini actions for selection" })

-- === LSP and Formatting Mappings ===
vim.keymap.set("n", "<leader>f", function()
  require("conform").format({ lsp_fallback = true })
end, { desc = "Format file" })

vim.keymap.set("n", "<leader>d", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Toggle diagnostics panel" })

-- LSP key mappings
vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover documentation" })
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code actions (auto-fix)" })
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

-- Terminal mode mappings
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
```

### 10. Auto Commands: `~/.config/nvim/lua/config/autocmds.lua`

```lua
-- ============================================================================
-- Auto Commands and Events
-- ============================================================================

-- Auto save on cursor hold and focus gained
local autosave_group = vim.api.nvim_create_augroup("AutoSave", { clear = true })
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = autosave_group,
  callback = function()
    if vim.bo.modified and vim.bo.buftype == "" then
      vim.cmd("silent! update")
    end
  end,
})

-- File type specific settings
local filetype_group = vim.api.nvim_create_augroup("FileTypeSpecific", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = filetype_group,
  pattern = { "quarto", "rmd" },
  callback = function()
    vim.opt_local.commentstring = "# %s"
  end,
})

-- Configure diagnostic display
vim.diagnostic.config({
  virtual_text = true,
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
```

## AI Services Setup

### 1. Google Gemini API Setup

1. **Get API Key**:
   - Go to: https://aistudio.google.com/app/apikey
   - Sign in with Google account
   - Click "Create API Key"
   - Copy the key (starts with `AIza...`)

2. **Set Environment Variable**:
   ```bash
   # Add to ~/.zshrc or ~/.bashrc
   echo 'export GEMINI_API_KEY="your-gemini-api-key-here"' >> ~/.zshrc
   source ~/.zshrc
   ```

3. **Verify**:
   ```bash
   echo $GEMINI_API_KEY
   ```

### 2. GitHub Copilot Setup

1. **Install Copilot** (if you have access):
   ```bash
   gh extension install github/gh-copilot
   ```

2. **Authenticate in Neovim**:
   ```vim
   :Copilot auth
   ```

3. **Check Status**:
   ```vim
   :Copilot status
   ```

## R Development Tools

### 1. R Packages Installation

```r
# Essential R packages for development
install.packages(c(
  "languageserver",    # R LSP server
  "styler",           # Code formatting
  "lintr",            # Code linting
  "devtools",         # Development tools
  "usethis",          # Project setup
  "rmarkdown",        # R Markdown
  "knitr",            # Document generation
  "tidyverse",        # Data science packages
  "here",             # Path management
  "testthat"          # Testing framework
))
```

### 2. zzvim-R Configuration

The zzvim-R plugin provides these key mappings automatically:

**Core Execution:**
- `<CR>` - Smart R code execution (context-aware)
- `<Space>r` - Open R terminal

**Object Inspection:**
- `<Space>d` - dim() - dimensions
- `<Space>h` - head() - first rows  
- `<Space>s` - str() - structure
- `<Space>p` - print() - print object

**Navigation (R Markdown):**
- `<Space>j` - Next chunk
- `<Space>k` - Previous chunk
- `<Space>l` - Execute current chunk

## Testing and Verification

### 1. Basic Setup Test

```bash
# Test Neovim installation
nvim --version

# Test plugin manager
nvim -c "Lazy" -c "qa"
```

### 2. R Integration Test

1. **Open R file**: `nvim test.R`
2. **Test LSP**: `,tc` (should show R LSP attached)
3. **Test completion**: Type `libr` + `<Tab>` (should complete to `library()`)
4. **Test execution**: Write `x <- 1:10`, press `<CR>`
5. **Test inspection**: Position on `x`, press `<Space>d`

### 3. AI Integration Test

**Copilot:**
1. Start typing R code
2. Look for gray suggestions
3. Press `<C-l>` to accept

**Gemini:**
1. Press `,cc` to open chat
2. Ask: "How do I read a CSV file in R?"
3. Should get response from Gemini

## Troubleshooting

### Common Issues

**1. R LSP not starting:**
```r
# In R console, reinstall languageserver
install.packages("languageserver")
```

**2. Treesitter parsers missing:**
```vim
:TSInstall r markdown yaml
```

**3. Copilot not working:**
```vim
:Copilot status
:Copilot auth
```

**4. Gemini API errors:**
- Check API key is set: `echo $GEMINI_API_KEY`
- Verify rate limits (Flash model has higher limits)

**5. Completion not working:**
```vim
:LspInfo
:checkhealth nvim-cmp
```

### Debug Commands

```vim
" Check LSP status
:LspInfo

" Test R completion
,tc

" Check plugin status
:Lazy

" Health check
:checkhealth

" Check Treesitter
:TSInstall
```

## Key Features Summary

### ✅ **Complete R Development Environment**

**AI Assistants:**
- ✅ **GitHub Copilot** - Code suggestions (`<C-l>` to accept)
- ✅ **Google Gemini** - Chat assistance (`,cc`) and actions (`,ca`)

**R Development:**
- ✅ **zzvim-R** - Smart execution (`<CR>`) and object inspection (`<Space>d/h/s/p`)
- ✅ **R LSP** - Completion, hover docs, go-to-definition
- ✅ **Formatting** - Auto-format with styler (`,f`)
- ✅ **Diagnostics** - Real-time linting with trouble.nvim (`,d`)

**Modern Editor Features:**
- ✅ **Telescope** - Fuzzy finding (`,z` files, `,r` grep)
- ✅ **Flash** - Advanced movement (`s` for jump)
- ✅ **Treesitter** - Superior syntax highlighting
- ✅ **Lualine** - Modern status line
- ✅ **Gruvbox Material** - Professional theme

**Workflow Integration:**
- ✅ **Modular config** - Easy to maintain and extend
- ✅ **Cross-platform** - Works on macOS/Linux/Windows
- ✅ **Professional** - IDE-quality features with Vim efficiency

This setup provides a **complete professional R development environment** that rivals RStudio and VS Code while maintaining Vim's power and efficiency.