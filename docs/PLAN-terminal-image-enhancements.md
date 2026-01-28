# Terminal Image Display Enhancement Plan

## Executive Summary

This plan outlines enhancements to zzvim-R's terminal image display system across
four areas: enhanced features, performance optimization, configuration
flexibility, and Vim/R integration. The implementation is organized into four
phases with clear dependencies and deliverables.

## Current Architecture Overview

### Components

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Current Architecture                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  R Session (.Rprofile.local)              Vim (plugin/zzvim-R.vim)     │
│  ┌─────────────────────────┐              ┌─────────────────────────┐  │
│  │ zzplot() / zzggplot()   │              │ Plot Watcher (500ms)    │  │
│  │ .plot_history list      │──(file)────▶ │ s:DisplayDockerPlot()   │  │
│  │ .display_plot()         │              │ kitty @ commands        │  │
│  │ set_plot_*() config     │              │ :RPlot* commands        │  │
│  └─────────────────────────┘              └─────────────────────────┘  │
│           │                                          │                  │
│           ▼                                          ▼                  │
│  .plots/current.png                        kitty pane (zzvim-plot)     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### Current Limitations

1. **Performance**: Fixed 500ms polling regardless of activity
2. **Features**: Single plot view, linear history only
3. **Configuration**: Split between R and Vim with no synchronization
4. **Integration**: One-way communication (R → file → Vim)

---

## Phase 1: Performance Optimization

**Goal**: Reduce plot display latency from ~300ms average to <100ms

### 1.1 Event-Driven Plot Detection

Replace timer-based polling with signal file approach.

**Implementation**:

```
R writes plot                    Vim watches signal
     │                                 │
     ▼                                 ▼
.plots/current.png          .plots/.signal (touch)
     │                                 │
     └────────────────┬────────────────┘
                      ▼
              Vim detects signal change
              (10ms poll on tiny file)
                      │
                      ▼
              Display plot immediately
```

**R-side changes** (`.Rprofile.local`):

```r
.signal_plot_ready <- function() {
  signal_file <- ".plots/.signal"
  if (!dir.exists(".plots")) dir.create(".plots", showWarnings = FALSE)
  # Touch signal file with current timestamp
  writeLines(as.character(Sys.time()), signal_file)
}

# Modify .display_plot() to call signal after file write
.display_plot <- function(pf) {
  # ... existing display logic ...
  if (.is_docker()) {
    file.copy(pf, ".plots/current.png", overwrite = TRUE)
    .signal_plot_ready()  # NEW: Signal Vim
  }
  # ...
}
```

**Vim-side changes** (`plugin/zzvim-R.vim`):

```vim
let s:signal_file_mtime = 0

function! s:GetSignalFile() abort
    return s:GetProjectRoot() . '/.plots/.signal'
endfunction

function! s:CheckPlotSignal() abort
    let l:signal = s:GetSignalFile()
    if !filereadable(l:signal)
        return
    endif
    let l:mtime = getftime(l:signal)
    if l:mtime > s:signal_file_mtime
        let s:signal_file_mtime = l:mtime
        call s:DisplayDockerPlot()
    endif
endfunction

" Fast polling on tiny signal file (50ms)
function! s:StartPlotWatcher() abort
    if exists('s:plot_watcher_timer')
        call timer_stop(s:plot_watcher_timer)
    endif
    let s:plot_watcher_timer = timer_start(50, {-> s:CheckPlotSignal()}, {'repeat': -1})
endfunction
```

**Benefits**:
- 50ms poll on <100 byte file vs 500ms poll on PNG
- Signal file change = guaranteed new plot (no false positives)
- Backward compatible (falls back to mtime if no signal)

### 1.2 Adaptive Polling

Implement activity-based polling rate adjustment.

```vim
let s:poll_fast = 50       " During active work
let s:poll_slow = 1000     " When idle
let s:poll_current = 50
let s:last_r_activity = 0

function! s:OnRActivity() abort
    let s:last_r_activity = localtime()
    if s:poll_current != s:poll_fast
        let s:poll_current = s:poll_fast
        call s:RestartWatcher()
    endif
endfunction

function! s:MaybeSlowDown() abort
    " Slow down if no R activity for 30 seconds
    if localtime() - s:last_r_activity > 30
        if s:poll_current != s:poll_slow
            let s:poll_current = s:poll_slow
            call s:RestartWatcher()
        endif
    endif
endfunction

" Hook into s:Send_to_r() to track activity
function! s:Send_to_r(cmd, stay_on_line) abort
    call s:OnRActivity()  " Track activity
    " ... existing logic ...
endfunction
```

### 1.3 Pre-warmed Plot Pane

Keep plot pane alive and update in-place instead of recreate.

```vim
function! s:UpdatePlotInPane() abort
    let l:plot_file = s:GetPlotFile()
    let l:pane_title = 'zzvim-plot'

    if s:PlotPaneExists()
        " Update existing pane (faster)
        let l:cmd = 'kitty +kitten icat --clear --scale-up ' . shellescape(l:plot_file)
        call system('kitty @ send-text --match title:' . l:pane_title .
                  \ ' ' . shellescape(l:cmd . "\n"))
    else
        " Create new pane (first time only)
        call s:CreatePlotPane()
    endif
endfunction

function! s:PlotPaneExists() abort
    let l:check = system('kitty @ ls 2>/dev/null | grep -q zzvim-plot && echo 1')
    return trim(l:check) == '1'
endfunction
```

### 1.4 Deliverables

| Item | File | Description |
|------|------|-------------|
| Signal file mechanism | `.Rprofile.local`, `zzvim-R.vim` | R signals, Vim responds |
| Adaptive polling | `zzvim-R.vim` | Fast/slow based on activity |
| Pre-warmed pane | `zzvim-R.vim` | Update vs recreate |
| `:RPlotPerfDebug` | `zzvim-R.vim` | Performance diagnostics |

---

## Phase 2: Configuration Unification

**Goal**: Single source of truth for plot settings across R and Vim

### 2.1 Configuration File Format

Create `.zzvim-r.json` in project root for unified settings.

```json
{
  "plot": {
    "width": 900,
    "height": 700,
    "dpi": 96,
    "align": "right",
    "mode": "pane",
    "pane_location": "vsplit",
    "history_limit": 50,
    "thumbnails": true
  }
}
```

### 2.2 Vim Configuration Variables

```vim
" New g:zzvim_r_plot_* variables
let g:zzvim_r_plot_width = get(g:, 'zzvim_r_plot_width', 900)
let g:zzvim_r_plot_height = get(g:, 'zzvim_r_plot_height', 700)
let g:zzvim_r_plot_dpi = get(g:, 'zzvim_r_plot_dpi', 96)
let g:zzvim_r_plot_align = get(g:, 'zzvim_r_plot_align', 'right')
let g:zzvim_r_plot_mode = get(g:, 'zzvim_r_plot_mode', 'pane')
let g:zzvim_r_plot_location = get(g:, 'zzvim_r_plot_location', 'vsplit')
let g:zzvim_r_plot_history_limit = get(g:, 'zzvim_r_plot_history_limit', 50)

" Write config for R to read
function! s:WriteConfigForR() abort
    let l:config = {
        \ 'width': g:zzvim_r_plot_width,
        \ 'height': g:zzvim_r_plot_height,
        \ 'dpi': g:zzvim_r_plot_dpi,
        \ 'align': g:zzvim_r_plot_align,
        \ 'mode': g:zzvim_r_plot_mode,
        \ 'history_limit': g:zzvim_r_plot_history_limit
    \ }
    let l:json = json_encode(l:config)
    let l:config_file = s:GetProjectRoot() . '/.plots/.config.json'
    call writefile([l:json], l:config_file)
endfunction
```

### 2.3 R Configuration Reader

```r
.read_vim_config <- function() {
  config_file <- ".plots/.config.json"
  if (file.exists(config_file)) {
    tryCatch({
      config <- jsonlite::fromJSON(config_file)
      if (!is.null(config$width)) assign(".plot_width", config$width, envir = .GlobalEnv)
      if (!is.null(config$height)) assign(".plot_height", config$height, envir = .GlobalEnv)
      if (!is.null(config$dpi)) assign(".plot_res", config$dpi, envir = .GlobalEnv)
      if (!is.null(config$align)) assign(".plot_align", config$align, envir = .GlobalEnv)
      if (!is.null(config$mode)) assign(".plot_display_mode", config$mode, envir = .GlobalEnv)
      if (!is.null(config$history_limit)) assign(".plot_history_limit", config$history_limit, envir = .GlobalEnv)
    }, error = function(e) {
      # Silently use defaults if config read fails
    })
  }
}

# Call on plot creation to pick up any config changes
.create_plot_device <- function() {
  .read_vim_config()  # Check for updated config
  # ... existing logic ...
}
```

### 2.4 Pane Location Options

```vim
" g:zzvim_r_plot_location options:
"   'vsplit'  - vertical split to right (default)
"   'hsplit'  - horizontal split below
"   'float'   - floating window (Neovim only)
"   'tab'     - new tab

function! s:GetPaneLocationArg() abort
    let l:loc = g:zzvim_r_plot_location
    if l:loc == 'vsplit'
        return '--location=vsplit'
    elseif l:loc == 'hsplit'
        return '--location=hsplit'
    elseif l:loc == 'tab'
        return '--location=tab'
    else
        return '--location=vsplit'
    endif
endfunction
```

### 2.5 Deliverables

| Item | File | Description |
|------|------|-------------|
| Config file format | `.zzvim-r.json` spec | JSON schema for settings |
| Vim config vars | `zzvim-R.vim` | `g:zzvim_r_plot_*` variables |
| R config reader | `.Rprofile.local` | Read Vim-written config |
| Location options | `zzvim-R.vim` | vsplit/hsplit/tab/float |
| `:RPlotConfig` | `zzvim-R.vim` | View/edit current config |

---

## Phase 3: Enhanced Features

**Goal**: Gallery view, improved history management, thumbnails

### 3.1 Plot History Persistence

Store plot history in `.plots/history/` with metadata.

**Directory structure**:

```
.plots/
├── current.png          # Current plot (for watcher)
├── .signal              # Signal file for Vim
├── .config.json         # Unified configuration
└── history/
    ├── index.json       # History metadata
    ├── 001_linear.png   # Named plots
    ├── 001_linear_thumb.png
    ├── 002_scatter.png
    └── 002_scatter_thumb.png
```

**History index format** (`index.json`):

```json
{
  "version": 1,
  "plots": [
    {
      "id": 1,
      "file": "001_linear.png",
      "thumb": "001_linear_thumb.png",
      "name": "linear",
      "created": "2026-01-28T10:30:00",
      "width": 900,
      "height": 700,
      "code": "plot(1:10, (1:10)^2)"
    }
  ],
  "current_index": 1
}
```

### 3.2 R-side History Functions

```r
.plot_counter <- 0
.plot_history_limit <- 50

# Enhanced zzplot with optional name and history
zzplot <- function(..., .name = NULL, .save_history = TRUE) {
  .GlobalEnv$.create_plot_device()
  plot(...)
  dev.off()

  if (.save_history) {
    .add_to_history(.name, deparse(substitute(list(...))))
  }
}

.add_to_history <- function(name, code) {
  .plot_counter <<- .plot_counter + 1

  history_dir <- ".plots/history"
  if (!dir.exists(history_dir)) dir.create(history_dir, recursive = TRUE)

  # Generate name if not provided
  if (is.null(name)) {
    name <- sprintf("plot_%03d", .plot_counter)
  }

  # Copy current plot to history
  src <- get(".plot_file", envir = .GlobalEnv)
  dst <- file.path(history_dir, sprintf("%03d_%s.png", .plot_counter, name))
  file.copy(src, dst, overwrite = TRUE)

  # Generate thumbnail (200px wide)
  .generate_thumbnail(dst)

  # Update index
  .update_history_index(.plot_counter, name, dst, code)

  # Trim history if over limit
  .trim_history()
}

.generate_thumbnail <- function(src_path) {
  thumb_path <- sub("\\.png$", "_thumb.png", src_path)
  # Use R's png package or system convert
  if (Sys.which("convert") != "") {
    system(paste("convert", shQuote(src_path), "-resize 200x", shQuote(thumb_path)),
           ignore.stderr = TRUE)
  }
}

.update_history_index <- function(id, name, file, code) {
  index_file <- ".plots/history/index.json"

  if (file.exists(index_file)) {
    index <- jsonlite::fromJSON(index_file)
  } else {
    index <- list(version = 1, plots = list(), current_index = 0)
  }

  new_entry <- list(
    id = id,
    file = basename(file),
    thumb = sub("\\.png$", "_thumb.png", basename(file)),
    name = name,
    created = format(Sys.time(), "%Y-%m-%dT%H:%M:%S"),
    code = code
  )

  index$plots <- c(index$plots, list(new_entry))
  index$current_index <- id

  jsonlite::write_json(index, index_file, auto_unbox = TRUE, pretty = TRUE)
}

# Navigate by name
plot_goto <- function(name_or_id) {
  index <- .read_history_index()
  if (is.numeric(name_or_id)) {
    entry <- Filter(function(x) x$id == name_or_id, index$plots)
  } else {
    entry <- Filter(function(x) grepl(name_or_id, x$name, ignore.case = TRUE), index$plots)
  }

  if (length(entry) > 0) {
    file <- file.path(".plots/history", entry[[1]]$file)
    .GlobalEnv$.display_plot(file)
    cat(sprintf("Showing: %s (%s)\n", entry[[1]]$name, entry[[1]]$created))
  } else {
    cat("Plot not found\n")
  }
}

# Search history
plot_search <- function(pattern) {
  index <- .read_history_index()
  matches <- Filter(function(x) {
    grepl(pattern, x$name, ignore.case = TRUE) ||
    grepl(pattern, x$code, ignore.case = TRUE)
  }, index$plots)

  if (length(matches) > 0) {
    cat(sprintf("Found %d plots:\n", length(matches)))
    for (m in matches) {
      cat(sprintf("  [%d] %s - %s\n", m$id, m$name, m$created))
    }
  } else {
    cat("No matching plots\n")
  }
}
```

### 3.3 Gallery View (Vim-side)

Create a Vim buffer displaying thumbnail grid.

```vim
function! s:OpenPlotGallery() abort
    let l:index_file = s:GetProjectRoot() . '/.plots/history/index.json'
    if !filereadable(l:index_file)
        call s:Error("No plot history found")
        return
    endif

    let l:index = json_decode(join(readfile(l:index_file), ''))
    if empty(l:index.plots)
        call s:Error("Plot history is empty")
        return
    endif

    " Create gallery buffer
    vnew
    setlocal buftype=nofile bufhidden=wipe noswapfile
    setlocal nonumber norelativenumber
    file [Plot Gallery]

    " Build gallery content
    let l:lines = ['╔══════════════════════════════════════════════════════════════╗']
    call add(l:lines, '║                      Plot Gallery                            ║')
    call add(l:lines, '║  Press number to view, Enter on line, q to close            ║')
    call add(l:lines, '╚══════════════════════════════════════════════════════════════╝')
    call add(l:lines, '')

    let l:idx = 1
    for plot in l:index.plots
        let l:line = printf('  [%d] %-20s  %s', l:idx, plot.name, plot.created)
        call add(l:lines, l:line)
        let l:idx += 1
    endfor

    call setline(1, l:lines)
    setlocal readonly

    " Key mappings for gallery
    nnoremap <buffer> <silent> q :bwipe<CR>
    nnoremap <buffer> <silent> <CR> :call <SID>GallerySelectCurrent()<CR>
    for i in range(1, 9)
        execute 'nnoremap <buffer> <silent> ' . i . ' :call <SID>GallerySelect(' . i . ')<CR>'
    endfor
endfunction

function! s:GallerySelect(num) abort
    call s:Send_to_r('plot_goto(' . a:num . ')', 1)
endfunction

function! s:GallerySelectCurrent() abort
    let l:line = getline('.')
    let l:match = matchstr(l:line, '\[\zs\d\+\ze\]')
    if !empty(l:match)
        call s:GallerySelect(str2nr(l:match))
    endif
endfunction

command! -bar RPlotGallery call s:OpenPlotGallery()
```

### 3.4 Thumbnail Display in Kitty

For terminals supporting unicode placeholders, display actual thumbnails.

```vim
function! s:DisplayThumbnailGrid() abort
    " Only works in Kitty with unicode placeholders
    if empty($KITTY_WINDOW_ID)
        call s:OpenPlotGallery()  " Fallback to text gallery
        return
    endif

    let l:history_dir = s:GetProjectRoot() . '/.plots/history/'
    let l:thumbs = glob(l:history_dir . '*_thumb.png', 0, 1)

    if empty(l:thumbs)
        call s:Error("No thumbnails found")
        return
    endif

    " Create gallery pane with thumbnail grid
    let l:pane_title = 'zzvim-gallery'
    call system('kitty @ close-window --match title:' . l:pane_title . ' 2>/dev/null')

    " Build display command showing thumbnails in grid
    let l:cmd = 'clear; echo "Plot Gallery - press number to select, q to close"; echo ""'
    let l:idx = 1
    for thumb in l:thumbs[:8]  " Max 9 thumbnails
        let l:cmd .= '; echo "[' . l:idx . ']"; kitty +kitten icat --place 20x15@0x0 ' . shellescape(thumb)
        let l:idx += 1
    endfor
    let l:cmd .= '; read -n1 choice; echo $choice > /tmp/zzvim_gallery_choice'

    call system('kitty @ launch --location=vsplit --keep-focus --title ' . l:pane_title .
              \ ' -- sh -c ' . shellescape(l:cmd))
endfunction
```

### 3.5 Deliverables

| Item | File | Description |
|------|------|-------------|
| History persistence | `.Rprofile.local` | Save plots to history/ |
| Thumbnail generation | `.Rprofile.local` | Auto-generate thumbnails |
| History index | `.plots/history/index.json` | Metadata JSON |
| `plot_goto()` | `.Rprofile.local` | Navigate by name/id |
| `plot_search()` | `.Rprofile.local` | Search history |
| `:RPlotGallery` | `zzvim-R.vim` | Vim gallery buffer |
| `<LocalLeader>G` | `zzvim-R.vim` | Quick gallery access |

---

## Phase 4: Vim/R Integration

**Goal**: Bidirectional communication and synchronized state

### 4.1 R → Vim Signaling

R can signal Vim about plot state changes.

```r
# Signal Vim via file
.signal_vim <- function(event, data = list()) {
  signal_file <- ".plots/.vim_signal"
  payload <- list(
    event = event,
    time = format(Sys.time(), "%Y-%m-%dT%H:%M:%OS3"),
    data = data
  )
  jsonlite::write_json(payload, signal_file, auto_unbox = TRUE)
}

# Usage in display function
.display_plot <- function(pf) {
  # ... existing display ...
  .signal_vim("plot_ready", list(
    file = pf,
    index = get(".plot_history_idx", envir = .GlobalEnv),
    total = length(get(".plot_history", envir = .GlobalEnv))
  ))
}
```

### 4.2 Vim → R Commands

Vim can request actions from R.

```vim
" Request plot info from R
function! s:RequestPlotInfo() abort
    call s:Send_to_r('.signal_vim("plot_info", list(index=.plot_history_idx, total=length(.plot_history)))', 1)
    " Wait for response in signal file
    call timer_start(100, {-> s:ReadPlotInfo()})
endfunction

function! s:ReadPlotInfo() abort
    let l:signal = s:GetProjectRoot() . '/.plots/.vim_signal'
    if filereadable(l:signal)
        let l:data = json_decode(join(readfile(l:signal), ''))
        if l:data.event == 'plot_info'
            let s:plot_index = l:data.data.index
            let s:plot_total = l:data.data.total
            " Update statusline
            redrawstatus
        endif
    endif
endfunction
```

### 4.3 Statusline Integration

```vim
" Plot info for statusline
function! ZzvimRPlotStatus() abort
    if !exists('s:plot_index') || s:plot_total == 0
        return ''
    endif
    return printf('[Plot %d/%d]', s:plot_index, s:plot_total)
endfunction

" Example statusline usage (user adds to their config):
" set statusline+=%{ZzvimRPlotStatus()}
```

### 4.4 Synchronized Navigation

```vim
" Vim-side navigation that syncs with R
function! s:PlotNext() abort
    call s:Send_to_r('plot_next()', 1)
    call s:RequestPlotInfo()
endfunction

function! s:PlotPrev() abort
    call s:Send_to_r('plot_prev()', 1)
    call s:RequestPlotInfo()
endfunction

nnoremap <Plug>(zzvim-r-plot-next) :call <SID>PlotNext()<CR>
nnoremap <Plug>(zzvim-r-plot-prev) :call <SID>PlotPrev()<CR>
```

### 4.5 Event Handling

```vim
" Process signals from R
function! s:ProcessRSignal() abort
    let l:signal = s:GetProjectRoot() . '/.plots/.vim_signal'
    if !filereadable(l:signal)
        return
    endif

    let l:mtime = getftime(l:signal)
    if l:mtime <= s:last_signal_mtime
        return
    endif
    let s:last_signal_mtime = l:mtime

    let l:data = json_decode(join(readfile(l:signal), ''))

    if l:data.event == 'plot_ready'
        call s:DisplayDockerPlot()
        let s:plot_index = l:data.data.index
        let s:plot_total = l:data.data.total
        redrawstatus
    elseif l:data.event == 'plot_info'
        let s:plot_index = l:data.data.index
        let s:plot_total = l:data.data.total
        redrawstatus
    elseif l:data.event == 'history_updated'
        " Refresh gallery if open
        call s:RefreshGalleryIfOpen()
    endif
endfunction
```

### 4.6 Deliverables

| Item | File | Description |
|------|------|-------------|
| R signal function | `.Rprofile.local` | `.signal_vim()` |
| Vim signal reader | `zzvim-R.vim` | Process R signals |
| Statusline function | `zzvim-R.vim` | `ZzvimRPlotStatus()` |
| Synced navigation | `zzvim-R.vim` | `<Plug>` mappings |
| Event handlers | `zzvim-R.vim` | Route R events |

---

## Implementation Schedule

### Phase 1: Performance (Week 1-2)

| Task | Priority | Effort | Dependencies |
|------|----------|--------|--------------|
| Signal file mechanism | High | 2h | None |
| Adaptive polling | Medium | 1h | Signal file |
| Pre-warmed pane | Medium | 2h | None |
| Performance debugging | Low | 1h | All above |

### Phase 2: Configuration (Week 2-3)

| Task | Priority | Effort | Dependencies |
|------|----------|--------|--------------|
| Vim config variables | High | 1h | None |
| Config file format | High | 1h | None |
| R config reader | High | 1h | Config format |
| Location options | Medium | 2h | Vim config |

### Phase 3: Features (Week 3-5)

| Task | Priority | Effort | Dependencies |
|------|----------|--------|--------------|
| History persistence | High | 3h | None |
| Thumbnail generation | Medium | 2h | History |
| History index | High | 2h | History |
| R navigation functions | High | 2h | History index |
| Vim gallery buffer | Medium | 3h | History index |
| Thumbnail grid display | Low | 3h | Thumbnails |

### Phase 4: Integration (Week 5-6)

| Task | Priority | Effort | Dependencies |
|------|----------|--------|--------------|
| R → Vim signaling | High | 2h | Signal file (P1) |
| Vim → R commands | Medium | 2h | Signal format |
| Statusline function | Low | 1h | Signaling |
| Synced navigation | Medium | 2h | Both directions |
| Event handlers | Medium | 2h | All signaling |

---

## Testing Strategy

### Unit Tests

```vim
" test_files/test_plot_enhancements.vim

" Test signal file detection
function! Test_SignalFileDetection()
    let l:signal = tempname()
    call writefile(['test'], l:signal)
    sleep 100m
    let l:mtime1 = getftime(l:signal)
    sleep 100m
    call writefile(['test2'], l:signal)
    let l:mtime2 = getftime(l:signal)
    call assert_true(l:mtime2 > l:mtime1, "Signal file mtime should update")
endfunction

" Test config JSON roundtrip
function! Test_ConfigRoundtrip()
    let l:config = {'width': 900, 'height': 700}
    let l:json = json_encode(l:config)
    let l:decoded = json_decode(l:json)
    call assert_equal(l:config.width, l:decoded.width)
endfunction
```

### Integration Tests

```r
# test_files/test_plot_history.R

# Test history persistence
test_that("plot history persists", {
  zzplot(1:10, (1:10)^2, .name = "test_linear")
  expect_true(file.exists(".plots/history/index.json"))

  index <- jsonlite::fromJSON(".plots/history/index.json")
  expect_equal(length(index$plots), 1)
  expect_equal(index$plots[[1]]$name, "test_linear")
})

# Test thumbnail generation
test_that("thumbnails are generated", {
  zzplot(1:10, (1:10)^2, .name = "test_thumb")
  thumb_file <- list.files(".plots/history", pattern = "_thumb\\.png$")
  expect_true(length(thumb_file) > 0)
})
```

---

## Backward Compatibility

### Preserved Behaviors

1. All existing `:RPlot*` commands continue to work
2. `zzplot()` / `zzggplot()` default behavior unchanged
3. Existing `g:zzvim_r_*` variables still respected
4. Timer-based polling works if signal file missing

### Migration Path

1. **Phase 1**: Signal file is additive; polling is fallback
2. **Phase 2**: New config vars have defaults matching current behavior
3. **Phase 3**: History features are opt-in (`.save_history` parameter)
4. **Phase 4**: Integration signals are non-breaking additions

---

## Documentation Updates

### Files to Update

1. `doc/zzvim-R.txt` - Add new commands and config vars
2. `README.md` - Update features list
3. `docs/terminal-graphics-setup.md` - New configuration options
4. `docs/plot-window-options.md` - Gallery and history features
5. `CHANGELOG.md` - Version history

### New Documentation

1. `docs/plot-history-management.md` - History system guide
2. `docs/plot-gallery-usage.md` - Gallery feature guide

---

## Success Metrics

| Metric | Current | Target | Measurement |
|--------|---------|--------|-------------|
| Plot display latency | ~300ms | <100ms | Time from plot() to display |
| Config locations | 2 (R + Vim) | 1 | Unified config file |
| History capacity | Session only | Persistent | Survives R restart |
| Navigation methods | 2 (prev/next) | 5+ | name, id, search, gallery |
| Vim/R sync | One-way | Bidirectional | Events flow both ways |

---

## Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| jsonlite not installed | Medium | Medium | Graceful fallback to basic JSON |
| ImageMagick not available | Medium | Low | Skip thumbnails, use full images |
| Kitty remote control disabled | Medium | Medium | Detect and warn user |
| Large history disk usage | Low | Low | Configurable limit, auto-trim |
| Signal file race conditions | Low | Low | Atomic writes, retry logic |

---

## Open Questions

1. **Thumbnail size**: 200px width good default? Make configurable?
2. **History limit**: 50 plots reasonable? Per-project setting?
3. **Gallery layout**: Text-based vs kitty image grid as default?
4. **Signal format**: JSON vs simpler timestamp-only signal?

---

**Document Version**: 1.0
**Created**: 2026-01-28
**Status**: Draft - Awaiting Review
