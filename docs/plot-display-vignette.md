# zzvim-R Plot Display System: A Comprehensive Vignette

## Introduction

The zzvim-R plugin provides a sophisticated inline plot display system for R
development in terminal environments. This vignette walks through all plot
display features, from basic usage to advanced configuration.

**Key Innovation**: The dual-resolution plot system renders each plot at two
sizes simultaneously - a compact version for the terminal pane and a
high-resolution version for zoom and export. This eliminates scaling artifacts
and ensures crisp display at all viewing sizes.

## Prerequisites

### Supported Terminals

The plot display system supports terminals with inline image capabilities:

| Terminal | Protocol | Status |
|----------|----------|--------|
| Kitty | Kitty Graphics Protocol | Full support |
| Ghostty | Kitty Graphics Protocol | Full support |
| WezTerm | Kitty Graphics Protocol | Full support |
| iTerm2 | imgcat | Basic support |

### Kitty Configuration

For full functionality with Kitty terminal, enable remote control in
`~/.config/kitty/kitty.conf`:

```
allow_remote_control yes
```

Restart Kitty after making this change.

## Getting Started

### Launching R with Plot Support

From Vim, open any R file and launch the Docker R terminal:

```vim
" Open an R file
:edit analysis.R

" Launch Docker R terminal (any of these work)
ZR
" or
<Space>r
" or
:RDockerTerminal
```

When R starts, you'll see the terminal graphics confirmation:

```
✓ Terminal graphics enabled (KITTY)
  Dual-resolution: pane (600x450) + zoom (1800x1350)

Quick reference:
  zzplot(...)                : Base R plots (renders both sizes)
  zzggplot(p)                : ggplot2 plots (renders both sizes)
  plot_zoom()                : Open hi-res in Preview
  ...
```

## Basic Plot Functions

### `zzplot()` - Base R Plots

The `zzplot()` function wraps base R's `plot()` with automatic dual-resolution
rendering and display.

```r
# Simple scatter plot
zzplot(1:10, (1:10)^2)

# With labels and title
zzplot(mtcars$wt, mtcars$mpg,
       xlab = "Weight (1000 lbs)",
       ylab = "Miles per Gallon",
       main = "MPG vs Weight")

# Multiple series
zzplot(1:100, sin(1:100 / 10), type = "l", col = "blue")
```

**What happens internally:**

1. R renders the plot at 600x450 pixels (pane size)
2. R renders the same plot at 1800x1350 pixels (zoom size)
3. The small version is copied to `.plots/current.png`
4. The large version is copied to `.plots/current_hires.png`
5. A signal file `.plots/.signal` is touched
6. Vim detects the signal (within 100ms) and displays the plot

### `zzggplot()` - ggplot2 Plots

For ggplot2 objects, use `zzggplot()`:

```r
library(ggplot2)

# Create a ggplot object
p <- ggplot(mtcars, aes(x = wt, y = mpg, color = factor(cyl))) +
  geom_point(size = 3) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(title = "MPG vs Weight by Cylinder Count",
       x = "Weight (1000 lbs)",
       y = "Miles per Gallon",
       color = "Cylinders") +
  theme_minimal()

# Display with dual-resolution
zzggplot(p)
```

## Plot Pane Interaction

### Pane Location

Plots appear in a dedicated Kitty pane to the right of the R terminal. The pane
is titled `zzvim-plot` for identification.

```
┌─────────────────────┬─────────────────────┐
│                     │                     │
│     Vim Editor      │     R Terminal      │
│                     │                     │
│                     ├─────────────────────┤
│                     │                     │
│                     │    Plot Pane        │
│                     │    (zzvim-plot)     │
│                     │                     │
└─────────────────────┴─────────────────────┘
```

### Pane Controls

The plot pane displays helpful information:

```
Plot 600x450 | <Space>] zoom | Enter to close
```

| Action | Effect |
|--------|--------|
| Press Enter | Close the plot pane |
| `<Space>]` in Vim | Open hi-res version in new window |
| `<Space>[` in Vim | Open plot in macOS Preview |

### Automatic Cleanup

The plot pane closes automatically when:

- You close the R terminal buffer
- R exits (e.g., `q()`)
- You manually press Enter in the pane

## Zoom and Export

### Vim Zoom Commands

| Mapping | Command | Description |
|---------|---------|-------------|
| `<Space>]` | `:RPlotZoom` | Open hi-res (1800x1350) in new Kitty window |
| `<Space>[` | `:RPlotPreview` | Open in macOS Preview |
| - | `:RPlotZoomPreview` | Open hi-res in macOS Preview |

**Example workflow:**

```r
# Create a detailed plot
zzplot(rnorm(1000), rnorm(1000), pch = 20, col = rgb(0, 0, 1, 0.3))
```

In Vim, press `<Space>]` to see the 1800x1350 version in a separate Kitty
window. This is ideal for:

- Checking fine details
- Presentations
- Screenshots for documentation

### R-side Zoom Functions

From the R console:

```r
# Open hi-res in macOS Preview
plot_zoom()

# Open hi-res in new Kitty window
plot_zoom_kitty()
```

**Note:** In Docker mode, `plot_zoom()` instructs you to use `:RPlotZoom` in
Vim since the Docker container cannot access macOS applications directly.

### Saving Plots

```r
# Save current plot as PNG (uses small version by default)
save_plot("my_analysis.png")

# Save as PDF
plot_to_pdf("my_analysis.pdf")
```

For publication-quality output, the hi-res version is at:
`.plots/current_hires.png`

## Plot History

### Navigation Functions

Every plot you create is stored in history:

```r
# Create several plots
zzplot(1:10, (1:10)^1, main = "Linear")
zzplot(1:10, (1:10)^2, main = "Quadratic")
zzplot(1:10, (1:10)^3, main = "Cubic")

# View history
plot_history()
# Output:
# Plot history: 3 plots
# Current: Plot 3
#
#   [1] /tmp/plot_abc123.png
#   [2] /tmp/plot_def456.png
# * [3] /tmp/plot_ghi789.png

# Navigate backward
plot_prev()
# Plot 2 of 3

plot_prev()
# Plot 1 of 3

# Navigate forward
plot_next()
# Plot 2 of 3
```

### History Scope

Plot history is maintained per R session. When R exits, the history is cleared.
Use `save_plot()` to persist important plots before exiting.

## Configuration

### Plot Dimensions

The dual-resolution system uses two size sets:

| Size | Default | Purpose |
|------|---------|---------|
| Small | 600x450 | Pane display |
| Large | 1800x1350 | Zoom/export |

Customize with `set_plot_size()`:

```r
# Change both sizes (large defaults to 3x small)
set_plot_size(small_width = 800, small_height = 600)
# Plot sizes: pane 800x600, zoom 2400x1800 @ 96dpi

# Specify all dimensions explicitly
set_plot_size(small_width = 640, small_height = 480,
              large_width = 1920, large_height = 1440,
              res = 144)
# Plot sizes: pane 640x480, zoom 1920x1440 @ 144dpi
```

### Display Mode

Control how plots are displayed in Kitty:

```r
# Check current mode
get(".plot_display_mode", envir = .GlobalEnv)

# Set display mode
set_plot_mode("pane")    # Dedicated plot pane (default, recommended)
set_plot_mode("inline")  # Display in R terminal itself
set_plot_mode("auto")    # Try inline, fall back to pane
```

**Mode comparison:**

| Mode | Behavior | Best for |
|------|----------|----------|
| `pane` | Dedicated reusable pane | Most workflows |
| `inline` | Plots appear in R terminal | Quick inspection |
| `auto` | Inline with pane fallback | Mixed environments |

### Plot Alignment

For inline display mode:

```r
set_plot_align("right")   # Default
set_plot_align("center")
set_plot_align("left")
```

### Managing the Plot Pane

```r
# Manually close the plot pane
close_plot_pane()
```

## Vim Commands Reference

### Ex Commands

| Command | Description |
|---------|-------------|
| `:RPlotShow` | Force display current plot |
| `:RPlotPreview` | Open plot in macOS Preview |
| `:RPlotZoom` | Open hi-res in new Kitty window |
| `:RPlotZoomPreview` | Open hi-res in macOS Preview |
| `:RPlotWatchStart` | Start plot watcher (auto-started) |
| `:RPlotWatchStop` | Stop plot watcher |
| `:RPlotDebug` | Show debug information |

### Key Mappings

| Mapping | Description |
|---------|-------------|
| `<Space>[` | Open plot in macOS Preview |
| `<Space>]` | Open hi-res in new Kitty window |

### Debug Information

When troubleshooting, use `:RPlotDebug`:

```
=== Plot Watcher Debug ===
Signal file: /path/to/project/.plots/.signal
  Exists: 1
  Mtime: 1706428800
  Cached mtime: 1706428800

Plot file (small): /path/to/project/.plots/current.png
  Exists: 1
  Mtime: 1706428799

Plot file (hi-res): /path/to/project/.plots/current_hires.png
  Exists: 1
  Mtime: 1706428799

Plot pane exists: 1
```

## R Functions Reference

### Plot Creation

| Function | Description |
|----------|-------------|
| `zzplot(...)` | Base R plot with auto-display |
| `zzggplot(p)` | ggplot2 plot with auto-display |

### Navigation

| Function | Description |
|----------|-------------|
| `plot_history()` | Show all plots in history |
| `plot_prev()` | Go to previous plot |
| `plot_next()` | Go to next plot |

### Zoom & Export

| Function | Description |
|----------|-------------|
| `plot_zoom()` | Open hi-res in Preview |
| `plot_zoom_kitty()` | Open hi-res in Kitty window |
| `save_plot(file)` | Save current plot as PNG |
| `plot_to_pdf(file)` | Save current plot as PDF |

### Configuration

| Function | Description |
|----------|-------------|
| `set_plot_size(sw, sh, lw, lh, res)` | Set plot dimensions |
| `set_plot_mode(mode)` | Set display mode |
| `set_plot_align(align)` | Set alignment (Kitty only) |
| `close_plot_pane()` | Close the plot pane |

## Architecture Overview

### File Structure

When plots are created in Docker mode:

```
project/
├── .plots/
│   ├── current.png        # Small version (600x450)
│   ├── current_hires.png  # Large version (1800x1350)
│   └── .signal            # Timestamp file for Vim watcher
├── .Rprofile.local        # Terminal graphics configuration
└── ...
```

### Signal-Based Detection

The plot watcher uses a lightweight signal file approach:

1. **R creates plot** → writes PNG files + touches `.signal`
2. **Vim polls `.signal`** → 100ms interval, tiny file
3. **Mtime changed?** → display new plot
4. **No change** → continue polling

This is faster than polling the PNG file directly because:

- Signal file is ~30 bytes vs PNG at ~50-200KB
- Mtime check is filesystem metadata only
- 100ms polling provides near-instant response

### Template Versioning

The `.Rprofile.local` template includes version tracking:

```r
# zzvim-R template version: 2
```

When you open an R file, zzvim-R checks if your local copy is outdated:

```
.Rprofile.local is outdated (v0 -> v2). Update for dual-resolution plots? [y/N]:
```

If you accept, your old file is backed up as
`.Rprofile.local.backup.YYYYMMDDHHMMSS`.

## Troubleshooting

### Plot pane doesn't appear

1. Check Kitty remote control is enabled:
   ```bash
   kitty @ ls
   ```
   If this fails, add `allow_remote_control yes` to `kitty.conf`.

2. Check plot files exist:
   ```bash
   ls -la .plots/
   ```

3. Run `:RPlotDebug` in Vim to see watcher status.

### Plot appears but is blank or corrupted

1. Check R can write to `.plots/`:
   ```r
   file.access(".plots", 2)  # Should return 0
   ```

2. Verify PNG files are valid:
   ```bash
   file .plots/current.png
   ```

### Plots not updating

1. Check signal file is being touched:
   ```bash
   ls -la .plots/.signal
   ```

2. Restart the watcher:
   ```vim
   :RPlotWatchStop
   :RPlotWatchStart
   ```

### Old plot displays on R startup

This was fixed in v1.1. The watcher now initializes its mtime cache from
existing files, so stale plots don't display on startup. If this still occurs:

1. Delete `.plots/` directory
2. Restart R

## Best Practices

### For Interactive Analysis

```r
# Quick exploratory plots
zzplot(data$x, data$y)

# Navigate history to compare
plot_prev()
plot_next()

# Zoom when you find something interesting
# (press <Space>] in Vim)
```

### For Presentations

```r
# Set larger dimensions for projection
set_plot_size(800, 600, 2400, 1800, res = 144)

# Create publication-quality plot
zzggplot(my_final_plot)

# Use zoom view for presentation
# (press <Space>] in Vim)
```

### For Reports

```r
# Create plot
zzggplot(analysis_plot)

# Save hi-res version
file.copy(".plots/current_hires.png", "figures/figure1.png")

# Or convert to PDF
plot_to_pdf("figures/figure1.pdf")
```

## Version History

| Version | Date | Changes |
|---------|------|---------|
| v2 | Jan 2026 | Dual-resolution plots, signal-based watcher |
| v1 | Aug 2025 | Initial release, single-resolution |

## See Also

- `docs/terminal-graphics-setup.md` - Initial setup guide
- `docs/plot-window-options.md` - Window management options
- `CLAUDE.md` - Developer documentation
- `CHANGELOG.md` - Full version history
