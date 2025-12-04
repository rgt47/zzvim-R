# Plot Window Options in zzvim-R

This guide describes the different ways to display R plots in separate windows within Kitty terminal, from inline display to fullscreen viewing.

## Overview

zzvim-R offers multiple approaches for displaying plots, allowing you to choose the workflow that best fits your development style:

| Approach | Display | Maximizable | Use Case |
|----------|---------|-------------|----------|
| **Inline** | Plots appear in terminal where called | Yes | Default workflow, compact |
| **Fullscreen Window** | Separate Kitty window for plots | Yes | Focused plot viewing |
| **Multi-pane Layout** | Plots in dedicated pane | Yes | Side-by-side R and plots |

## Inline Display (Default)

Plots display inline at the current cursor position in your R terminal, using 75% of terminal width and full height by default.

### Usage

```r
# Base R plots with auto-display
zzplot(x = 1:10, y = (1:10)^2)

# ggplot2 plots with auto-display
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
zzggplot(p)
```

### Characteristics

- ✓ Immediate feedback
- ✓ Compact display (doesn't require separate window)
- ✓ Easy to save or navigate history
- ✓ Good for iterative development
- ✗ Limited screen real estate for large plots
- ✗ Scrolls with terminal output

### Configuration

Control inline plot dimensions:

```r
# Relative sizing (responsive to terminal size)
set_plot_size_relative(width_pct = 0.75, height_pct = 1.0)

# Fixed pixel dimensions
set_plot_size(width = 1200, height = 800, res = 96)

# Alignment (Kitty only)
set_plot_align("right")  # left, center, right
```

## Fullscreen Window Display

Open the current plot in a dedicated, fullscreen Kitty window. This is ideal when you want to focus on a specific plot.

### Usage

```r
# Create and display a plot inline
zzplot(1:100, rnorm(100))

# Open that plot in fullscreen
plot_maximize()
```

### Workflow Example

```r
# Create multiple plots
zzplot(1:10, (1:10)^2, main = "Linear")
zzplot(1:10, (1:10)^3, main = "Cubic")
zzplot(1:10, sqrt(1:10), main = "Square Root")

# Navigate through history
plot_prev()
plot_prev()

# Fullscreen the plot you want to focus on
plot_maximize()
```

### Characteristics

- ✓ Dedicated window space
- ✓ Large viewing area
- ✓ Kitty window management controls
- ✓ Can be resized, zoomed, moved
- ✓ Non-blocking (doesn't pause R)
- ✗ Separate window to manage
- ✗ Requires closing or switching windows

### Kitty Window Management

Once `plot_maximize()` opens a fullscreen window:

| Keybinding | Action |
|------------|--------|
| `Ctrl+Shift+Q` | Close window |
| `Ctrl+Shift+]` | Next window |
| `Ctrl+Shift+[` | Previous window |
| `Ctrl+Shift+N` | New window |
| `Ctrl+Shift+W` | Close window (alternative) |

### Example: Side-by-Side Workflow

```r
# Terminal layout: Kitty running R in left pane

# Open a new Kitty window for plots
plot_maximize()

# Now you have:
# - Left: R terminal for commands
# - Right: Plot window

# Switch between them with Ctrl+Shift+]
# Work fluidly between exploring code and viewing results
```

## Plot History with Window Display

Combine plot history navigation with fullscreen viewing:

```r
# Create several plots
for (i in 1:5) {
  zzplot(1:100, rnorm(100, mean = i),
         main = paste("Distribution", i))
}

# Navigate the history
plot_history()        # See all plots
plot_prev()          # Go to previous
plot_next()          # Go to next

# Maximize any plot in history
plot_maximize()
```

## Exporting from Fullscreen Window

After maximizing a plot:

```r
# The current plot (whether viewed inline or maximized) is the same
save_plot("myplot.png")        # Save as PNG
plot_to_pdf("myplot.pdf")      # Save as PDF
```

The plot is still accessible through the plot history regardless of how you viewed it.

## Advanced: Multi-Window Comparison

For comparing multiple plots side-by-side:

```r
# Create plots
p1 <- zzplot(mtcars$wt, mtcars$mpg, main = "Weight vs MPG")
p2 <- zzplot(mtcars$hp, mtcars$mpg, main = "Horsepower vs MPG")

# View each in separate windows
plot_maximize()                    # Shows p2 in fullscreen
# Ctrl+Shift+[ to switch windows
# Run plot_prev() in R terminal to navigate back
plot_prev()
plot_maximize()                    # Shows p1 in fullscreen now
```

This creates multiple plot windows you can navigate between.

## Workflow Recommendations

### Interactive Exploratory Analysis
```r
# Best approach: Inline with occasional maximize
zzplot(data$x, data$y)
# If plot needs closer inspection:
plot_maximize()
```

**Rationale:** Fast iteration with minimal window management, zoom in when needed.

### Publication/Presentation Preparation
```r
# Best approach: Maximize frequently to verify appearance
zzplot(final_data, ...)
plot_maximize()
# Adjust sizing, alignment if needed
set_plot_size_relative(0.8, 1.0)
zzplot(final_data, ...)
plot_maximize()
```

**Rationale:** Fullscreen view shows exactly how plots will appear at full resolution.

### Multi-plot Comparison
```r
# Best approach: Maximize for each plot
zzplot(method_a_results)
plot_maximize()
# Ctrl+Shift+[ to see previous window
plot_prev()
plot_maximize()
# Ctrl+Shift+] to compare side-by-side
```

**Rationale:** Separate windows allow direct visual comparison.

### Long-Running Analysis
```r
# Best approach: Maximize to watch progress plots
# Create monitoring plots periodically
zzplot(intermediate_results)
plot_maximize()
# Keep this window open while analysis runs
# Switch back to R terminal with Ctrl+Shift+[
```

**Rationale:** Monitor progress in dedicated window without cluttering main terminal.

## Terminal Resizing Behavior

When using relative sizing (`set_plot_size_relative()`):

```r
# Inline plots adapt automatically
zzplot(1:100, rnorm(100))

# If you resize terminal:
plot_redisplay_if_resized()  # Redisplay at new size

# Maximized plots don't auto-resize
# But you can manually resize the Kitty window
```

**Note:** Inline plots will rescale when terminal is resized. Maximized plot windows can be resized manually like any Kitty window.

## Limitations and Notes

### Kitty-Specific Features
The `plot_maximize()` function is optimized for Kitty and uses Kitty's windowing system. On other terminals, behavior may differ.

### iTerm2 Support
On iTerm2, `plot_maximize()` opens plots in macOS Preview instead:

```r
plot_maximize()  # Opens in Preview on iTerm2
```

This provides native macOS image viewing but less integration with the terminal workflow.

### Performance
- Inline display: No overhead
- Fullscreen window: Minimal overhead (~50-100ms to launch window)
- Multiple windows: Negligible performance impact

### File Cleanup
Plot temporary PNG files are stored in `/tmp`. They're reused by the next plot unless explicitly saved:

```r
save_plot("myplot.png")      # Persist a plot
plot_to_pdf("myplot.pdf")    # Convert and save
```

## Configuration Reference

### Display Options

```r
# Inline display sizing
set_plot_size(width, height, res)
set_plot_size_relative(width_pct, height_pct)

# Appearance
set_plot_align("left|center|right")  # Kitty only

# Fullscreen display
plot_maximize()

# Refresh
plot_redisplay_if_resized()
```

### Navigation

```r
plot_history()     # List all plots
plot_prev()        # Previous plot
plot_next()        # Next plot
```

### Export

```r
save_plot("file.png")
plot_to_pdf("file.pdf")
```

## Troubleshooting

### `plot_maximize()` not opening window
- Verify Kitty is installed: `which kitty`
- Check Kitty version supports `kitty @ launch`: `kitty --version`
- Confirm `kitty +kitten icat` works: `kitty +kitten icat --help`

### Plot window opened but image not displayed
- Confirm the plot file exists: check `/tmp/plot_*.png`
- Verify terminal supports inline images: `echo $KITTY_WINDOW_ID`

### Window closes immediately
- Plot file may have been deleted
- Try creating a new plot: `zzplot(1:10, 1:10); plot_maximize()`

## See Also

- **Terminal Graphics Setup**: `docs/TERMINAL_GRAPHICS_SETUP.md`
- **Plot Display Design Rationale**: `docs/PLOT_DISPLAY_DESIGN_RATIONALE.md`
- **Kitty Documentation**: https://sw.kovidgoyal.net/kitty/
- **icat Kitten Documentation**: https://sw.kovidgoyal.net/kitty/kittens/icat/
