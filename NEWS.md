# zzvim-R (development)

## 2026-10-20

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
