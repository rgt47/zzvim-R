# Test coverage

Living document. Maps functions in `plugin/zzvim-R.vim` to the
specs that cover them. A 1.0 release gate per
`docs/archive/RELEASE_PLAN.md` requires every P0 function to have
at least one positive and one edge-case spec.

Update when adding a new function or spec file.

## Functional tier (vim-themis)

All specs under `test/functional/` are run by `make functional`
against both Vim and Neovim in CI.

| Priority | Function                     | Spec file                      | Specs | Notes                               |
|----------|------------------------------|--------------------------------|-------|-------------------------------------|
| P0       | `s:IsBlockStart`             | `block_detect_spec.vim`        | 9     | 8 positive paths + negatives        |
| P0       | `s:GetCodeBlock`             | `block_detect_spec.vim`        | 8     | pipes, braces, parens, nested       |
| P0       | `s:IsIncompleteStatement`    | `incomplete_stmt_spec.vim`     | 15    | all three branches + negatives      |
| P0       | `s:EndsWithInfixOperator`    | `endswith_infix_spec.vim`      | 9     | pipes, assign, arith, logic, comma  |
| P0       | `s:MoveNextChunk`            | `chunk_nav_spec.vim`           | 5     | incl. boundary at EOF               |
| P0       | `s:MovePrevChunk`            | `chunk_nav_spec.vim`           | 5     | incl. 1 documented bug (see below)  |
| P1       | `s:CompareSemver`            | `semver_spec.vim`              | 5     | pure function; canary for harness   |
| P1       | `s:GetProjectRoot`           | `project_root_spec.vim`        | 4     | temp-dir filesystem fixtures        |
| P1       | `s:IsInsideZzcollab`         | `project_root_spec.vim`        | 2     | delegates to GetProjectRoot         |
| P1       | `s:IsZzCollabProject`        | `project_root_spec.vim`        | 5     | incl. 1 documented bug (see below)  |
|          |                              | **Total**                      | **67** |                                    |

## Smoke tier

`test/ci_smoke.vim` (11 tests): plugin load guard, version
consistency between plugin header and `g:zzvim_r_version`,
Vim/Neovim version floor, five core config variables, every
`:R*` command declared in the plugin source (69 commands at
time of writing), representative `<LocalLeader>` mappings on a
`filetype=r` buffer, and `<CR>` registration.

## P0 release-gate status

| Function                     | Positive | Edge-case | Status |
|------------------------------|----------|-----------|--------|
| `s:IsBlockStart`             | yes      | yes       | ✓      |
| `s:GetCodeBlock`             | yes      | yes       | ✓      |
| `s:IsIncompleteStatement`    | yes      | yes       | ✓      |
| `s:EndsWithInfixOperator`    | yes      | yes       | ✓      |
| `s:MoveNextChunk`            | yes      | yes       | ✓      |
| `s:MovePrevChunk`            | yes      | yes       | ✓      |

All P0 functions gate-met.

## Out of scope for 1.0

- `s:GetTextByType` (P2) — secondary extraction path. Add in 1.1
  if block-detection regressions surface.
- Terminal-integration functions (`s:OpenDockerRTerminal`,
  `s:OpenLocalRTerminal`, etc.) — require real R + interactive
  pty; unreliable in headless CI.
- Plot-watcher functions (`s:CheckForNewPlot`,
  `s:DisplayPlotInline`) — timer-driven, filesystem-dependent.
- HUD functions — buffer/tab manipulation with async R calls.

## Bugs surfaced by specs (pinned)

Each of these is documented with a passing spec that asserts
current (buggy) behavior. When fixed, the spec must be updated
to assert the correct behavior.

1. **`s:MovePrevChunk` from between chunks fails**
   (`chunk_nav_spec.vim::prev_from_between_chunks_currently_fails`).
   Cursor on prose between chunk-a (ended) and chunk-b's start,
   pressing 'prev chunk' returns 0 instead of landing inside
   chunk-a. The function finds chunk-a's start line and treats
   the cursor as already inside it, never checking whether the
   chunk closed.

2. **`s:IsZzCollabProject` misses first-line `r:` target**
   (`project_root_spec.vim::zzcollab_project_first_line_r_target_not_detected`).
   The regex `\n\s*r\s*:` requires a newline *before* the
   target. A minimal Makefile whose first line is `r:` is
   misclassified as not-a-zzcollab-project. Fix: use
   `\%(^\|\n\)\s*r\s*:`.
