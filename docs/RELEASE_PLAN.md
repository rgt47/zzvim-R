# zzvim-R 1.0 Release Plan

Living document. Tracks the phased path from the current `main` to a
credible, publishable `v1.0.0` tag. Revised after a community-idioms
survey (Apr 2026) — see 'Why these phases' at the bottom for what
research surfaced that the initial plan missed.

## Status at a glance

| Phase | Description                                  | Effort    | Status       |
|-------|----------------------------------------------|-----------|--------------|
| 1     | Repo hygiene                                 | done      | Done         |
| 1.5   | Restore CI smoke tests                       | done      | Done         |
| 2     | Version reconciliation                       | 1 h       | Not started  |
| 3     | Structural modernization                     | 2–3 d     | Not started  |
| 4     | Tests as a 1.0 release gate                  | 2 d       | Not started  |
| 5     | Metadata and CI polish                       | ½ d       | Not started  |
| 6     | Documentation polish                         | 1 d       | Not started  |
| 7     | Release mechanics                            | 1 h       | Not started  |
| 8     | Announcement                                 | ½ d + ongoing | Not started |

Total remaining effort: ~6–8 working days of focused time, spread
over whatever calendar fits.

---

## Phase 1 — Repo hygiene (done)

Commits on `main`:

- `e70f24f` Remove tracked backups, build artifacts, rendered READMEs
- `3aa0599` Archive non-standard root docs and scratch files
- `39b2b53` Archive `test_files/` scratch suite (90 files)
- `7d3581b` Restore CI smoke tests at `test/ci_smoke.vim`

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
- README install block: replace any `yourusername` placeholder with
  `rgt47`.
- Same replacement in `.github/workflows/release.yml`.

Exit criteria:
`rg -i 'version|yourusername' plugin/ doc/ CHANGELOG.md README.md .github/`
shows one canonical version and no placeholders.

---

## Phase 3 — Structural modernization (2–3 days)

A 3800-line single-file `plugin/` is the most-cited first-plugin
tell. Reviewers on r/neovim and awesome-neovim notice. This phase
aligns the layout with standard Vim plugin conventions documented
at `:help write-plugin` and `:help ftplugin`.

### 3a. Extract to `autoload/` (1–1.5 d)

Rationale: `plugin/` is sourced unconditionally at Vim startup;
`autoload/` loads functions only on first reference. Moving logic
to `autoload/` lowers every user's `vim --startuptime` cost.

- Keep in `plugin/zzvim-R.vim`: guard (`g:loaded_zzvim_r`), version
  constant, `:command!` registrations (thin wrappers calling
  `zzvim_r#foo()`), default-mapping block.
- Move to `autoload/zzvim_r.vim` (or split by domain):
  `autoload/zzvim_r/terminal.vim`, `autoload/zzvim_r/plot.vim`,
  `autoload/zzvim_r/hud.vim`, `autoload/zzvim_r/chunk.vim`,
  `autoload/zzvim_r/inspect.vim`, `autoload/zzvim_r/send.vim`.
- Rename `s:Foo` → `zzvim_r#domain#foo` as functions move; keep a
  thin `s:` wrapper where needed for internal helpers that stay
  within one autoload file.
- Existing `autoload/zzvimr/terminal_graphics.vim` uses `zzvimr#`
  (no underscore). Decide on one naming convention — `zzvim_r#` is
  more conventional (Google VimScript style) — and rename for
  consistency. Note: this is a breaking change for anyone using the
  function externally, but pre-1.0 that's fine.

### 3b. Filetype plugins (½ d)

Rationale: `<LocalLeader>` mappings and R-specific `setlocal`
options belong in `ftplugin/`, not `plugin/`. Makes the plugin
inert for non-R buffers without needing internal filetype guards.

- `ftplugin/r.vim`, `ftplugin/rmd.vim`, `ftplugin/quarto.vim` —
  buffer-local mappings. Set `b:undo_ftplugin` so `:setfiletype`
  cleans up correctly.
- `after/ftplugin/r.vim` — overrides for Vim's bundled `r.vim`
  ftplugin, which otherwise clobbers some buffer-local settings.
  This is the specific R-plugin gotcha the initial plan missed.
- Remove filetype guards from `plugin/zzvim-R.vim` where they
  become redundant.

### 3c. `:checkhealth` support (½ d)

Lets users run `:checkhealth zzvim_r` for diagnosis, which is the
single best first-line support tool for a plugin with many
moving parts (R, terminal, plots, Docker, zzcollab detection).

- `lua/zzvim_r/health.lua` exposing `M.check()` for Neovim ≥ 0.9.
- `autoload/health/zzvim_r.vim` with `health#zzvim_r#check()` for
  classic Vim and as Neovim VimScript fallback.
- Checks: `R` on `$PATH`; R version ≥ 4.0; `has('terminal')`;
  optional pandoc / quarto; `.Rprofile.local` template version vs.
  `s:template_version`; writable temp dir.

### Defer to 1.1 (explicit)

- `compiler/r.vim` defining `:compiler r` with `&makeprg` and
  `&errorformat` for `R CMD check` / `devtools::check()` quickfix
  integration. Genuinely useful but not shipping-critical.
- Syntax additions beyond Vim's default `r.vim`.

---

## Phase 4 — Tests as a 1.0 release gate (2 days)

### What CI already does (keep)

Syntax load × (Vim, Neovim) × (Ubuntu, macOS); `helptags` smoke;
`vint` lint; existence assertions in `test/ci_smoke.vim`.

### 4a. Expand smoke tier (2–3 h)

- Assert every public `:R*` Ex command exists (currently 5 of 40+).
- Assert every mapping declared in README exists when a buffer
  with `filetype=r` is loaded.
- Assert help tags cover every `*zzvim-R-*` anchor referenced
  from README.

### 4b. Functional tier (8–12 h, load-bearing)

Framework: `vim-themis`. Runs on Vim and Neovim, no compilation.
Specs live at `test/functional/`.

Script-local access via a thin test-only wrapper module,
`autoload/zzvim_r/testing.vim`, loaded only when
`g:zzvim_r_testing` is set. Cleaner than `<SNR>` resolution.

Priority order:

| Priority | Function                                               | Rationale                                  |
|----------|--------------------------------------------------------|--------------------------------------------|
| P0       | `GetCodeBlock`, `IsBlockStart`                         | Core of `<CR>` submission                  |
| P0       | `MoveNextChunk`, `MovePrevChunk`                       | Previously regressed; historically fragile |
| P0       | `IsIncompleteStatement`, `EndsWithInfixOperator`       | Silent wrong behavior on pipe chains       |
| P1       | `CompareSemver`, `GetRprofileVersion`                  | Template-version prompt accuracy           |
| P1       | `IsInsideFunction`, `IsInsideZzcollab`, `GetProjectRoot` | Terminal-launch routing                 |
| P2       | `GetTextByType`                                        | Secondary extraction path                  |

Each spec: fixture buffer, call via wrapper, assert return value,
cursor position, lack of side effects.

### 4c. Wire themis into CI (2 h)

New `functional` job in `test.yml`. Install themis via `git clone`,
cache the checkout. Fail matrix on any spec failure.

Switch the Vim/Neovim install steps to
[`rhysd/action-setup-vim`](https://github.com/rhysd/action-setup-vim) —
pins versions, works on Ubuntu/macOS/Windows, faster and more
reliable than the current apt/brew approach.

### 4d. Expand CI matrix (1 h)

Add Windows (the current matrix is Linux + macOS only). Add
`nightly` to catch Vim/Neovim breaking changes early. Final matrix:

```yaml
os: [ubuntu-latest, macos-latest, windows-latest]
vim:    [v9.0.0000, v9.1.0000, nightly]
nvim:   [v0.9.5, v0.10.4, v0.11.0, nightly]
```

Mark nightly as `continue-on-error: true` so upstream breakage
doesn't red-CI a legitimate PR.

### 4e. Release gate policy

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

## Phase 5 — Metadata and CI polish (½ day)

Low-effort items that collectively mark a plugin as maintained.

- `.editorconfig` — 2-space indent, LF line endings, trim
  trailing whitespace. Per Google VimScript style guide.
- `.vintrc.yaml` — vint config. See
  [ale/.vintrc.yaml](https://github.com/dense-analysis/ale/blob/master/.vintrc.yaml)
  as reference.
- `.github/dependabot.yml` — weekly bumps for Actions versions.
- `.github/ISSUE_TEMPLATE/bug_report.yml` — YAML *form*, not
  Markdown template. Fields: Vim/Neovim version (`:version`), OS,
  R version, minimal reproducer, `:checkhealth zzvim_r` output.
- `.github/ISSUE_TEMPLATE/feature_request.yml`.
- `.github/ISSUE_TEMPLATE/config.yml` — disable blank issues, link
  Discussions.
- `.github/PULL_REQUEST_TEMPLATE.md` — checklist: tests added,
  help updated, CHANGELOG entry.
- `SECURITY.md` — one paragraph: this plugin evaluates R code; do
  not run `.Rmd` files from untrusted sources. Don't overthink.
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

Modeline at bottom is mandatory — without it, `:help` won't
syntax-highlight the file. Current help file may already have it;
verify.

Per-command tags: `*:RSendLine*`, `*g:zzvim_r_chunk_start*`
(exact user-typed token).

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
  with one GIF: open an .Rmd, press `<CR>` on a chunk, see
  output in the R terminal.
- 'Similar projects' section — honest comparison:
  - [R.nvim](https://github.com/R-nvim/R.nvim) — Neovim-only, Lua,
    successor to Nvim-R (which was archived in 2023). Heavier.
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
- Wait 1 week for bug reports before announcing widely (see
  Phase 8).

---

## Phase 8 — Announcement (½ day + ongoing)

Sequence matters. Higher-effort, higher-reach channels first;
wait on community lists until after a quiet week proves stability.

### 8a. Launch blog post (2–3 h)

Single highest-ROI action. Personal blog or dev.to. Cover:

- The problem zzvim-R solves
- Design choices (multi-terminal, `<CR>` smart submission,
  plot pipeline, HUD)
- Honest comparison with R.nvim and ESS
- Install and quickstart
- 60-second GIF (the one from README)

Register the blog's RSS feed with
[r-bloggers.com](https://www.r-bloggers.com/add-your-blog/) — it
syndicates R-tagged posts and is where most R users discover
tooling. Approval takes ~1 week.

### 8b. Direct announcements (day of release + blog)

- **r/neovim** — post with flair 'Plugin'. Link the blog post;
  include GIF and one-sentence pitch.
- **r/rstats** — separate post; lead with R angle, not Vim.
- **[This Week in Neovim](https://this-week-in-neovim.org/)** — PR
  to [contents repo](https://github.com/phaazon/this-week-in-neovim-contents)
  in the release week. High-quality Neovim user audience.
- **rstats Mastodon** — post with `#rstats` tag on fosstodon.org.
- **vim_use mailing list** — plain-text, short, Vim-focused pitch.
- **Matrix `#neovim:matrix.org`** — casual share after the reddit
  post lands.

Etiquette: one post per channel per major release. No reposting.
Do not cross-post to Hacker News unless there's genuinely novel
technical content (a plot pipeline for terminal Vim arguably
qualifies, but decide case by case).

### 8c. Discoverability lists (2+ weeks after release)

Wait until some organic traffic/stars accumulate; list maintainers
reject too-early submissions.

- [awesome-neovim](https://github.com/rockerBOO/awesome-neovim) PR.
  Read `CONTRIBUTING.md`. Alphabetical within category. One-line
  description. Soft rule: ≥ ~10 stars and a GIF in README.
- [awesome-vim](https://github.com/akrawchyk/awesome-vim) — less
  actively curated, but try.
- vim-awesome.com — autoscrapes from GitHub once the repo has
  `vim-plugin` topic set. No submission needed.

### 8d. Post-release hygiene (ongoing)

- Acknowledge issues within ~1 week, even if only 'thanks, will
  investigate.' Silence >1 month reads as abandonment.
- PR response target: 2 weeks.
- Label issues: `bug`, `enhancement`, `help wanted`,
  `good first issue`.
- Avoid `actions/stale` — auto-closing issues is polarizing.
- If/when slowing down: README banner ('maintenance mode'),
  invite co-maintainers via Discussions, archive as last resort.

---

## Deferred to 1.1

- Further split of large autoload files if any single one exceeds
  ~800 lines after Phase 3.
- `compiler/r.vim` for `:compiler r` quickfix integration.
- Custom `syntax/` additions beyond Vim defaults.
- Conventional Commits + `release-please` automation.
- Triage `../archive/cleanup-2026-04-13/` — decide which companion
  docs (Docker, png1, zzcollab workflows) return and where.
- Property-based tests on submission logic if block-detection
  regressions recur.
- Lua port for pure-Neovim users (low priority given dual-support
  is the positioning).

---

## Open questions

1. **Phase 3 scope.** The structural refactor is 2–3 days and
   touches every function. Doing it before 1.0 is correct per
   community idioms but materially delays release. Alternative:
   tag a `v0.9.0` pre-release with current structure, refactor in
   public, tag `v1.0.0` after. **Recommendation: do the refactor
   pre-1.0.** A monolithic `plugin/` at 1.0 invites PRs that are
   hard to review and signals inexperience to awesome-neovim
   reviewers.

2. **Phase 4b wrapper approach.** `autoload/zzvim_r/testing.vim`
   re-export vs. `<SNR>` resolution. **Recommendation: wrapper.**
   Unresolved pending sign-off.

3. **Naming convention.** Current code mixes `zzvimr#` (in
   `autoload/zzvimr/terminal_graphics.vim`) and `s:` prefixes.
   Phase 3 should settle on `zzvim_r#` per Google VimScript style.
   Pre-1.0 breakage is acceptable.

4. **`docs/` curation.** ~20 design notes and comparisons. Keep,
   prune, or migrate to GitHub wiki? Not a 1.0 blocker; revisit
   during Phase 6.

---

## Why these phases (research note)

A web survey of modern plugin idioms (r/neovim, awesome-neovim,
reference repos: vim-go, fzf.vim, lazy.nvim, ale, R.nvim,
mini.nvim) surfaced gaps not in the initial plan:

- **Structural.** Monolithic `plugin/` is the loudest first-plugin
  tell; `autoload/` + `ftplugin/` + `after/ftplugin/` is standard.
  `:checkhealth` support is expected for Neovim plugins of any
  complexity.
- **Metadata.** YAML issue forms replaced Markdown templates circa
  2023. Dependabot and `.editorconfig` are minor but universal.
- **CI.** `rhysd/action-setup-vim` is the de facto Vim/Neovim
  installer. Windows is part of the standard matrix now.
- **Docs.** `vhs` tapes replaced terminalizer/LICEcap for
  reproducible GIFs. lazy.nvim is dominant enough that its install
  snippet comes first.
- **Ecosystem.** Nvim-R was archived in 2023; R.nvim (Lua,
  Neovim-only) is the successor. Position honestly against R.nvim,
  not against the dead Nvim-R.
- **Announcement.** r-bloggers syndication via a blog post
  outperforms direct r/neovim posts for an R-specific plugin.
  This Week in Neovim is the highest-quality Neovim user channel.
