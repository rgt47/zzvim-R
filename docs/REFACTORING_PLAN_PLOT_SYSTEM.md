# Plot System Refactoring Plan

**Date**: 2026-01-30
**Status**: Proposal for Review
**Goal**: Simplify overengineered plot management code for public release

## Executive Summary

The plot management system has grown organically through multiple development
iterations, resulting in overlapping functionality, unclear responsibilities,
and unnecessary complexity. This document proposes a refactoring to create a
clean, maintainable architecture.

**Current State**: ~1300 lines in `.Rprofile.local` + ~1000 lines in VimScript
**Target State**: ~400 lines in `.Rprofile.local` + ~400 lines in VimScript

---

## Part 1: Issues Identified

### 1.1 Duplicated Functionality

| Function | R-side | Vim-side | Issue |
|----------|--------|----------|-------|
| Pane management | `close_plot_pane()`, `.display_in_pane()` | `s:PlotPaneExists()`, `s:RefreshPlotInPane()` | Both manage same pane |
| History navigation | `plot_prev()`, `plot_next()` | `s:PlotPrev()`, `s:PlotNext()` | Vim just calls R |
| Configuration | `set_plot_size()`, etc. | `g:zzvim_r_plot_*`, `s:WriteConfigForR()` | Two sources of truth |
| Zoom | `plot_zoom()`, `plot_zoom_kitty()` | `s:ZoomPlotPane()`, `s:OpenDockerPlotHiresInPreview()` | Overlapping |

### 1.2 Dead/Rarely-Used Code

**In R template:**
- `set_plot_size_relative()` - Terminal size detection, rarely useful
- `plot_redisplay_if_resized()` - Complex, terminal resize edge case
- `plot_split()` - Opens split pane, duplicates pane mode
- Three display modes (inline/pane/auto) - only `pane` is recommended
- Session-based history alongside persistent history

**In VimScript:**
- `s:GenerateCompositeImage()` - 150 lines of ImageMagick commands for composite view
- `s:PlotWindowToggleVim()`, `s:PlotWindowSelectVim()` - Plot window mode
- `s:OpenThumbnailGallery()` - Separate from text gallery, incomplete
- Adaptive polling (fast/slow) - Minimal benefit for complexity cost
- `s:GenerateMissingThumbnails()` - Host-side thumbnail gen, duplicates R-side

### 1.3 Unclear Responsibility Boundaries

```
Current Architecture (Confused):

┌─────────────────────────────────────────────────────────────────┐
│                           VIM                                   │
│  - Watches .plots/.signal                                       │
│  - Creates/manages kitty pane via kitty @                       │
│  - Writes config JSON for R                                     │
│  - Has its own plot history navigation                          │
│  - Generates composite images with ImageMagick                  │
│  - Has adaptive polling logic                                   │
└─────────────────────────────────────────────────────────────────┘
            ↕ file system (.plots/)  ↕ R commands
┌─────────────────────────────────────────────────────────────────┐
│                            R                                    │
│  - Renders plots to PNG                                         │
│  - Creates/manages kitty pane via kitty @ (duplicate!)          │
│  - Reads config JSON from Vim                                   │
│  - Has its own plot history (session + persistent)              │
│  - Manages display modes (inline/pane/auto)                     │
│  - Handles Docker vs host detection                             │
└─────────────────────────────────────────────────────────────────┘
```

**Problems:**
- Both sides try to manage the same kitty pane
- Two history systems (R session + persistent files)
- Config flows Vim → JSON → R (unnecessary indirection)
- Docker detection spreads logic across both sides

### 1.4 Over-Engineering Examples

**Dual-Resolution Always-On:**
```r
zzplot <- function(...) {
  # Renders BOTH sizes every time, even if zoom never used
  .create_plot_device_at_size("small")   # 600x450
  eval(plot_call)
  dev.off_original()
  .create_plot_device_at_size("large")   # 1800x1350
  eval(plot_call)
  dev.off_original()
  # ... display small version
}
```
Cost: Double rendering time, double disk writes, double memory

**Adaptive Polling:**
```vim
let s:poll_fast = 50     " Fast polling during active work
let s:poll_slow = 1000   " Slow polling when idle
" Plus 30 lines of activity tracking and mode switching
```
Cost: Complexity for minimal CPU savings

**Composite Image Generation:**
```vim
" 150 lines of ImageMagick commands to create:
" - Header image
" - 2x4 thumbnail grid with reordering
" - Number labels
" - Resize main plot
" - Stack header + grid
" - Append to main
```
Cost: External dependency, slow, complex layout logic

### 1.5 Documentation vs Reality Mismatch

- `plot-window-options.md` references `plot_maximize()` - function doesn't exist
- Multiple zoom functions with overlapping purposes
- Gallery types not clearly documented
- Docker vs host behavior differs but not clearly explained

---

## Part 2: Proposed Architecture

### 2.1 Clear Separation of Concerns

```
Proposed Architecture (Clean):

┌─────────────────────────────────────────────────────────────────┐
│                     VIM (Display Layer)                         │
│  - Watches .plots/.signal for new plots                         │
│  - Manages kitty plot pane lifecycle                            │
│  - Opens hi-res images for zoom (Preview or Kitty window)       │
│  - Provides gallery buffer for history browsing                 │
│  - Sends R commands for navigation (plot_prev, plot_next)       │
│  - NO config writing, NO composite generation                   │
└─────────────────────────────────────────────────────────────────┘
                    ↓ watches files    ↓ sends R commands
┌─────────────────────────────────────────────────────────────────┐
│                     R (Render Layer)                            │
│  - Renders plots to .plots/current.png                          │
│  - Renders hi-res only on explicit request                      │
│  - Manages persistent history in .plots/history/                │
│  - Provides navigation functions (plot_prev, plot_next)         │
│  - Handles configuration (size, dpi)                            │
│  - NO kitty @ commands (Vim handles display)                    │
└─────────────────────────────────────────────────────────────────┘
```

**Key Principle**: R renders, Vim displays. Single responsibility.

### 2.2 Simplified Feature Set

| Feature | Keep | Remove | Rationale |
|---------|------|--------|-----------|
| Pane display mode | ✓ | inline, auto | Pane is the standard workflow |
| Persistent history | ✓ | session history | One source of truth |
| History navigation | ✓ (R-side) | Vim-side duplication | R manages history |
| Zoom to Preview | ✓ | | Simple, reliable |
| Zoom to Kitty window | ✓ | | Useful for presentations |
| Vim gallery buffer | ✓ | thumbnail gallery | Text is faster, works everywhere |
| Dual-resolution | Lazy | Always-on | Render hi-res only when needed |
| Adaptive polling | | ✓ | Fixed 100ms is fine |
| Composite/window mode | | ✓ | Complex, gallery is better |
| Config JSON sync | | ✓ | R handles its own config |
| Terminal size tracking | | ✓ | Rarely useful |
| Template versioning | ✓ | | Useful for upgrades |

### 2.3 Simplified R Template (~400 lines)

```r
# ============================================================================
# Terminal Graphics Support for zzvim-R (Simplified)
# zzvim-R template version: 7
# ============================================================================

# Terminal Detection (keep)
.terminal_type <- function() { ... }  # ~10 lines
.is_docker <- function() { ... }      # ~3 lines

# Configuration (simplified)
.plot_width <- 600
.plot_height <- 450
.plot_res <- 96

set_plot_size <- function(width = 600, height = 450, res = 96) {
  assign(".plot_width", width, envir = .GlobalEnv)
  assign(".plot_height", height, envir = .GlobalEnv)
  assign(".plot_res", res, envir = .GlobalEnv)
  cat(sprintf("Plot size: %dx%d @ %ddpi\n", width, height, res))
}

# Core Plot Functions (simplified - no dual-resolution by default)
zzplot <- function(..., .name = NULL) {
  pf <- .render_plot(function() plot(...))
  .save_to_history(pf, .name, deparse(substitute(list(...))))
  .signal_vim(pf)
}

zzggplot <- function(p, .name = NULL) {
  pf <- .render_plot(function() print(p))
  .save_to_history(pf, .name, deparse(substitute(p)))
  .signal_vim(pf)
}

.render_plot <- function(plot_fn) {
  pf <- ".plots/current.png"
  if (!dir.exists(".plots")) dir.create(".plots")
  png(pf, width = .plot_width, height = .plot_height, res = .plot_res)
  plot_fn()
  dev.off()
  pf
}

.signal_vim <- function(pf) {
  writeLines(as.character(Sys.time()), ".plots/.signal")
}

# History (persistent only, simplified)
.save_to_history <- function(pf, name, code) {
  # ~50 lines: copy to history/, update index.json
}

plot_prev <- function() { ... }   # ~20 lines
plot_next <- function() { ... }   # ~20 lines
plot_goto <- function(id) { ... } # ~15 lines
plot_history <- function() { ... } # ~15 lines

# Zoom (render hi-res on demand)
plot_zoom <- function() {
  pf_hires <- ".plots/current_hires.png"
  png(pf_hires, width = .plot_width * 3, height = .plot_height * 3, res = .plot_res)
  # Re-render current plot at high resolution
  # This requires storing the plot expression, or just use the PNG
  dev.off()
  system2("open", pf_hires, wait = FALSE)
}

# Export
save_plot <- function(filename) { ... }  # ~5 lines

# Startup message
if (interactive()) {
  cat("Terminal graphics enabled\n")
  cat("  zzplot(...)  : Base R plots\n")
  cat("  zzggplot(p)  : ggplot2 plots\n")
  cat("  plot_zoom()  : Open hi-res version\n")
}
```

**Removed:**
- Display mode management (inline/pane/auto)
- Kitty remote control from R
- Terminal size tracking
- Session-based history
- Dual-resolution always-on
- `plot_split()`, `plot_maximize()`, `close_plot_pane()`

### 2.4 Simplified VimScript (~400 lines)

```vim
" Plot Watcher (simplified - no adaptive polling)
let s:poll_interval = 100
let s:plot_signal_mtime = 0
let s:pane_title = 'zzvim-plot'

function! s:StartPlotWatcher() abort
  if exists('s:plot_watcher_timer')
    call timer_stop(s:plot_watcher_timer)
  endif
  let s:plot_watcher_timer = timer_start(s:poll_interval,
    \ {-> s:CheckForNewPlot()}, {'repeat': -1})
endfunction

function! s:CheckForNewPlot() abort
  let l:signal = '.plots/.signal'
  if !filereadable(l:signal)
    return
  endif
  let l:mtime = getftime(l:signal)
  if l:mtime <= s:plot_signal_mtime
    return
  endif
  let s:plot_signal_mtime = l:mtime
  call s:DisplayPlot()
endfunction

function! s:DisplayPlot() abort
  let l:pf = '.plots/current.png'
  if !filereadable(l:pf)
    return
  endif

  " Refresh existing pane or create new
  if s:PlotPaneExists()
    call system('kitty @ send-text --match title:' . s:pane_title . " r")
  else
    call s:CreatePlotPane(l:pf)
  endif
endfunction

function! s:CreatePlotPane(plot_file) abort
  " Simple shell script that displays plot and waits for input
  let l:script = '/tmp/zzvim_plot.sh'
  call writefile([
    \ '#!/bin/bash',
    \ 'while true; do',
    \ '  clear',
    \ '  kitty +kitten icat --clear ' . shellescape(a:plot_file),
    \ '  read -n1 -s key',
    \ '  [[ "$key" == "q" ]] && exit 0',
    \ 'done'
    \ ], l:script)
  call system('chmod +x ' . l:script)
  call system('kitty @ launch --location=vsplit --keep-focus --title '
    \ . s:pane_title . ' ' . l:script)
endfunction

function! s:PlotPaneExists() abort
  return system('kitty @ ls 2>/dev/null') =~# s:pane_title
endfunction

" Zoom functions
function! s:ZoomInPreview() abort
  let l:pf = '.plots/current.png'
  if filereadable(l:pf)
    call system('open ' . shellescape(l:pf))
  endif
endfunction

function! s:ZoomInKittyWindow() abort
  let l:pf = '.plots/current.png'
  if filereadable(l:pf)
    call system('kitty @ launch --type=os-window kitty +kitten icat --hold '
      \ . shellescape(l:pf))
  endif
endfunction

" Gallery buffer (keep as-is, it's useful)
function! s:OpenPlotGallery() abort
  " ~60 lines - this is a good feature
endfunction

" Cleanup
function! s:OnRTerminalClose() abort
  call s:StopPlotWatcher()
  call system('kitty @ close-window --match title:' . s:pane_title . ' 2>/dev/null')
endfunction

" Commands
command! RPlotShow call s:DisplayPlot()
command! RPlotPreview call s:ZoomInPreview()
command! RPlotZoom call s:ZoomInKittyWindow()
command! RPlotGallery call s:OpenPlotGallery()

" Mappings
nnoremap <LocalLeader>[ :RPlotPreview<CR>
nnoremap <LocalLeader>] :RPlotZoom<CR>
nnoremap <LocalLeader>G :RPlotGallery<CR>
```

**Removed:**
- Adaptive polling
- Composite image generation
- Plot window mode
- Thumbnail gallery
- Config JSON writing
- Multiple zoom variants
- Path caching (premature optimization)
- Host-side thumbnail generation

---

## Part 3: Refactoring Steps

### Phase 1: Clean Up R Template (Day 1)

1. **Remove display mode management**
   - Delete `.display_in_pane()`, `set_plot_mode()`, `.plot_display_mode`
   - Keep only file-based output (Vim handles display)

2. **Remove session-based history**
   - Delete in-memory `.plot_history` list
   - Keep only persistent `.plots/history/`

3. **Remove kitty remote control from R**
   - Delete `.kitty_remote_enabled()`, `.kitty_window_exists()`
   - R just writes files; Vim handles kitty

4. **Simplify dual-resolution**
   - Render only small version by default
   - Add `plot_zoom()` that re-renders at 3x on demand

5. **Remove terminal size tracking**
   - Delete `.store_terminal_size()`, `plot_redisplay_if_resized()`
   - Delete `set_plot_size_relative()`

6. **Remove unused functions**
   - Delete `plot_split()`, `close_plot_pane()`

### Phase 2: Clean Up VimScript (Day 2)

1. **Remove adaptive polling**
   - Delete `s:poll_fast`, `s:poll_slow`, `s:MaybeSlowDown()`
   - Use fixed 100ms interval

2. **Remove composite image generation**
   - Delete `s:GenerateCompositeImage()` (~150 lines)
   - Delete `s:PlotWindowToggleVim()`, `s:PlotWindowSelectVim()`

3. **Remove thumbnail gallery**
   - Delete `s:OpenThumbnailGallery()` (~100 lines)
   - Keep text-based gallery

4. **Remove config JSON sync**
   - Delete `s:WriteConfigForR()`
   - Delete `g:zzvim_r_plot_*` config variables (except location)

5. **Remove host-side thumbnail generation**
   - Delete `s:GenerateMissingThumbnails()`

6. **Consolidate zoom functions**
   - Keep `s:ZoomInPreview()` and `s:ZoomInKittyWindow()`
   - Remove redundant variants

### Phase 3: Update Documentation (Day 3)

1. **Update vignette**
   - Simplify to reflect new architecture
   - Remove references to removed features

2. **Update CLAUDE.md**
   - Document new clean architecture
   - Remove obsolete implementation details

3. **Remove obsolete docs**
   - `plot-window-options.md` - references removed features
   - `plot-display-design-rationale.md` - keep, still valid

4. **Update README**
   - Simplify plot feature description

### Phase 4: Testing (Day 4)

1. **Test basic workflow**
   - `zzplot()` displays in pane
   - `zzggplot()` displays in pane
   - Pane refreshes on new plot

2. **Test history**
   - `plot_prev()`, `plot_next()` work
   - Gallery shows history correctly

3. **Test zoom**
   - `<LocalLeader>[` opens Preview
   - `<LocalLeader>]` opens Kitty window

4. **Test Docker mode**
   - Plots work from Docker R

---

## Part 4: What to Keep

### Essential Features (Keep As-Is)
- File-based communication (.plots/.signal)
- Persistent history with JSON index
- Vim gallery buffer
- Template versioning
- Pane display via kitty

### Good Abstractions (Keep)
- `s:GetPlotsDir()`, `s:GetPlotFile()` path helpers
- `zzplot()`, `zzggplot()` wrapper pattern
- Exit callbacks for cleanup

### Documentation (Keep)
- `plot-display-design-rationale.md` - Explains wrapper vs override decision
- Template version history comments

---

## Part 5: Risk Assessment

### Low Risk
- Removing adaptive polling - Minimal impact
- Removing terminal size tracking - Rarely used
- Consolidating zoom functions - Just renaming

### Medium Risk
- Removing dual-resolution always-on - Users expecting hi-res
- Removing display modes - Users using inline mode

### Mitigation
- Keep `plot_zoom()` function for on-demand hi-res
- Document that pane mode is the only mode
- Provide clear migration notes

---

## Part 6: Migration Notes for Users

```markdown
## Migrating from v6 to v7

### Changed Behavior
- Plots always display in a dedicated pane (no inline mode)
- Hi-res version rendered on demand, not automatically
- Configuration functions simplified

### Removed Functions
- `set_plot_mode()` - Pane mode is now the only mode
- `set_plot_size_relative()` - Use `set_plot_size()` instead
- `plot_split()` - Use zoom functions instead
- `close_plot_pane()` - Pane closes with R terminal

### New Workflow
1. Create plot: `zzplot(x, y)`
2. Plot appears in pane
3. Zoom: Press `<LocalLeader>]` in Vim or call `plot_zoom()` in R
4. Navigate history: `plot_prev()`, `plot_next()`
5. Browse history: `<LocalLeader>G` for gallery
```

---

## Appendix: Line Count Comparison

| Component | Current | Target | Reduction |
|-----------|---------|--------|-----------|
| `.Rprofile.local` | 1025 | ~400 | 60% |
| VimScript (plot code) | ~1000 | ~400 | 60% |
| `terminal_graphics.vim` | 264 | 264 | 0% |
| Documentation | ~2500 | ~1000 | 60% |
| **Total** | ~4800 | ~2000 | **58%** |

---

## Decision Required

Before proceeding, please confirm:

1. **Remove display modes?** Keep only pane mode, remove inline/auto
2. **Remove dual-resolution always-on?** Render hi-res only on zoom request
3. **Remove composite/window mode?** Gallery buffer is sufficient
4. **Remove adaptive polling?** Fixed 100ms interval
5. **Remove Vim→R config sync?** R manages its own configuration

If yes to all, the refactoring can proceed as outlined above.
