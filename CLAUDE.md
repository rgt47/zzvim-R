# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

zzvim-R is a Vim/Neovim plugin (VimScript) providing R integration: code
submission, multi-terminal management, R Markdown chunk navigation, object
inspection, a vim-peekaboo style object browser, a plot display pipeline
(PDF master + PNG preview in `.plots/`), and a set of HUD panels for the
R workspace.

## Layout

- `plugin/zzvim-R.vim` — the plugin. Single-file architecture, ~3800 lines.
  All commands, mappings, and script-local (`s:`) functions live here.
- `autoload/zzvimr/terminal_graphics.vim` — terminal-graphics detection
  (Kitty / Ghostty / WezTerm / iTerm2) and `.Rprofile.local` template
  injection. `s:template_version` here is the source of truth for the
  `.Rprofile.local` template version check (currently 9).
- `doc/zzvim-R.txt` — Vim help. Regenerate tags with
  `vim -c 'helptags doc/' -c 'quit'` after edits.
- `docs/` — design notes, comparison writeups, HUD/plot design docs.
- `test_files/` — ad-hoc `.vim` / `.R` scratch harnesses used during
  development. Not a structured test suite; the `Makefile` `test` target
  references a `test/rgt-R.vader` file that does not exist in the tree.
  Treat these as manual reproducers, not CI.

## Architecture notes that are not obvious from one file

- **Single-file plugin.** Everything loads via `plugin/zzvim-R.vim` guarded
  by `g:loaded_zzvim_r`. There is no split across multiple autoload files
  except the terminal-graphics helper. When adding a feature, follow the
  existing pattern: `s:` function + `command! -bar RFoo` + optional
  `<LocalLeader>` mapping gated by `g:zzvim_r_disable_mappings`.

- **Vim/Neovim compatibility shim.** Near the top of `plugin/zzvim-R.vim`
  there is a compatibility layer (`s:compat_term_list`,
  `s:compat_term_getstatus`, etc.) that wraps terminal APIs for Neovim.
  Use these wrappers rather than calling `term_*` directly — calling the
  Vim builtins will break Neovim.

- **Buffer-scoped terminals.** Each source buffer is associated with its
  own R terminal via `s:GetBufferTerminal()` / `s:GetTerminalName()`. Do
  not assume a single global R terminal. Code submission always resolves
  the terminal for the current buffer.

- **Three terminal-launch variants.** `<LocalLeader>r` enters a Docker
  container via `make r` when inside a zzcollab project (detected by
  `s:IsZzCollabProject` / `s:IsInsideZzcollab`); `<LocalLeader>rr` starts
  host R with renv; `<LocalLeader>rh` starts vanilla host R. Project-root
  detection (`s:GetProjectRoot`) drives auto-`lcd` behavior.

- **R communication protocol.** Non-trivial commands are written to a
  temp file and `source()`-d from R rather than pasted line-by-line.
  Follow this pattern for new features that need multi-line R or
  `capture.output()` — it is more reliable than terminal injection.

- **Plot pipeline.** R writes `PDF (master) + PNG (preview)` into
  `.plots/` plus a signal file. A Vim timer (`s:StartPlotWatcher` /
  `s:CheckForNewPlot`) polls the signal file's mtime and triggers
  `s:DisplayPlot` → `s:DisplayPlotInline` (Kitty protocol) or
  `s:DisplayPlotITerm2` (imgcat). Plot history lives in a history dir
  (`s:GetHistoryDir`). **Path gotcha:** HUD functions must NOT call
  `s:GetPlotsDir()` / `s:GetHistoryDir()` at use time because those
  depend on `getcwd()`, which may have moved. Capture paths when the HUD
  buffer is created and stash them as buffer-local `b:plots_dir` /
  `b:history_dir`; HUD callbacks read those.

- **HUD system.** Multiple panels (Memory, Data Frames, Packages, Plots,
  …) built on scratch buffers with buffer-local mappings.
  `:RHUDDashboard` composes them into tabs. The Plots tab is special-cased
  and excluded from the generic HUD Enter-key binding.

- **Object browser (`<LocalLeader>"`).** vim-peekaboo style right-side
  split. Numbered list; `1`–`9` inspect quickly, `<CR>` inspects at
  cursor, `<Esc>` returns to list, `q` closes. Implemented as scratch
  buffer with buffer-local mappings — follow this pattern for new tool
  windows.

- **Template version check.** On opening an R file, the plugin compares
  the local `.Rprofile.local` version string against `s:template_version`
  in `autoload/zzvimr/terminal_graphics.vim` and prompts on mismatch.
  When changing the template meaningfully, bump that integer.

## Common commands

```bash
# Regenerate help tags after editing doc/zzvim-R.txt
vim -c 'helptags doc/' -c 'quit'

# Smoke-load the plugin headlessly
vim -Nu NONE -c 'source plugin/zzvim-R.vim' -c 'qa!'

# Run an ad-hoc harness from test_files/ (manual, not CI)
vim -Nu NONE -S test_files/<file>.vim
```

The `Makefile` `test` target points at a Vader file that is not in the
repo; ignore it unless/until a real test suite lands.

## Conventions specific to this repo

- Configuration reads use `get(g:, 'zzvim_r_<name>', <default>)` — keep
  that pattern and document new options in the header comment block of
  `plugin/zzvim-R.vim` and in `doc/zzvim-R.txt`.
- Mapping prefixes are carved up by domain to avoid single-/multi-letter
  collisions: `x` = package mgmt, `z` = data I/O, `v` = working dir,
  `u` = help. `h`, `s`, `d`, `p` are reserved for single-letter object
  inspection (`head`, `str`, `dim`, `print`). When adding mappings, do
  not introduce a multi-letter mapping whose first letter shadows one of
  those single-letter ones.
- Search calls should use explicit flags (`bW`, `bcnW`, `W`) and always
  save/restore cursor position on failure — see `s:MovePrevChunk` for
  the canonical example. Prefer `cursor()` over `setpos()` for simple
  line/column moves.
- `CHANGELOG.md` is the home for version narratives. Do not accumulate
  version-by-version history in this file.
