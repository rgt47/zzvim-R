# zzvim-R 1.0 Release Plan

Living document. Tracks the phased path from the current `main` to a
credible, publishable `v1.0.0` tag. Revised twice:

- After a community-idioms survey (Apr 2026) — see 'Why these phases'
  at the bottom.
- After a risk review of the refactor-before-tests ordering — see
  'Revised ordering rationale' below. Tests now precede refactor.

## Status at a glance

| Phase | Description                                  | Effort    | Status       |
|-------|----------------------------------------------|-----------|--------------|
| 1     | Repo hygiene                                 | done      | Done         |
| 1.5   | Restore CI smoke tests                       | done      | Done         |
| 2     | Version reconciliation                       | 1 h       | Not started  |
| 3     | Tests as a 1.0 release gate                  | 2 d       | Not started  |
| 4     | Minimum autoload extraction                  | ½ d       | Not started  |
| 5     | Metadata and CI polish                       | ½ d       | Not started  |
| 6     | Documentation polish                         | 1 d       | Not started  |
| 7     | Release mechanics                            | 1 h       | Not started  |
| 8     | Announcement                                 | ½ d + ongoing | Not started |

Total remaining effort: ~4.5–5.5 working days of focused time.

**Deferred to 1.1 (was Phase 3 in prior revision):** full domain
split of autoload into `send.vim` / `chunk.vim` / `plot.vim` /
`hud.vim`, `ftplugin/{r,rmd,quarto}.vim` extraction,
`after/ftplugin/r.vim` overrides, `:checkhealth` support,
`compiler/r.vim`. These are good ideas but not 1.0-blocking once
Phase 4 reduces startup cost.

---

## Revised ordering rationale

Earlier revisions placed the structural refactor (Phase 3) *before*
the test suite (Phase 4). That ordering asked an untested 3800-line
codebase to survive a 2–3 day refactor, with no mechanical way to
catch regressions. Observation-before-modification is the safer
sequence.

Revised order:

1. Write tests against the *current* monolithic structure. This is
   purely additive — behavior does not change, only gains coverage.
2. Do a narrow structural change (move bulk of `plugin/` into
   `autoload/zzvim_r.vim`) with the test suite as safety net.
3. Leave the domain split, `ftplugin/` extraction, and
   `:checkhealth` for 1.1. The 'monolithic `plugin/`' critique
   the research agent flagged is satisfied by Phase 4's minimum
   extraction; the rest is polish that is genuinely safer after
   real user bug reports identify unstable areas.

---

## Phase 1 — Repo hygiene (done)

Commits on `main`:

- `e70f24f` Remove tracked backups, build artifacts, rendered READMEs
- `3aa0599` Archive non-standard root docs and scratch files
- `39b2b53` Archive `test_files/` scratch suite (90 files)
- `7d3581b` Restore CI smoke tests at `test/ci_smoke.vim`
- `7677e75` Add docs/RELEASE_PLAN.md

Results:

- Tracked files: 172 → 43
- Root entries: 40+ → 13, all standard plugin layout
- Archive at `../archive/cleanup-2026-04-13/` for v1.1 triage
- CI workflow path updated; smoke script verified locally (exit 0)

---

## Phase 2 — Version reconciliation (1 hour)

The plugin header says `Version: 1.0`; `CHANGELOG.md` says
`[1.0.0] - 2025-12-03`; archived notes referenced `v2.3`. Pick one
source of truth.

Actions:

- Target version: `1.0.0`. Correct the CHANGELOG date at tag time.
- Plugin header: `Version: 1.0.0`, `Last Change: YYYY-MM-DD`.
- Add `g:zzvim_r_version = '1.0.0'` as the single canonical
  constant. Extend `test/ci_smoke.vim` to assert it matches the
  header via regex.
- Update `doc/zzvim-R.txt` version header.
- README install block: replace any `yourusername` placeholder
  with `rgt47`.
- Same replacement in `.github/workflows/release.yml`.

Exit criteria:
`rg -i 'version|yourusername' plugin/ doc/ CHANGELOG.md README.md .github/`
shows one canonical version and no placeholders.

---

## Phase 3 — Tests as a 1.0 release gate (2 days)

Tests first, against the current monolithic structure. Purely
additive. No `s:` function is renamed or moved; Phase 3 only *reads*
the plugin.

### What CI already does (keep)

Syntax load × (Vim, Neovim) × (Ubuntu, macOS); `helptags` smoke;
`vint` lint; existence assertions in `test/ci_smoke.vim`.

### 3a. Expand smoke tier (2–3 h)

- Assert every public `:R*` Ex command exists (currently 5 of 40+).
- Assert every mapping declared in README exists when a buffer
  with `filetype=r` is loaded.
- Assert help tags cover every `*zzvim-R-*` anchor referenced from
  README.

### 3b. Functional tier (8–12 h, load-bearing)

Framework: `vim-themis`. Runs on Vim and Neovim; no compilation.
Specs live at `test/functional/`.

Script-local access via a thin test-only wrapper module,
`autoload/zzvim_r/testing.vim`, loaded only when
`g:zzvim_r_testing` is set. The wrapper delegates to the `s:`
functions in `plugin/zzvim-R.vim` via `<SID>` resolution exposed
through a `zzvim_r#testing#expose()` helper.

Recommendation: wrapper module (cleaner than raw `<SNR>`-lookup in
each spec; open for override).

Priority order:

| Priority | Function                                               | Rationale                                  |
|----------|--------------------------------------------------------|--------------------------------------------|
| P0       | `GetCodeBlock`, `IsBlockStart`                         | Core of `<CR>` submission                  |
| P0       | `MoveNextChunk`, `MovePrevChunk`                       | Previously regressed; historically fragile |
| P0       | `IsIncompleteStatement`, `EndsWithInfixOperator`       | Silent wrong behavior on pipe chains       |
| P1       | `CompareSemver`, `GetRprofileVersion`                  | Template-version prompt accuracy           |
| P1       | `IsInsideFunction`, `IsInsideZzcollab`, `GetProjectRoot` | Terminal-launch routing                 |
| P2       | `GetTextByType`                                        | Secondary extraction path                  |

Each spec: fixture buffer (`.R` or `.Rmd`), call via wrapper,
assert return value, cursor position, lack of side effects.

### 3c. Wire themis into CI (2 h)

New `functional` job in `test.yml`. Install themis via `git clone`,
cache the checkout. Fail matrix on any spec failure.

Switch the Vim/Neovim install steps to
[`rhysd/action-setup-vim`](https://github.com/rhysd/action-setup-vim) —
pins versions, works on Ubuntu/macOS/Windows, faster and more
reliable than the current apt/brew approach.

### 3d. Expand CI matrix (1 h)

Add Windows (the current matrix is Linux + macOS only). Add
`nightly` to catch Vim/Neovim breaking changes early. Final matrix:

```yaml
os: [ubuntu-latest, macos-latest, windows-latest]
vim:    [v9.0.0000, v9.1.0000, nightly]
nvim:   [v0.9.5, v0.10.4, v0.11.0, nightly]
```

Mark nightly as `continue-on-error: true` so upstream breakage
does not red-CI a legitimate PR.

### 3e. Release gate policy

No `v1.0.0` tag until:

- All non-nightly CI jobs green
- Functional suite has ≥1 positive and ≥1 edge-case test for every
  P0 function
- `test/COVERAGE.md` committed, manually mapping function → spec

### Out of scope for 1.0

- Terminal integration tests (require real R + interactive pty)
- Plot-watcher timer tests (side-effectful, filesystem-dependent)
- Property-based testing (defer to 1.1 if regressions recur)

---

## Phase 4 — Minimum autoload extraction (½ day)

With the Phase 3 test suite in place, do the smallest refactor
that addresses the monolithic-`plugin/` critique: move the bulk of
`plugin/zzvim-R.vim` into a single `autoload/zzvim_r.vim` so
startup cost drops to near zero.

Scope:

- `plugin/zzvim-R.vim` retains: load guard, `g:zzvim_r_version`,
  `:command!` registrations (thin `zzvim_r#foo()` calls), default
  mapping block. Target size: a few hundred lines.
- `autoload/zzvim_r.vim` receives the logic. Rename `s:Foo` →
  `zzvim_r#foo` as each moves.
- Internal `s:` helpers that are only called from one location may
  stay `s:` inside the autoload file; no need to make them public.
- Resolve the naming inconsistency with
  `autoload/zzvimr/terminal_graphics.vim` by renaming the
  directory and function prefix to `zzvim_r#` (Google VimScript
  style convention).
- Run the test suite after each logical chunk of functions moves.
  A red spec identifies exactly which function broke.
- `autoload/zzvim_r/testing.vim` from Phase 3 updates to point at
  the new locations.

Not in scope (deferred to 1.1):

- Domain sub-split (`send.vim`, `chunk.vim`, `plot.vim`, etc.)
- `ftplugin/{r,rmd,quarto}.vim` extraction
- `after/ftplugin/r.vim` override layer
- `lua/zzvim_r/health.lua` + `autoload/health/zzvim_r.vim`
  (`:checkhealth` support)
- `compiler/r.vim`

Rationale for the narrower scope:

- The startup-cost critique is satisfied by moving logic *out* of
  `plugin/`; a single-file `autoload/zzvim_r.vim` is common (see
  tpope/vim-fugitive with its 11k-line `autoload/fugitive.vim`).
- `ftplugin/` and `:checkhealth` are idiomatic polish, not
  correctness issues. They are better informed by real bug
  reports post-1.0.
- Every additional extraction multiplies refactor risk. Keeping
  Phase 4 to half a day keeps risk bounded.

Exit criteria:

- `plugin/zzvim-R.vim` is ≤ ~500 lines.
- `vim --startuptime` on a sample `.R` file drops materially.
- Phase 3 test suite is all green.

---

## Phase 5 — Metadata and CI polish (½ day)

Low-effort items that collectively mark a plugin as maintained.

- `.editorconfig` — 2-space indent, LF line endings, trim
  trailing whitespace. Per Google VimScript style guide.
- `.vintrc.yaml` — vint config. See
  [ale/.vintrc.yaml](https://github.com/dense-analysis/ale/blob/master/.vintrc.yaml).
- `.github/dependabot.yml` — weekly bumps for Actions versions.
- `.github/ISSUE_TEMPLATE/bug_report.yml` — YAML *form*, not
  Markdown template. Fields: Vim/Neovim version (`:version`), OS,
  R version, minimal reproducer, `:checkhealth` output (once 1.1
  adds it; for 1.0 ask for `:version` and `:messages`).
- `.github/ISSUE_TEMPLATE/feature_request.yml`.
- `.github/ISSUE_TEMPLATE/config.yml` — disable blank issues,
  link Discussions.
- `.github/PULL_REQUEST_TEMPLATE.md` — checklist: tests added,
  help updated, CHANGELOG entry.
- `SECURITY.md` — one paragraph: this plugin evaluates R code; do
  not run `.Rmd` files from untrusted sources.
- `CODE_OF_CONDUCT.md` — Contributor Covenant v2.1. Optional but
  expected at this scale.
- GitHub repo topics (set via Settings, not committed):
  `vim-plugin`, `neovim-plugin`, `vim`, `neovim`, `r`, `rstats`,
  `r-language`, `rmarkdown`, `quarto`, `data-science`, `vimscript`.

Deferred to 1.1: Conventional Commits + `release-please` for
automated tagging/changelog.

---

## Phase 6 — Documentation polish (1 day)

### 6a. Help file (`doc/zzvim-R.txt`)

Restructure to canonical section order:

```
*zzvim-R.txt*   One-line description    *zzvim-R*

CONTENTS                                *zzvim-R-contents*
INTRODUCTION                            *zzvim-R-introduction*
REQUIREMENTS                            *zzvim-R-requirements*
INSTALLATION                            *zzvim-R-installation*
USAGE                                   *zzvim-R-usage*
COMMANDS                                *zzvim-R-commands*
MAPPINGS                                *zzvim-R-mappings*
CONFIGURATION                           *zzvim-R-configuration*
FAQ                                     *zzvim-R-faq*
CONTRIBUTING                            *zzvim-R-contributing*
CHANGELOG                               *zzvim-R-changelog*
LICENSE                                 *zzvim-R-license*

 vim:tw=78:ts=8:ft=help:norl:
```

Modeline at bottom is mandatory — without it, `:help` will not
syntax-highlight the file. Verify current help already has it.

Per-command tags: `*:RSendLine*`, `*g:zzvim_r_chunk_start*` (exact
user-typed token).

Reconcile: every mapping and command in README appears in help,
and every `:R*` command in `plugin/` is documented.

### 6b. README

- Badges at top: CI status, license, latest release tag.
- Lead section: 30-second install + 'press `<CR>`' demo.
- Install blocks in order of 2026 usage:
  1. lazy.nvim (dominant Neovim)
  2. vim-plug (dominant classic Vim)
  3. mini.deps (rising)
  4. Native `:packadd`
  Collapse dein/pathogen/Vundle into a `<details>` section.
- Screenshots or GIFs. Use [`vhs`](https://github.com/charmbracelet/vhs)
  and commit the `.tape` source — reproducible, diffable. Start
  with one GIF: open an `.Rmd`, press `<CR>` on a chunk, see
  output in the R terminal.
- 'Similar projects' section — honest comparison:
  - [R.nvim](https://github.com/R-nvim/R.nvim) — Neovim-only, Lua,
    successor to Nvim-R (archived 2023). Heavier.
  - ESS (Emacs) — different ecosystem.
  - vim-slime — generic, not R-aware.
  Position zzvim-R as: dual Vim/Neovim, VimScript, lighter
  weight. Do not disparage; communities overlap.
- Features list: prune to ~7 bullets; push the rest to
  `:help zzvim-R`.
- Replace any `yourusername/zzvim-R` with `rgt47/zzvim-R`.

### 6c. `CONTRIBUTING.md`

State: test command (`make test` → themis invocation), CI
expectations, style (vint clean, 2-space indent), DCO/sign-off
policy (optional).

---

## Phase 7 — Release mechanics (1 hour)

Pre-flight:

- `vim -Nu NONE -S plugin/zzvim-R.vim` — no errors.
- Open an `.Rmd` file in fresh session — no errors.
- All non-nightly CI jobs green on `main`.
- `CHANGELOG.md` date set to actual release day.
- Regenerate helptags: `vim -c 'helptags doc/' -c 'qa!'`.
  Do not commit `doc/tags`; add to `.gitignore` if not already.

Release workflow fixes (`.github/workflows/release.yml`):

- Replace `yourusername/zzvim-R` with `rgt47/zzvim-R`.
- Bump `softprops/action-gh-release@v1` → `@v2`.
- Pull release body from the matching `CHANGELOG.md` section
  (awk/sed extraction) rather than hardcoded text.

Tag and push:

```
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

Release workflow fires automatically on `v*` tag.

Post-tag:

- Verify the GitHub Release renders correctly.
- Set GitHub repo topics (Phase 5 list).
- Wait 1 week for bug reports before announcing widely (Phase 8).

---

## Phase 8 — Announcement (½ day + ongoing)

Sequence matters. Higher-effort, higher-reach channels first;
wait on community lists until after a quiet week proves stability.

### 8a. Launch blog post (2–3 h)

Single highest-ROI action. Personal blog or dev.to. Cover:

- The problem zzvim-R solves
- Design choices (multi-terminal, `<CR>` smart submission, plot
  pipeline, HUD)
- Honest comparison with R.nvim and ESS
- Install and quickstart
- 60-second GIF (the one from README)

Register the blog RSS feed with
[r-bloggers.com](https://www.r-bloggers.com/add-your-blog/) — it
syndicates R-tagged posts and is where most R users discover
tooling. Approval takes ~1 week.

### 8b. Direct announcements (day of release + blog)

- **r/neovim** — post with flair 'Plugin'. Link blog post;
  include GIF and one-sentence pitch.
- **r/rstats** — separate post; lead with R angle, not Vim.
- **[This Week in Neovim](https://this-week-in-neovim.org/)** — PR
  to [contents repo](https://github.com/phaazon/this-week-in-neovim-contents)
  in the release week.
- **rstats Mastodon** — post with `#rstats` tag on fosstodon.org.
- **vim_use mailing list** — plain-text, short, Vim-focused.
- **Matrix `#neovim:matrix.org`** — casual share after reddit
  post lands.

Etiquette: one post per channel per major release. No reposting.
Hacker News only for genuinely novel technical content.

### 8c. Discoverability lists (2+ weeks after release)

Wait until some organic traffic/stars accumulate; list maintainers
reject too-early submissions.

- [awesome-neovim](https://github.com/rockerBOO/awesome-neovim) PR.
  Alphabetical within category. One-line description. Soft rule:
  ≥ ~10 stars and a GIF in README.
- [awesome-vim](https://github.com/akrawchyk/awesome-vim) — less
  actively curated, try anyway.
- vim-awesome.com — autoscrapes from GitHub once the repo has
  `vim-plugin` topic set. No submission needed.

### 8d. Post-release hygiene (ongoing)

- Acknowledge issues within ~1 week.
- PR response target: 2 weeks.
- Label issues: `bug`, `enhancement`, `help wanted`,
  `good first issue`.
- Avoid `actions/stale` — auto-closing is polarizing.
- If slowing down: README banner, invite co-maintainers via
  Discussions, archive as last resort.

---

## Deferred to 1.1

Grouped by area. All are genuinely valuable; none are
1.0-blocking with the revised ordering.

**Structural.** Domain sub-split of `autoload/zzvim_r.vim` into
`send.vim` / `chunk.vim` / `plot.vim` / `hud.vim` /
`inspect.vim`. `ftplugin/{r,rmd,quarto}.vim` extraction with
`b:undo_ftplugin`. `after/ftplugin/r.vim` to override Vim's
bundled `r.vim`. `compiler/r.vim` for `:compiler r` quickfix
integration.

**Neovim ecosystem.** `:checkhealth zzvim_r` support via
`lua/zzvim_r/health.lua` and `autoload/health/zzvim_r.vim`.

**Automation.** Conventional Commits + `release-please` for
automated tagging/changelog.

**Documentation.** Triage of `../archive/cleanup-2026-04-13/` —
decide which companion docs (Docker, png1, zzcollab workflows)
return and where.

**Testing.** Property-based tests on submission logic if
block-detection regressions recur. Terminal integration tests
under `nvim --headless` with a real R process.

**Long term.** Lua port for pure-Neovim users (low priority;
dual-support is the 1.0 positioning).

---

## Open questions

1. **Phase 3b wrapper approach.** Confirmation that
   `autoload/zzvim_r/testing.vim` re-export is preferred over raw
   `<SNR>`-lookup. Recommended; pending sign-off.

2. **Phase 4 naming convention.** Settle on `zzvim_r#` and rename
   `autoload/zzvimr/terminal_graphics.vim` accordingly. Breaking
   change for anyone who imported the old name externally, but
   acceptable pre-1.0.

3. **`docs/` curation.** ~20 design notes and comparisons. Keep,
   prune, or migrate to GitHub wiki? Not a 1.0 blocker; revisit
   during Phase 6.

---

## Why these phases (research note)

A web survey of modern plugin idioms (r/neovim, awesome-neovim,
reference repos: vim-go, fzf.vim, lazy.nvim, ale, R.nvim,
mini.nvim) surfaced gaps not in the initial plan:

- **Structural.** Monolithic `plugin/` is the loudest first-plugin
  tell; the 1.0 target here is only to move logic *out of*
  `plugin/`, not the full domain split (deferred to 1.1 per the
  risk review above).
- **Metadata.** YAML issue forms replaced Markdown templates ~2023.
  Dependabot and `.editorconfig` are minor but universal.
- **CI.** `rhysd/action-setup-vim` is the de facto Vim/Neovim
  installer. Windows is part of the standard matrix now.
- **Docs.** `vhs` tapes replaced terminalizer/LICEcap for
  reproducible GIFs. lazy.nvim's install snippet comes first.
- **Ecosystem.** Nvim-R was archived in 2023; R.nvim is the
  successor. Position honestly against R.nvim, not the dead one.
- **Announcement.** r-bloggers syndication via a blog post
  outperforms direct r/neovim posts for an R-specific plugin.
  This Week in Neovim is the highest-quality Neovim user channel.
