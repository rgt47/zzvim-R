# zzvim-R (development)

## 2026-10-24 (v0.10.2)

* **Breaking: pipe key and pipe operator.** `<LocalLeader>o` (append
  pipe, open new line) was still both a complete command and the
  prefix of the ten `<LocalLeader>o?` object-inspection keys, so it
  waited `timeoutlen` on every use. It moves to `<LocalLeader>|`. It
  now appends the pipe to the end of the current line (tidyverse
  style) instead of putting it alone on the next line, inserts the
  native `|>` by default (new option `g:zzvim_r_pipe`; set it to
  `'%>%'` for magrittr), indents the new line, and enters insert mode.
* **Breaking: `<LocalLeader>0` -> `<LocalLeader>uu` and
  `<LocalLeader>P` -> `<LocalLeader>pp`**, so the dashboard and plot
  HUD sit inside their `u` and `p` groups. `<Plug>` names are
  unchanged.
* **Removed `g:zzvim_r_map_submit`.** It was documented but never
  read. Remap `<Plug>(zzvim-r-send-smart)` to move submission off
  `<CR>`.

## 2026-10-20 (v0.10.1)

* **Breaking: three default keys renamed to avoid mixed case.**
  v0.10.0 briefly used `<LocalLeader>rD` (force a new Docker
  terminal), `<LocalLeader>oS` (`summary()`), and `<LocalLeader>ci`/
  `cI` (insert chunk below/above) -- each combines an upper- and a
  lower-case letter in one key, which forces a shift key mid-sequence
  and is easy to mistype. Renamed to `<LocalLeader>rf`,
  `<LocalLeader>ou`, and `<LocalLeader>nb`/`na`. The `nb`/`na` rename
  also fixed an unrelated defect: `<LocalLeader>c` (Ctrl-C) is a
  complete command active in every one of r/rmd/quarto, so `ci`/`cI`'s
  `c` prefix collided with it in rmd/quarto buffers specifically --
  the same one-key-is-both-a-command-and-a-prefix pattern already
  fixed elsewhere in v0.10.0, just scoped to a filetype subset.
  `<Plug>` target names are unchanged, only the default key bound to
  each. See `:help zzvim-r-mappings-migration`.

## 2026-10-20 (v0.10.0)

* **Breaking: default key mappings regrouped (v0.10.0).** `<LocalLeader>r`
  and `<LocalLeader>s` are now pure prefixes (no key is both a complete
  command and the start of a longer one); object inspection moved under
  a new `o` prefix and HUD windows under a new `u` prefix; plot
  previous/next moved onto `[`/`]`, matching Vim's own bracket-pair
  convention; four exact duplicate mappings (`ZR`, `<LocalLeader>R`,
  `<LocalLeader>sa`, `<LocalLeader>t`) and one near-duplicate
  (`<LocalLeader>y`) were removed. Every action now also has a named
  `<Plug>(zzvim-r-...)` target, bound by default only when the user has
  not already mapped it (the standard `hasmapto()` plugin convention),
  so a single key can be customized without disabling the rest. The
  object-inspection group gained visual-mode counterparts, so
  `<LocalLeader>oh` etc. now work on a visual selection (e.g. `df$x`),
  not just the word under the cursor. Chunk navigation gained
  buffer-local `]]`/`[[` aliases that compose with operators (`d]]`).
  See `:help zzvim-r-mappings-migration` for the full old-key-to-new-key
  table.

## 2026-05-19

* Add `<LocalLeader>rv` mapping for rendering Rmd/Quarto files to PDF
  (`pdf_document`) via `rmarkdown::render()`.
* Add `:RMarkdownRender [{format}]` command (previously undocumented); update
  vim help and README to document all three render bindings (`rk`, `rp`, `rv`).

# zzvim-R v0.9.0

* Initial public release.
