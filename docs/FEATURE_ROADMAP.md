# zzvim-R Feature Roadmap: Incremental Improvements

## Overview

This document outlines potential enhancements to zzvim-R. These are
incremental improvements to an already competitive plugin, not gap-closing
measures. zzvim-R's integrated terminal graphics, comprehensive HUD system,
and Vim compatibility already position it strongly against R.nvim.

## Current Competitive Position

| Category | zzvim-R | R.nvim | Assessment |
|----------|---------|--------|------------|
| Plot Viewing | Integrated terminal graphics | External windows | **zzvim-R leads significantly** |
| Vim Support | Vim 8+ and Neovim | Neovim only | **zzvim-R only option** |
| Setup | Minimal (no R packages) | Moderate (nvimcom) | **zzvim-R leads** |
| Docker | Full integration | None | **zzvim-R leads** |
| Object Browser | 5 buffer-based HUDs | Interactive tree | Different approaches, both functional |
| Help System | Terminal output | Buffer display | R.nvim slightly better |
| Code Completion | External LSP | External LSP | Equal (both use languageserver) |
| R Markdown | Navigation + execution | + rendering commands | R.nvim slightly better |

### Key Insight

zzvim-R is not "behind" R.nvim. The terminal graphics system alone is a
major differentiator that R.nvim cannot match. The remaining differences
are minor workflow preferences, not fundamental capability gaps.

## Existing Capabilities (Often Underappreciated)

### Terminal Graphics System
- Kitty/Ghostty/WezTerm/iTerm2 support
- Dual-resolution rendering (600×450 pane + 1800×1350 zoom)
- Automatic plot watcher with signal-based detection
- Plot history with navigation (`<LocalLeader><` / `>`)
- Gallery viewer (`:RPlotGallery`)
- Persistent history with search

### HUD System (Buffer-Based, Not Terminal)
- `<LocalLeader>0` - Full 5-tab dashboard
- `<LocalLeader>m` - Memory usage (sorted by size)
- `<LocalLeader>e` - Data frames (dimensions)
- `<LocalLeader>z` - Loaded packages
- `<LocalLeader>x` - Environment variables
- `<LocalLeader>'` - Workspace overview
- `<LocalLeader>i` - Object inspection (str/glimpse)
- `<LocalLeader>v` - Data viewer with tabulation

### Code Completion (Already Documented)
README.md contains complete LSP setup for:
- CoC (Vim + Neovim)
- nvim-cmp (Neovim)
- Native LSP (Neovim)

No additional documentation needed.

---

## Phase 1: Genuine Improvements

### 1.1 R Markdown Rendering Commands

**Effort**: 1 day
**Value**: High - only real feature gap for research workflows

#### Current State
- `<LocalLeader>j/k` - chunk navigation
- `<LocalLeader>l` - execute current chunk
- `<LocalLeader>t` - execute previous chunks

#### Missing
- No render commands
- No chunk insertion

#### Implementation

```vim
" Commands
command! -nargs=? RMarkdownRender call s:RMarkdownRender(<q-args>)
command! -bar RMarkdownPreview call s:RMarkdownPreview()

" Mappings
autocmd FileType rmd,qmd nnoremap <buffer> <LocalLeader>rp :RMarkdownPreview<CR>
autocmd FileType rmd,qmd nnoremap <buffer> <LocalLeader>ci :call <SID>InsertRChunk(0)<CR>
autocmd FileType rmd,qmd nnoremap <buffer> <LocalLeader>cI :call <SID>InsertRChunk(1)<CR>

" Functions
function! s:RMarkdownRender(format) abort
    let l:format = empty(a:format) ? 'html_document' : a:format
    let l:file = expand('%:p')
    let l:file_escaped = substitute(l:file, '\', '/', 'g')
    write
    call s:Send_to_r(printf('rmarkdown::render("%s", output_format = "%s")',
        \ l:file_escaped, l:format), 0)
    echom "Rendering " . expand('%:t') . " to " . l:format
endfunction

function! s:RMarkdownPreview() abort
    call s:RMarkdownRender('html_document')
    let l:output = expand('%:p:r') . '.html'
    if has('mac')
        call system('(sleep 2 && open "' . l:output . '") &')
    elseif has('unix')
        call system('(sleep 2 && xdg-open "' . l:output . '") &')
    endif
endfunction

function! s:InsertRChunk(above) abort
    let l:chunk = ['```{r}', '', '```']
    call append(a:above ? line('.') - 1 : line('.'), l:chunk)
    execute 'normal!' (a:above ? 'k' : 'j') . 'j'
    startinsert
endfunction
```

---

### 1.2 Help in Buffer

**Effort**: 1-2 days
**Value**: Medium - genuine workflow improvement

#### Current State
- `<LocalLeader>y` sends `help(topic)` to R terminal
- Output scrolls in terminal, cannot reference while coding

#### Implementation

```vim
" Commands
command! -nargs=? RHelp call s:RHelpBuffer(<q-args>)

" Mappings
autocmd FileType r,rmd,qmd nnoremap <buffer> <LocalLeader>? :call <SID>RHelpBuffer('')<CR>
autocmd FileType r,rmd,qmd nnoremap <buffer> K :call <SID>RHelpBuffer('')<CR>

" Configuration
let g:zzvim_r_help_position = get(g:, 'zzvim_r_help_position', 'vsplit')
let g:zzvim_r_help_width = get(g:, 'zzvim_r_help_width', 80)

" Main function
function! s:RHelpBuffer(topic) abort
    let l:topic = empty(a:topic) ? expand('<cword>') : a:topic
    if empty(l:topic)
        call s:Error("No topic specified")
        return
    endif

    let l:help_file = tempname() . '.Rhelp'
    let l:cmd = printf(
        \ 'tryCatch({h <- help("%s"); ' .
        \ 'if(length(h) > 0) {' .
        \ 'writeLines(capture.output(tools:::Rd2txt(' .
        \ 'utils:::.getHelpFile(h))), "%s")} ' .
        \ 'else cat("No help found\n")}, ' .
        \ 'error = function(e) cat("Error:", e$message, "\n"))',
        \ l:topic, substitute(l:help_file, '\', '/', 'g'))

    call s:Send_to_r(l:cmd, 1)

    " Wait for file with timeout
    let l:tries = 30
    while !filereadable(l:help_file) && l:tries > 0
        sleep 100m
        let l:tries -= 1
    endwhile

    if !filereadable(l:help_file)
        call s:Error("Help not found: " . l:topic)
        return
    endif

    " Close existing help buffer
    if exists('s:help_bufnr') && bufexists(s:help_bufnr)
        execute 'bwipeout' s:help_bufnr
    endif

    " Open help buffer
    let l:pos = g:zzvim_r_help_position
    if l:pos == 'vsplit'
        execute 'vertical' g:zzvim_r_help_width . 'split' fnameescape(l:help_file)
    elseif l:pos == 'tab'
        execute 'tabnew' fnameescape(l:help_file)
    else
        execute 'split' fnameescape(l:help_file)
    endif

    " Configure buffer
    setlocal buftype=nofile bufhidden=wipe noswapfile readonly nomodifiable
    execute 'file R:' . l:topic
    let s:help_bufnr = bufnr('%')

    " Buffer mappings
    nnoremap <buffer> q :bwipeout<CR>
    nnoremap <buffer> <Esc> :bwipeout<CR>

    normal! gg
    call delete(l:help_file)
endfunction
```

---

## Phase 2: Polish (Optional)

### 2.1 HUD Interactivity

**Effort**: 2 hours
**Value**: Low - convenience improvement

Add buffer-local mappings to existing HUD buffers for drill-down:

```vim
" Add to HUD buffer setup
nnoremap <buffer> <CR> :call <SID>HUDInspectLine()<CR>
nnoremap <buffer> o :call <SID>HUDOpenViewer()<CR>
nnoremap <buffer> h :call <SID>HUDHead()<CR>
nnoremap <buffer> r :call <SID>RefreshHUD()<CR>
nnoremap <buffer> q :bwipeout<CR>

function! s:HUDInspectLine() abort
    let l:line = getline('.')
    let l:obj = matchstr(l:line, '^\s*\zs\w\+')
    if !empty(l:obj)
        call s:RInspectObject(l:obj)
    endif
endfunction

function! s:HUDOpenViewer() abort
    let l:line = getline('.')
    let l:obj = matchstr(l:line, '^\s*\zs\w\+')
    if !empty(l:obj)
        " Check if data frame, then open viewer
        call s:Send_to_r('if(is.data.frame(' . l:obj . ')) View(' . l:obj . ')', 1)
    endif
endfunction
```

### 2.2 Error Navigation

**Effort**: 1 day
**Value**: Low - R errors often lack file:line references

```vim
command! -bar RErrors call s:RParseErrors()

function! s:RParseErrors() abort
    let l:term_bufnr = s:GetRTerminalBuffer()
    if l:term_bufnr == -1
        call s:Error("No R terminal found")
        return
    endif

    let l:qf_items = []
    for l:line in getbufline(l:term_bufnr, 1, '$')
        " Pattern: Error in file.R:42: message
        let l:m = matchlist(l:line, '\vError in ([^:]+):(\d+)')
        if !empty(l:m)
            call add(l:qf_items, {
                \ 'filename': l:m[1], 'lnum': l:m[2],
                \ 'text': l:line, 'type': 'E'})
        endif
    endfor

    if empty(l:qf_items)
        echom "No R errors with file references found"
    else
        call setqflist(l:qf_items)
        copen
    endif
endfunction
```

---

## Features NOT Recommended

### Session Management Wrappers
```vim
:RSaveWorkspace  →  save.image()
:RCheck          →  devtools::check()
```
**Reason**: Marginal value. Typing the R command is equally easy.

### Remote/SSH Support
**Reason**: High effort (5+ days), niche use case. Users needing remote R
typically have established workflows (tmux, SSH port forwarding).

### Debugging Integration
**Reason**: High effort, R's debugging is painful regardless of editor
integration. `browser()` insertion is already trivial.

### Additional Completion Documentation
**Reason**: Already comprehensive in README.md.

---

## Implementation Summary

| Feature | Effort | Value | Status |
|---------|--------|-------|--------|
| R Markdown render | 1 day | High | Recommended |
| Help in buffer | 1-2 days | Medium | Recommended |
| HUD interactivity | 2 hours | Low | Optional polish |
| Error navigation | 1 day | Low | Optional polish |

**Total for recommended features: 2-3 days**

---

## Conclusion

zzvim-R is already a strong R development environment. The integrated
terminal graphics system provides a workflow advantage that R.nvim cannot
match. The HUD system, while different from R.nvim's tree browser, is
comprehensive and functional.

The improvements outlined here are incremental polish:
- R Markdown rendering fills a genuine (small) gap
- Help in buffer improves documentation workflow
- HUD interactivity adds convenience

These are not transformational changes because none are needed. zzvim-R
competes effectively with R.nvim today, with clear advantages for:
- Vim users (only maintained option)
- Kitty/Ghostty/WezTerm users (superior plot viewing)
- Docker-based workflows (native integration)
- Users who value simplicity (no external R packages required)
