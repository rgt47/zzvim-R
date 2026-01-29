# zzvim-R Feature Roadmap: Closing the Gap with R.nvim

## Overview

This document outlines the implementation plan for features that would bring
zzvim-R to feature parity with R.nvim for research data analysis workflows.
Features are prioritized by impact on daily research workflows and
implementation complexity.

## Current Competitive Position

| Category | zzvim-R | R.nvim | Status |
|----------|---------|--------|--------|
| Plot Viewing | Integrated terminal graphics | External windows | **zzvim-R leads** |
| Vim Support | Vim 8+ and Neovim | Neovim only | **zzvim-R leads** |
| Setup | Minimal | Moderate | **zzvim-R leads** |
| Docker | Full integration | None | **zzvim-R leads** |
| Object Browser | Buffer HUDs (5 views) | Interactive tree | Close - R.nvim slightly ahead |
| Help System | Terminal output | Buffer display | R.nvim leads |
| Code Completion | External only | Built-in | R.nvim leads |
| R Markdown | Basic chunks | Advanced | R.nvim leads |

### Object Browser Detail

zzvim-R's HUD system is more capable than the comparison doc suggests:

- **5 specialized views**: Memory, DataFrames, Packages, Environment, Options
- **Buffer-based display**: Not terminal output, proper Vim buffers
- **Data viewer**: Opens data frames in split buffer with tabulation
- **Object inspection**: str()/glimpse() for any object
- **Dashboard mode**: All 5 HUDs in separate tabs

What R.nvim adds: hierarchical tree with expand/collapse, real-time updates,
click-to-drill-down interactivity. The gap is smaller than initially assessed.

---

## Phase 1: High Impact, Medium Effort

### 1.1 Buffer-Based Help Display

**Priority**: Critical
**Effort**: Medium (2-3 days)
**Impact**: High - used constantly during research

#### Current State

- `<LocalLeader>y` sends `help(topic)` to R terminal
- Output appears in terminal, scrolls away, cannot reference while coding

#### Proposed Implementation

```vim
" New commands
:RHelp topic           " Open help in split buffer
:RHelpK                " Help for word under cursor (override K)
<LocalLeader>?         " Help for word under cursor in buffer

" New config variables
let g:zzvim_r_help_position = 'vsplit'  " vsplit, split, tab, float
let g:zzvim_r_help_width = 80           " Width for vsplit
let g:zzvim_r_help_height = 20          " Height for split
```

#### Technical Approach

1. **Capture help output**: Use temp file approach like existing HUDs
   ```r
   capture.output(help(topic), file = tempfile)
   ```

2. **Parse and display**: Read temp file into scratch buffer with:
   - R help syntax highlighting (create `syntax/rhelp.vim`)
   - Searchable content
   - Read-only mode
   - Quick close with `q`

3. **Buffer management**:
   - Reuse existing help buffer if open
   - Track help buffer ID in script-local variable
   - Position based on `g:zzvim_r_help_position`

#### Implementation Skeleton

```vim
function! s:RHelpBuffer(topic) abort
    " Validate topic
    if empty(a:topic)
        let l:topic = expand('<cword>')
        if empty(l:topic)
            call s:Error("No topic specified")
            return
        endif
    else
        let l:topic = a:topic
    endif

    " Create temp file for help output
    let l:help_file = tempname() . '.Rhelp'
    let l:help_file_escaped = substitute(l:help_file, '\', '/', 'g')

    " Send R command to capture help
    let l:cmd = printf(
        \ 'tryCatch({h <- help("%s"); ' .
        \ 'if(length(h) > 0) {' .
        \ 'txt <- capture.output(tools:::Rd2txt(utils:::.getHelpFile(h)));' .
        \ 'writeLines(txt, "%s");' .
        \ 'cat("HELP_OK\n")} else cat("HELP_NOT_FOUND\n")}, ' .
        \ 'error = function(e) cat("HELP_ERROR:", e$message, "\n"))',
        \ l:topic, l:help_file_escaped)

    call s:Send_to_r(l:cmd, 1)

    " Wait for file (with timeout)
    let l:timeout = 50  " 50 * 100ms = 5 seconds
    while !filereadable(l:help_file) && l:timeout > 0
        sleep 100m
        let l:timeout -= 1
    endwhile

    if !filereadable(l:help_file)
        call s:Error("Help not found for: " . l:topic)
        return
    endif

    " Open in buffer
    call s:OpenHelpBuffer(l:help_file, l:topic)

    " Clean up temp file
    call delete(l:help_file)
endfunction

function! s:OpenHelpBuffer(file, topic) abort
    " Close existing help buffer if any
    if exists('s:help_bufnr') && bufexists(s:help_bufnr)
        execute 'bwipeout ' . s:help_bufnr
    endif

    " Open based on position setting
    let l:pos = get(g:, 'zzvim_r_help_position', 'vsplit')
    if l:pos == 'vsplit'
        let l:width = get(g:, 'zzvim_r_help_width', 80)
        execute 'vertical ' . l:width . 'split ' . fnameescape(a:file)
    elseif l:pos == 'split'
        let l:height = get(g:, 'zzvim_r_help_height', 20)
        execute l:height . 'split ' . fnameescape(a:file)
    elseif l:pos == 'tab'
        execute 'tabnew ' . fnameescape(a:file)
    else
        execute 'split ' . fnameescape(a:file)
    endif

    " Configure buffer
    setlocal buftype=nofile
    setlocal bufhidden=wipe
    setlocal noswapfile
    setlocal nomodifiable
    setlocal readonly
    setlocal filetype=rhelp
    execute 'file R-help:' . a:topic

    " Save buffer number
    let s:help_bufnr = bufnr('%')

    " Quick close mapping
    nnoremap <buffer> q :bwipeout<CR>
    nnoremap <buffer> <ESC> :bwipeout<CR>

    " Navigation within help
    nnoremap <buffer> <CR> :call <SID>RHelpFollowLink()<CR>

    " Go to top
    normal! gg
endfunction
```

#### Syntax File (syntax/rhelp.vim)

```vim
" R Help syntax highlighting
if exists("b:current_syntax")
    finish
endif

syn match rhelpSection "^[A-Z][A-Za-z ]*:$"
syn match rhelpTitle "^_\+.*_\+$"
syn match rhelpCode "'[^']*'"
syn match rhelpArg "^\s*[a-zA-Z_.][a-zA-Z0-9_.]*:"
syn match rhelpLink "\\link{[^}]*}"
syn region rhelpExample start="^Examples:" end="^\S" contains=rhelpCode

hi def link rhelpSection Title
hi def link rhelpTitle Statement
hi def link rhelpCode String
hi def link rhelpArg Identifier
hi def link rhelpLink Underlined
hi def link rhelpExample Comment

let b:current_syntax = "rhelp"
```

#### Key Mappings

```vim
command! -nargs=? -complete=custom,s:RHelpComplete RHelp call s:RHelpBuffer(<q-args>)
autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> <LocalLeader>? :call <SID>RHelpBuffer('')<CR>
autocmd FileType r,rmd,qmd nnoremap <buffer> <silent> K :call <SID>RHelpBuffer('')<CR>
```

---

### 1.2 Completion Documentation

**Priority**: High
**Effort**: Low (1 day)
**Impact**: Critical - enables code completion without custom setup

Rather than building completion into zzvim-R (high effort, duplicates
existing tools), provide first-class documentation for integrating with
established completion engines.

#### Deliverable: docs/COMPLETION_SETUP.md

```markdown
# Code Completion Setup for zzvim-R

zzvim-R does not include built-in code completion. Instead, it integrates
with established completion engines that provide superior completion from
R's language server.

## Recommended: coc.nvim + coc-r-lsp

### Prerequisites
- Node.js 14+
- R with languageserver package: `install.packages("languageserver")`

### Installation

1. Install coc.nvim (Vim 8+ or Neovim):
   ```vim
   Plug 'neoclide/coc.nvim', {'branch': 'release'}
   ```

2. Install coc-r-lsp:
   ```vim
   :CocInstall coc-r-lsp
   ```

3. Configure (in coc-settings.json):
   ```json
   {
     "r.lsp.enabled": true,
     "r.lsp.diagnostics": true
   }
   ```

### What You Get
- Function completion from loaded packages
- Argument hints with documentation
- Data frame column completion after $ and [[
- Workspace object names
- Documentation preview

## Alternative: nvim-cmp + nvim-lspconfig (Neovim only)

### Prerequisites
- Neovim 0.8+
- R with languageserver package

### Installation

```lua
-- In your Neovim config (init.lua or plugins.lua)
return {
  'neovim/nvim-lspconfig',
  'hrsh7th/nvim-cmp',
  'hrsh7th/cmp-nvim-lsp',
}
```

### Configuration

```lua
-- LSP setup
require('lspconfig').r_language_server.setup({
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
})

-- nvim-cmp setup
local cmp = require('cmp')
cmp.setup({
  sources = {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
})
```

## Minimal: Vim's Built-in Completion

For users who prefer no external dependencies:

```vim
" Use Vim's built-in completion with dictionary
autocmd FileType r setlocal complete+=k~/.vim/dict/r.dict
```

Download an R dictionary file or generate one from installed packages.

## Troubleshooting

### languageserver not starting
- Verify installation: `R -e "library(languageserver)"`
- Check R path in Vim: `:echo exepath('R')`

### No completion in R Markdown
- Ensure the chunk has `{r}` header
- Some LSP clients need explicit R filetype for embedded chunks
```

---

## Phase 2: Medium Impact, Medium Effort

### 2.1 Enhanced Object Browser (Upgrade Existing HUD)

**Priority**: High
**Effort**: Medium (2-3 days)
**Impact**: High - data exploration is 30% of research workflow

#### Current State (Already Implemented)

zzvim-R already has a comprehensive HUD system:

- `<LocalLeader>'` - Workspace overview (objects with class) in buffer
- `<LocalLeader>m` - Memory HUD (object sizes sorted by size)
- `<LocalLeader>e` - DataFrames HUD (row × column dimensions)
- `<LocalLeader>z` - Package HUD (loaded packages)
- `<LocalLeader>i` - Inspect object (str/glimpse output)
- `<LocalLeader>v` - Data viewer (opens data frame in split buffer)
- `<LocalLeader>x` - Environment variables HUD
- `<LocalLeader>a` - Full HUD Dashboard (5 tabs: Memory, DataFrames,
  Packages, Environment, Options)
- `<LocalLeader>0` - Refresh all HUD tabs

**What's missing vs R.nvim:**

1. No tree structure with expand/collapse
2. No real-time auto-refresh
3. No interactive drill-down (click object → see contents)

#### Proposed Enhancements

Upgrade existing HUD to add interactivity, not replace it.

```vim
" Enhancement to existing workspace HUD
" Add interactivity to <LocalLeader>' workspace view

" New config variables
let g:zzvim_r_browser_auto_refresh = 0    " Auto-refresh interval (0=disabled)
```

#### Enhancement 1: Interactive Workspace Buffer

Add key mappings to existing workspace HUD buffer:

```vim
" In workspace buffer:
<CR>    " On object line: inspect with str()/glimpse()
o       " Open in data viewer (if data frame)
h       " Show head() output
n       " Show names() output
r       " Refresh workspace view
q       " Close buffer
```

#### Enhancement 2: Tree-Style Display (Optional)

Upgrade `<LocalLeader>'` output format:

```
R Workspace [15 objects] [r=refresh, <CR>=inspect]
──────────────────────────────────────────────────
▸ df1         data.frame   1000 × 15    2.4 MB
▸ df2         tibble        500 × 8     0.8 MB
  model1      lm                        1.2 MB
  x           numeric      [100]        0.1 KB
▸ results     list         [3]          0.5 MB
──────────────────────────────────────────────────
Total: 5.0 MB
```

Where `▸` indicates expandable objects (data frames, lists).

#### Enhancement 3: Auto-Refresh (Low Priority)

Use timer-based polling like plot watcher:

```vim
let g:zzvim_r_browser_auto_refresh = 5000  " Refresh every 5 seconds
```

#### Implementation Notes

- Build on existing `s:RWorkspaceOverview()` function
- Add buffer-local mappings after creating HUD buffer
- Parse object names from buffer content for interactivity
- Reuse existing `s:RInspectObject()`, `s:RDataViewer()` functions

---

### 2.2 Enhanced R Markdown Support

**Priority**: High
**Effort**: Medium (2-3 days)
**Impact**: High - literate programming standard in research

#### Current State

- `<LocalLeader>j/k` navigate chunks
- `<LocalLeader>l` submit current chunk
- `<LocalLeader>t` submit previous chunks
- No chunk insertion, no rendering commands

#### Proposed Additions

```vim
" Chunk management
<LocalLeader>ci        " Insert new R chunk below cursor
<LocalLeader>cI        " Insert new R chunk above cursor
<LocalLeader>cd        " Delete current chunk
<LocalLeader>ca        " Run all chunks
<LocalLeader>cr        " Run all chunks above current

" Rendering
:RMarkdownRender [format]   " Render document (html, pdf, word)
:RMarkdownPreview           " Render and open in browser
<LocalLeader>rp             " Quick render to HTML and preview

" Chunk options
<LocalLeader>co        " Toggle chunk options (eval, echo, etc.)
```

#### Implementation Skeleton

```vim
" Insert R chunk
function! s:InsertRChunk(above) abort
    let l:chunk = ['```{r}', '', '```']
    if a:above
        call append(line('.') - 1, l:chunk)
        normal! k
    else
        call append(line('.'), l:chunk)
        normal! j
    endif
    normal! j
    startinsert
endfunction

" Render document
function! s:RMarkdownRender(format) abort
    let l:format = empty(a:format) ? 'html_document' : a:format
    let l:file = expand('%:p')
    let l:file_escaped = substitute(l:file, '\', '/', 'g')

    " Save current buffer
    write

    " Build render command
    let l:cmd = printf(
        \ 'rmarkdown::render("%s", output_format = "%s")',
        \ l:file_escaped, l:format)

    call s:Send_to_r(l:cmd, 0)
    echom "Rendering " . expand('%:t') . " to " . l:format
endfunction

" Preview (render + open)
function! s:RMarkdownPreview() abort
    let l:file = expand('%:p')
    let l:output = expand('%:p:r') . '.html'

    " Render
    call s:RMarkdownRender('html_document')

    " Open in browser (after delay for rendering)
    " This is platform-specific
    if has('mac')
        call system('sleep 3 && open "' . l:output . '" &')
    elseif has('unix')
        call system('sleep 3 && xdg-open "' . l:output . '" &')
    endif
endfunction
```

---

### 2.3 Error Navigation

**Priority**: Medium
**Effort**: Medium (2 days)
**Impact**: Medium - improves debugging workflow

#### Proposed Implementation

```vim
:RErrors               " Parse R terminal for errors, populate quickfix
:RErrorsClear          " Clear R error quickfix
<LocalLeader>re        " Parse errors and jump to first
```

#### Technical Approach

1. **Parse R terminal buffer** for error patterns:
   ```
   Error in file.R:42:15: unexpected ')'
   Error: object 'x' not found
     at script.R#15
   ```

2. **Extract file:line** references using regex patterns

3. **Populate quickfix** with `setqflist()`

```vim
function! s:RParseErrors() abort
    " Find R terminal buffer
    let l:term_bufnr = s:GetRTerminalBuffer()
    if l:term_bufnr == -1
        call s:Error("No R terminal found")
        return
    endif

    " Get terminal content
    let l:lines = getbufline(l:term_bufnr, 1, '$')

    " Error patterns to match
    let l:patterns = [
        \ '\vError in ([^:]+):(\d+):(\d+): (.+)',
        \ '\vError.*at ([^#]+)#(\d+)',
        \ '\vError in source\("([^"]+)"\).*line (\d+)',
    \]

    let l:qf_items = []

    for l:line in l:lines
        for l:pat in l:patterns
            let l:match = matchlist(l:line, l:pat)
            if !empty(l:match)
                call add(l:qf_items, {
                    \ 'filename': l:match[1],
                    \ 'lnum': l:match[2],
                    \ 'col': get(l:match, 3, 1),
                    \ 'text': get(l:match, 4, l:line),
                    \ 'type': 'E'
                \})
            endif
        endfor
    endfor

    if empty(l:qf_items)
        echom "No R errors found"
        return
    endif

    call setqflist(l:qf_items)
    copen
    cfirst
endfunction
```

---

## Phase 3: Lower Priority / Advanced Features

### 3.1 Session Management

**Effort**: Low (1 day)
**Impact**: Medium

Simple wrappers around R's session functions:

```vim
command! -nargs=? RSaveWorkspace call s:Send_to_r('save.image("' . (empty(<q-args>) ? '.RData' : <q-args>) . '")', 1)
command! -nargs=? RLoadWorkspace call s:Send_to_r('load("' . (empty(<q-args>) ? '.RData' : <q-args>) . '")', 1)
command! -nargs=? RSaveHistory call s:Send_to_r('savehistory("' . (empty(<q-args>) ? '.Rhistory' : <q-args>) . '")', 1)
```

### 3.2 Package Development Tools

**Effort**: Low (1 day)
**Impact**: Low-Medium

Wrappers for devtools functions:

```vim
command! -bar RCheck call s:Send_to_r('devtools::check()', 0)
command! -bar RDocument call s:Send_to_r('devtools::document()', 0)
command! -bar RTest call s:Send_to_r('devtools::test()', 0)
command! -bar RLoad call s:Send_to_r('devtools::load_all()', 0)
command! -bar RBuild call s:Send_to_r('devtools::build()', 0)
command! -bar RInstall call s:Send_to_r('devtools::install()', 0)
```

### 3.3 Remote/SSH Support

**Effort**: High (5+ days)
**Impact**: Medium

This requires significant architecture changes to support:

- SSH tunneling for terminal communication
- Tmux session attachment
- Remote file synchronization

Defer unless user demand is high.

### 3.4 Debugging Integration

**Effort**: High (5+ days)
**Impact**: Medium

R's debugging facilities (browser, debug, trace) could be better integrated:

```vim
<LocalLeader>db    " Insert browser() at current line
<LocalLeader>dd    " debug(function_under_cursor)
<LocalLeader>du    " undebug(function_under_cursor)
```

More advanced integration (breakpoint markers, step navigation) requires
significant complexity.

---

## Implementation Schedule

| Phase | Feature | Effort | Priority |
|-------|---------|--------|----------|
| 1.1 | Buffer-Based Help | 2-3 days | **High impact** |
| 1.2 | Completion Docs | 1 day | Quick win |
| 2.1 | Object Browser Enhancements | 1-2 days | Builds on existing |
| 2.2 | R Markdown Enhanced | 2-3 days | High value |
| 2.3 | Error Navigation | 2 days | Nice to have |
| 3.1 | Session Management | 0.5 day | Easy add |
| 3.2 | Package Dev Tools | 0.5 day | Easy add |
| 3.3 | Remote/SSH | 5+ days | Defer |
| 3.4 | Debugging | 5+ days | Defer |

**Recommended order**: 1.2 → 3.1 → 3.2 → 2.1 → 1.1 → 2.2 → 2.3

1. **Completion docs** (1 day) - Quick win, enables LSP completion
2. **Session management** (0.5 day) - Trivial wrappers
3. **Package dev tools** (0.5 day) - Trivial wrappers
4. **Object browser enhancements** (1-2 days) - Add interactivity to existing HUDs
5. **Buffer-based help** (2-3 days) - Highest daily-use impact
6. **R Markdown enhanced** (2-3 days) - High value for research
7. **Error navigation** (2 days) - Nice debugging improvement

---

## Success Criteria

After implementing Phases 1 and 2, zzvim-R would:

1. **Lead** in: Plot viewing, Vim support, Docker integration, setup simplicity
2. **Match** in: Help system, R Markdown support, object browser, error handling
3. **Trail** in: Completion (documented external setup vs built-in)

This positions zzvim-R as the clear choice for:

- Vim users (only option with active development)
- Kitty terminal users (superior plot viewing)
- Docker-based workflows (native integration)
- Users who value simplicity over features

R.nvim remains stronger for users who need:

- Built-in completion without external setup
- Real-time object browser with auto-refresh
- Neovim-specific features (Lua integration, float windows)

---

## References

- R.nvim source: https://github.com/R-nvim/R.nvim
- nvimcom documentation: https://rdrr.io/github/jalvesaq/nvimcom/
- R languageserver: https://github.com/REditorSupport/languageserver
- coc-r-lsp: https://github.com/neoclide/coc-r-lsp
