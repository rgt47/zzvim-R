# zzvim-R v1.0.0 Announcement Drafts
*2026-04-16 16:54 PDT*

Drafts for Phase 8 (announcement). Edit to taste before posting.
The plan recommends waiting one week after tagging for bug reports
before announcing widely.

---

## 1. Launch blog post (dev.to / personal blog / r-bloggers)

Title: **zzvim-R: a lightweight R plugin for Vim and Neovim**

Tags: `#rstats` `#vim` `#neovim` `#datascience`

---

I have been writing R in Vim for several years. The existing
options -- Nvim-R (now archived), R.nvim (Neovim-only, Lua), and
vim-slime (language-agnostic) -- each had trade-offs that left me
wanting something different. So I wrote zzvim-R and have been
using it as my daily driver since mid-2025. Today it reaches v1.0.

### What it does

zzvim-R integrates Vim (8.0+) and Neovim with R. Press `<CR>` on
any line and the plugin detects the full expression -- function
body, pipe chain, ggplot `+` chain, control block, multi-line
call -- and sends it to an R terminal. No selection needed. It
works with `.R`, `.Rmd`, and `.qmd` files.

**Core features:**

- **Smart code submission.** Pattern detection for functions,
  pipes (`|>` and `%>%`), ggplot layers, control structures,
  and nested delimiters. One key sends the right amount of code.
- **Multi-terminal sessions.** Each buffer gets its own R process.
  Work on two scripts simultaneously without cross-contamination.
- **R Markdown / Quarto.** Navigate chunks (`j`/`k`), execute
  them (`l`), insert new chunks, render documents.
- **Object inspection.** `head`, `str`, `dim`, `names`, `glimpse`
  on the word under the cursor. No typing R commands by hand.
- **Workspace HUD.** A tabbed dashboard showing memory usage,
  data frames, loaded packages, environment variables, and R
  session options.
- **Inline plots.** PDF master + PNG preview displayed in Kitty,
  Ghostty, WezTerm, or iTerm2 terminal panes. Plot history with
  navigation.
- **Docker integration.** Auto-detects zzcollab workspaces and
  launches R inside the container via `make r`.

### Design choices

**VimScript, not Lua.** This means it works in both Vim and
Neovim without a compatibility layer. The startup cost is 2 ms.

**Pattern detection, not tree-sitter.** The plugin uses regex-based
pattern matching to detect R code structures. This avoids a
tree-sitter dependency and works identically in Vim 8 and Neovim.
The trade-off is that deeply nested or unusual syntax can
occasionally confuse the detector. In practice, standard R idioms
(tidyverse pipes, ggplot layers, base R functions) are handled
reliably.

**Single key for everything.** `<CR>` is context-aware. On a
simple line it sends that line. Inside a function body it sends
the whole function. On a pipe chain it sends the full chain. The
goal is that you never think about what to select before sending.

### How it compares

| | zzvim-R | R.nvim | vim-slime |
|---|---|---|---|
| Editor | Vim + Neovim | Neovim only | Vim + Neovim |
| Language | VimScript | Lua | VimScript |
| R-aware | Yes | Yes | No |
| Smart send | Pattern-based | Tree-sitter | Manual selection |
| Workspace HUD | Yes | Yes | No |
| Inline plots | Yes | Yes | No |
| Weight | ~4K lines | ~15K lines | ~500 lines |

R.nvim is the more feature-rich option if you use Neovim
exclusively. vim-slime is the lighter option if you just need a
REPL bridge. zzvim-R sits in between: R-aware intelligence with
broad editor compatibility and moderate weight.

### Install

```vim
" lazy.nvim
{ 'rgt47/zzvim-R', ft = { 'r', 'rmd', 'quarto' } }

" vim-plug
Plug 'rgt47/zzvim-R'
```

Full quickstart guide:
https://github.com/rgt47/zzvim-R/blob/main/docs/quickstart-guide.md

### What is next

v1.1 will complete the autoload extraction (started in 1.0),
add `ftplugin/` wiring, `:checkhealth` support, and a
`compiler/r.vim` for quickfix integration. Contributions are
welcome -- the repo has a structured test suite (67 functional
specs + CI) and YAML issue forms.

https://github.com/rgt47/zzvim-R

---

## 2. r/neovim post

**Title:** zzvim-R v1.0 -- lightweight R plugin for Vim and Neovim

**Flair:** Plugin

**Body:**

I have been building an R integration plugin that works in both
Vim (8.0+) and Neovim. It just hit v1.0.

The main idea: press `<CR>` and the plugin detects the full
expression (function body, pipe chain, ggplot layers, multi-line
call) and sends it to R. No manual selection.

Also includes: multi-terminal sessions (one R per buffer), R
Markdown chunk navigation, object inspection shortcuts, a
workspace HUD dashboard, and inline plot display for
Kitty/Ghostty/WezTerm/iTerm2.

Written in VimScript, ~4K lines, 2 ms startup. Not a Lua plugin
-- works in classic Vim too.

How it differs from R.nvim: lighter, dual-editor, regex-based
pattern detection instead of tree-sitter. R.nvim is the right
choice if you want the full-featured Neovim-native experience.
zzvim-R is for people who want something that also works in Vim
or who prefer a lighter footprint.

Install: `Plug 'rgt47/zzvim-R'` or
`{ 'rgt47/zzvim-R', ft = { 'r', 'rmd', 'quarto' } }`

Quickstart guide with 10 features to try:
https://github.com/rgt47/zzvim-R/blob/main/docs/quickstart-guide.md

Feedback and bug reports welcome. The repo has structured issue
forms and a test suite.

---

## 3. r/rstats post

**Title:** zzvim-R v1.0 -- R development plugin for Vim/Neovim

**Body:**

For those who use Vim or Neovim for R development: I released
v1.0 of zzvim-R, a plugin that provides smart code submission,
workspace inspection, R Markdown support, and inline plot
display.

The core feature: press Enter on any line and the plugin figures
out the full expression (function definition, pipe chain, ggplot
layers) and sends it to R. It handles `.R`, `.Rmd`, and `.qmd`
files.

Other highlights:

- Object inspection: `head`, `str`, `dim`, `names`, `glimpse` on
  the word under the cursor
- Workspace dashboard: memory usage, data frames, loaded packages
- Inline plots in Kitty/Ghostty/WezTerm/iTerm2
- Each buffer gets its own R terminal session

Works with both Vim (8.0+) and Neovim. Written in VimScript, no
external dependencies beyond R.

Quickstart guide:
https://github.com/rgt47/zzvim-R/blob/main/docs/quickstart-guide.md

GitHub: https://github.com/rgt47/zzvim-R

---

## 4. Mastodon (#rstats)

zzvim-R v1.0 released -- R development plugin for Vim and Neovim.

Smart code submission (press Enter, plugin detects the full
expression), workspace HUD, object inspection, R Markdown chunk
navigation, inline plots.

Works in both Vim 8+ and Neovim. Lightweight VimScript, 2 ms
startup.

https://github.com/rgt47/zzvim-R

#rstats #vim #neovim #datascience

---

## 5. This Week in Neovim submission

PR to https://github.com/phaazon/this-week-in-neovim-contents
in the week of release.

**Entry:**

### [zzvim-R](https://github.com/rgt47/zzvim-R) v1.0

R integration plugin for Vim and Neovim. Smart `<CR>` submission
detects functions, pipe chains, and ggplot layers. Includes
multi-terminal sessions, workspace HUD, object inspection, R
Markdown chunk navigation, and inline plot display for Kitty
protocol terminals. VimScript, dual-editor, 2 ms startup.

---

## Posting sequence

Per the release plan (docs/RELEASE_PLAN.md Phase 8):

1. **Now:** tag is live, wait one week for bug reports.
2. **Week 1:** publish blog post; register RSS feed with
   r-bloggers.com if not already done.
3. **Day of blog publish:** post to r/neovim, r/rstats, Mastodon.
4. **Same week:** submit This Week in Neovim PR.
5. **2+ weeks after release:** submit awesome-neovim PR once some
   organic stars accumulate.

---
*Rendered on 2026-04-16 at 17:25 PDT.*<br>
*Source: ~/prj/sfw/04-zzvim-r/zzvim-R/docs/announcement-drafts.md*
