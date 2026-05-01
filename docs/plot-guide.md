# Plot Display Guide
*2026-04-30 06:32 PDT*

zzvim-R renders R graphics into a graphics-capable terminal pane (Kitty,
Ghostty, WezTerm, or iTerm2) using a PDF master plus PNG preview
pipeline. Plots persist across an R session as a numbered history,
navigable from R or via the Plot HUD inside Vim.

This guide covers the user-facing API. The architectural rationale for
the wrapper-based design (rather than overriding base R's `plot()` via
S3 methods) is recorded in `:help zzvim-r-design`.

## Architecture in one paragraph

When R runs `show_plot(expr)` it evaluates `expr` once into a PDF
device (vector master) and once into a PNG device (raster preview),
both written to `.graphics/current.pdf` and `.graphics/current.png`.
A timestamp is then written to `.graphics/.signal`. A Vim timer
polling that signal file at 100 ms detects the mtime change and
displays the PNG inline in a Kitty pane (or via `imgcat` on iTerm2).
The PDF is what `<LocalLeader>]` (`:RPlotZoom`) opens for inspection.
History entries are saved into `.graphics/history/` with an
`index.json` manifest.

## Prerequisites

- A graphics-capable terminal:
  - Kitty (full support, including remote control for the plot pane)
  - Ghostty, WezTerm (Kitty graphics protocol)
  - iTerm2 (uses `imgcat`; basic display only)
- R packages: `jsonlite` (history index), `magick` (PDF-to-PNG render),
  optionally `ggplot2`.
- For Kitty, enable remote control in `~/.config/kitty/kitty.conf`:

  ```
  allow_remote_control yes
  ```

  and restart Kitty.

## R-side API

The plot functions are installed by `.Rprofile.local` (template version
1.9.0+), which the plugin auto-creates on first use of an R file.

### Display

| Function                  | Purpose                                       |
| ------------------------- | --------------------------------------------- |
| `show(expr)`              | Convenience wrapper around `show_plot`        |
| `show_plot(expr, .name)`  | Render and display a plot; record in history  |
| `show_table(x, .name)`    | Render a table to PDF + PNG; record in history|

```r
library(ggplot2)

show_plot(plot(mpg ~ wt, data = mtcars), .name = 'wt_mpg')

show_plot(
  ggplot(mtcars, aes(hp, mpg, colour = factor(cyl))) +
    geom_point() +
    geom_smooth(method = 'lm', se = FALSE),
  .name = 'hp_mpg_by_cyl'
)

show_table(head(mtcars, 10), .name = 'mtcars_head')
```

If `.name` is omitted, an ordinal name (`plot_001`, `plot_002`, …) is
generated.

### Navigation

| Function                  | Purpose                                |
| ------------------------- | -------------------------------------- |
| `show_history(type)`      | List history (filter by `'plot'`/`'table'`) |
| `show_prev()`             | Step backward in history               |
| `show_next()`             | Step forward in history                |
| `show_goto(name_or_id)`   | Jump to entry by name or numeric ID    |
| `show_search(pattern)`    | Substring search of names + code       |

### Export and zoom

| Function                  | Purpose                                |
| ------------------------- | -------------------------------------- |
| `show_zoom()`             | Open the master PDF in the system viewer |
| `show_save(filename)`     | Save current entry; `.pdf`/`.png` honoured |
| `graph_include(path)`     | Embed a saved graphic into an Rmd/qmd  |

### Configuration

```r
# Width and height in inches; png_scale in dpi
set_plot_size(width = 6, height = 4.5, png_scale = 150)
```

Defaults are 6 in by 4.5 in at 150 dpi, producing a roughly
900x675 px PNG preview and a vector PDF of the same dimensions.

## Vim-side commands and mappings

### Mappings (from any R, Rmd, or qmd buffer)

| Mapping            | Action                                      |
| ------------------ | ------------------------------------------- |
| `<LocalLeader>P`   | Open the Plot HUD                           |
| `<LocalLeader>]`   | Zoom: open the master PDF                   |
| `<LocalLeader><`   | Previous plot in history                    |
| `<LocalLeader>>`   | Next plot in history                        |

### Ex commands

| Command              | Description                                    |
| -------------------- | ---------------------------------------------- |
| `:RPlotShow`         | Force-display the current plot in the pane    |
| `:RPlotZoom`         | Open the master PDF in the system viewer      |
| `:RPlotPrev`         | Previous plot                                 |
| `:RPlotNext`         | Next plot                                     |
| `:RPlotHistory`      | Print the history listing                     |
| `:RPlotHUD`          | Open the Plot HUD (alias `:RPlotGallery`)     |
| `:RPlotSavePdf`      | Save current plot as PDF (prompts for path)   |
| `:RPlotSavePng`      | Save current plot as PNG (prompts for path)   |
| `:RPlotWatchStart`   | Start the signal-file watcher                 |
| `:RPlotWatchStop`    | Stop the watcher                              |
| `:RPlotDebug`        | Show watcher state (signal mtime, pane state) |

The watcher starts automatically when the first R terminal opens.
`:RPlotWatchStart`/`:RPlotWatchStop` are present for debugging.

## The plot pane

The plot pane is a separate Kitty (or compatible) window split off the
current view, titled `zzvim-plot`. It displays whichever PNG is at
`.graphics/current.png` and refreshes when the signal file's mtime
changes. Pressing `<CR>` inside the pane closes it; closing the
associated R terminal also closes the pane.

The pane is opened lazily on first plot. iTerm2 users see plots via
`imgcat` directly in the R terminal pane.

## The Plot HUD

`<LocalLeader>P` opens a numbered list of all plots in the current
session's history:

```
Plot History                                              [HUD]
====================================================================
Enter=display | z=zoom PDF | s=save | d=delete | q=close | /=search

  #   Name                 Created              Code
----------------------------------------------------------------------
> [1] wt_mpg               2026-04-30T14:30     show_plot(plot(mpg ~ wt...
  [2] hp_mpg_by_cyl        2026-04-30T14:31     show_plot(ggplot(mtcars...
  [3] mtcars_head          2026-04-30T14:32     show_table(head(mtcars...
```

Buffer-local mappings inside the HUD:

| Key       | Action                                         |
| --------- | ---------------------------------------------- |
| `j` / `k` | Move cursor down / up                          |
| `1`-`9`   | Jump to entry N                                |
| `<CR>`    | Display the selected entry in the graphics pane|
| `z`       | Open the master PDF                            |
| `s`       | Save (prompt for path; `.pdf`/`.png`)          |
| `d`       | Delete entry from history (with confirmation)  |
| `r`       | Refresh the HUD against the live R session     |
| `/`       | Search by name or code                         |
| `q`       | Close the HUD                                  |

Tables (from `show_table()`) interleave with plots in the same history
and are rendered with the same machinery.

## Persistent history

History entries live under `.graphics/history/` keyed by ordinal:

```
.graphics/
  current.pdf
  current.png
  .signal
  history/
    001_wt_mpg.pdf
    001_wt_mpg.png
    002_hp_mpg_by_cyl.pdf
    002_hp_mpg_by_cyl.png
    003_mtcars_head.pdf
    003_mtcars_head.png
    index.json
```

The `index.json` manifest records each entry's name, type, code, and
timestamp. The directory is project-local: history is per-project and
survives R restarts.

## Workflow examples

### Exploratory analysis

```r
library(ggplot2)
show(plot(rnorm(1000), rnorm(1000), pch = 20))
show(hist(rgamma(1000, 2)))
show(ggplot(iris, aes(Sepal.Length, Petal.Length, colour = Species)) +
       geom_point())
```

Press `<LocalLeader>P` to browse, `<LocalLeader>]` on the one worth
keeping for full-resolution review.

### Including a saved plot in a report

In an Rmd or qmd chunk:

```r
graph_include('.graphics/history/002_hp_mpg_by_cyl.pdf', out.width = '80%')
```

`graph_include()` resolves both PDF (preferred for LaTeX targets) and
PNG (for HTML targets) automatically based on the rendering format.

### Higher-resolution plots for presentation

```r
set_plot_size(width = 10, height = 7, png_scale = 200)
show_plot(my_plot, .name = 'final_for_slides')
```

Subsequent plots use the new dimensions until `set_plot_size()` is
called again or R restarts.

## Configuration variables (Vim side)

```vim
" The plugin's defaults are usually correct; override only if needed.
let g:zzvim_r_plot_location = 'vsplit'  " 'vsplit', 'hsplit', 'tab'
```

The R-side dimensions are configured with `set_plot_size()` in R,
not via `g:` variables.

## Statusline integration

```vim
set statusline+=%{ZzvimRPlotStatus()}
```

Displays `[Plot 3/7]` while a session has plots in history; empty
otherwise.

## Troubleshooting

### The plot pane never appears

1. Confirm Kitty remote control is enabled:
   ```
   kitty @ ls
   ```
   If this fails, add `allow_remote_control yes` to `kitty.conf` and
   restart.
2. Confirm the signal file is being written:
   ```
   ls -la .graphics/.signal
   ```
3. `:RPlotDebug` reports the watcher's view of mtime and pane state.

### The pane opens but the image is blank or stale

1. Verify R can write to `.graphics/`:
   ```r
   file.access('.graphics', 2)  # 0 = OK
   ```
2. Inspect `.graphics/current.png` with `file` to confirm it is a
   valid PNG.
3. `:RPlotWatchStop` then `:RPlotWatchStart` resets the watcher.

### `.Rprofile.local` is older than the plugin expects

When the template version on disk is older than the bundled version,
the plugin prompts on R-file open. Accepting the upgrade backs up the
existing file as `.Rprofile.local.backup.YYYYMMDDHHMMSS`.

### iTerm2: no zoom

`imgcat`-based rendering does not have a remote-control pane, so
`<LocalLeader>]` opens the master PDF in the macOS system viewer
instead. The HUD still works, but the inline pane is replaced by
inline output in the R terminal itself.

## Related

- `docs/terminal-graphics.md` - terminal detection and `.Rprofile.local`
  setup
- `docs/hud-guide.md` - the broader HUD system that the Plot HUD is
  part of
- `:help zzvim-r-design` - rationale for the wrapper-based plot API
- `:help zzvim-r-mappings` - canonical mapping reference
