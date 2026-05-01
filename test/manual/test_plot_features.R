# =============================================================================
# Test Script: Terminal Graphics Plot Management Features
# =============================================================================
# This script exercises all plot management functions from .Rprofile.local
# Run inside a Kitty terminal with zzvim-R loaded
#
# Prerequisites:
#   - Kitty terminal with allow_remote_control enabled
#   - jsonlite package (for persistent history)
#   - ImageMagick (for thumbnails, optional)
#
# Usage:
#   1. Open this file in Vim with zzvim-R loaded
#   2. Start R terminal with <LocalLeader>r
#   3. Send each section to R and verify behavior
#
# Quick reference (shown at R startup):
#   zzplot(...)                : Base R plots (renders both sizes)
#   zzggplot(p)                : ggplot2 plots (renders both sizes)
#   plot_zoom()                : Open hi-res in Preview
#   plot_zoom_kitty()          : Open hi-res in Kitty window
#   plot_history()             : View plot history
#   plot_prev() / plot_next()  : Navigate history
#   save_plot(file)            : Save current plot as PNG
#   plot_to_pdf(file)          : Save current plot as PDF
#   set_plot_size(sw,sh,lw,lh) : Set small/large dimensions
#   set_plot_mode(m)           : Display mode (pane/inline/auto)
#   close_plot_pane()          : Close the plot pane
#   plot_split(scale)          : Display in split pane
#   plot_redisplay_if_resized(): Redisplay after terminal resize
#   plot_window_toggle()       : Toggle window mode (main + 2x4 grid)
#   plot_window_select(n)      : Select plot 1-8 from grid
# =============================================================================


# -----------------------------------------------------------------------------
# SECTION 1: Basic Setup Verification
# -----------------------------------------------------------------------------
# Expected: Startup message shows terminal type and dual-resolution info

cat("\n=== Section 1: Setup Verification ===\n")
cat("Terminal type:", .terminal, "\n")
cat("jsonlite available:", exists(".jsonlite_available") &&
    get(".jsonlite_available", envir = .GlobalEnv), "\n")
cat("Plot dimensions (small):", .plot_width_small, "x", .plot_height_small, "\n")
cat("Plot dimensions (large):", .plot_width_large, "x", .plot_height_large, "\n")
cat("Display mode:", .plot_display_mode, "\n")


# -----------------------------------------------------------------------------
# SECTION 2: zzplot() - Base R Plots
# -----------------------------------------------------------------------------
# Expected: Plot appears in pane, dual resolution files created

cat("\n=== Section 2: zzplot() ===\n")
zzplot(100:50, main = "Test Plot 1: Basic Scatter")

# Verify files exist
cat("Small plot exists:", file.exists(.plot_file), "\n")
cat("Hi-res plot exists:", file.exists(.plot_file_hires), "\n")


# -----------------------------------------------------------------------------
# SECTION 3: zzggplot() - ggplot2 Plots
# -----------------------------------------------------------------------------
# Expected: ggplot appears in pane with dual resolution

cat("\n=== Section 3: zzggplot() ===\n")
if (requireNamespace("ggplot2", quietly = TRUE)) {
  library(ggplot2)
  p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
    geom_point() +
    ggtitle("Test Plot 2: ggplot2 Scatter")
  zzggplot(p)
} else {
  cat("ggplot2 not installed, skipping\n")
}


# -----------------------------------------------------------------------------
# SECTION 4: Named Plots for History
# -----------------------------------------------------------------------------
# Expected: Plots saved to persistent history with custom names

cat("\n=== Section 4: Named Plots ===\n")
zzplot(sin(seq(0, 2 * pi, length.out = 100)), type = "l",
       main = "Sine Wave", .name = "sine_wave")

zzplot(cos(seq(0, 2 * pi, length.out = 100)), type = "l",
       main = "Cosine Wave", .name = "cosine_wave")

zzplot(rnorm(100), type = "h", main = "Random Histogram",
       .name = "random_hist")

cat("Created 3 named plots\n")


# -----------------------------------------------------------------------------
# SECTION 5: plot_history() - View Plot History
# -----------------------------------------------------------------------------
# Expected: Lists all plots with IDs, names, and timestamps

cat("\n=== Section 5: plot_history() ===\n")
plot_history()


# -----------------------------------------------------------------------------
# SECTION 6: plot_prev() / plot_next() - Navigate History
# -----------------------------------------------------------------------------
# Expected: Navigate through plots, pane updates to show selected plot

cat("\n=== Section 6: plot_prev() / plot_next() ===\n")
cat("Navigating to previous plot...\n")
plot_prev()
Sys.sleep(0.5)

cat("\nNavigating to next plot...\n")
plot_next()
Sys.sleep(0.5)

cat("\nNavigating back two plots...\n")
plot_prev()
Sys.sleep(0.3)
plot_prev()


# -----------------------------------------------------------------------------
# SECTION 7: plot_zoom() - Open Hi-Res in Preview
# -----------------------------------------------------------------------------
# Expected: Opens hi-res version in macOS Preview app

cat("\n=== Section 7: plot_zoom() ===\n")
zzplot(density(rnorm(1000)), main = "Density Plot for Zoom Test")
cat("Opening hi-res plot in Preview...\n")
plot_zoom()


# -----------------------------------------------------------------------------
# SECTION 8: plot_zoom_kitty() - Open Hi-Res in Kitty Window
# -----------------------------------------------------------------------------
# Expected: Opens hi-res version in new Kitty terminal window

cat("\n=== Section 8: plot_zoom_kitty() ===\n")
cat("Opening hi-res plot in Kitty window...\n")
cat("(Close window manually when done viewing)\n")
plot_zoom_kitty()


# -----------------------------------------------------------------------------
# SECTION 9: save_plot() - Save Current Plot as PNG
# -----------------------------------------------------------------------------
# Expected: Plot saved to specified file path

cat("\n=== Section 9: save_plot() ===\n")
zzplot(1:20, main = "Plot to Save", .name = "save_test")
save_plot("/tmp/test_saved_plot.png")
cat("Saved to /tmp/test_saved_plot.png\n")
cat("File exists:", file.exists("/tmp/test_saved_plot.png"), "\n")
cat("File size:", file.info("/tmp/test_saved_plot.png")$size, "bytes\n")


# -----------------------------------------------------------------------------
# SECTION 10: plot_to_pdf() - Save Current Plot as PDF
# -----------------------------------------------------------------------------
# Expected: Plot converted to PDF format (requires 'png' package)

cat("\n=== Section 10: plot_to_pdf() ===\n")
zzplot(1:20, main = "Plot for PDF Export", .name = "pdf_test")
plot_to_pdf("/tmp/test_saved_plot.pdf")
cat("File exists:", file.exists("/tmp/test_saved_plot.pdf"), "\n")
cat("File size:", file.info("/tmp/test_saved_plot.pdf")$size, "bytes\n")


# -----------------------------------------------------------------------------
# SECTION 11: set_plot_size() - Set Plot Dimensions
# -----------------------------------------------------------------------------
# Expected: Changes plot dimensions for subsequent plots

cat("\n=== Section 11: set_plot_size() ===\n")
cat("Current dimensions - small:", .plot_width_small, "x", .plot_height_small,
    " large:", .plot_width_large, "x", .plot_height_large, "\n")

# Change to custom size
set_plot_size(400, 300, 1000, 750)
cat("After set_plot_size(400, 300, 1000, 750):\n")
cat("  Small:", .plot_width_small, "x", .plot_height_small, "\n")
cat("  Large:", .plot_width_large, "x", .plot_height_large, "\n")

zzplot(1:10, main = "Custom Size Plot (400x300)")

# Reset to defaults
set_plot_size(600, 450, 1200, 900)
cat("Reset to defaults (600x450, 1200x900)\n")


# -----------------------------------------------------------------------------
# SECTION 12: set_plot_mode() - Display Mode
# -----------------------------------------------------------------------------
# Expected: Switches between pane/inline/auto display modes

cat("\n=== Section 12: set_plot_mode() ===\n")
cat("Current mode:", .plot_display_mode, "\n")

# Test pane mode (default)
set_plot_mode("pane")
cat("Set to 'pane' mode\n")
zzplot(1:5, main = "Pane Mode Plot")
Sys.sleep(0.5)

# Test inline mode (plots in terminal)
set_plot_mode("inline")
cat("Set to 'inline' mode\n")
zzplot(1:5, main = "Inline Mode Plot")
Sys.sleep(0.5)

# Test auto mode
set_plot_mode("auto")
cat("Set to 'auto' mode\n")
zzplot(1:5, main = "Auto Mode Plot")

# Return to pane mode
set_plot_mode("pane")
cat("Returned to 'pane' mode\n")


# -----------------------------------------------------------------------------
# SECTION 13: close_plot_pane() - Close the Plot Pane
# -----------------------------------------------------------------------------
# Expected: Closes the Kitty plot pane

cat("\n=== Section 13: close_plot_pane() ===\n")
cat("Closing plot pane...\n")
close_plot_pane()
Sys.sleep(1)

cat("Pane closed. Creating new plot to reopen...\n")
zzplot(1:10, main = "Plot After Pane Close")


# -----------------------------------------------------------------------------
# SECTION 14: plot_split() - Display in Split Pane
# -----------------------------------------------------------------------------
# Expected: Opens plot in a vertical split pane in Kitty
# Use Ctrl+Shift+] to focus plot pane, Ctrl+Shift+[ to return

cat("\n=== Section 14: plot_split() ===\n")
zzplot(1:30, main = "Plot for Split View", .name = "split_test")
cat("Opening plot in split pane...\n")
plot_split()

cat("\nTesting scaled split (1.5x)...\n")
Sys.sleep(1)
plot_split(scale = 1.5)


# -----------------------------------------------------------------------------
# SECTION 15: plot_redisplay_if_resized() - Redisplay After Resize
# -----------------------------------------------------------------------------
# Expected: Checks if terminal was resized and redisplays current plot

cat("\n=== Section 15: plot_redisplay_if_resized() ===\n")
zzplot(1:15, main = "Plot for Resize Test", .name = "resize_test")
cat("Current terminal stored. Try resizing your terminal window,\n")
cat("then run plot_redisplay_if_resized() to redisplay.\n")
cat("\nCalling plot_redisplay_if_resized() now (no resize expected):\n")
plot_redisplay_if_resized()


# -----------------------------------------------------------------------------
# SECTION 16: plot_goto() - Navigate by ID or Name
# -----------------------------------------------------------------------------
# Expected: Displays specific plot from history

cat("\n=== Section 16: plot_goto() ===\n")

# By name pattern
cat("Going to 'sine' plot...\n")
plot_goto("sine")
Sys.sleep(0.5)

# By ID (adjust based on your history)
cat("Going to plot ID 1...\n")
plot_goto(1)


# -----------------------------------------------------------------------------
# SECTION 17: plot_search() - Search History
# -----------------------------------------------------------------------------
# Expected: Lists matching plots and displays first match

cat("\n=== Section 17: plot_search() ===\n")
cat("Searching for 'wave'...\n")
plot_search("wave")

cat("\nSearching for 'rnorm'...\n")
plot_search("rnorm")


# -----------------------------------------------------------------------------
# SECTION 18: plot_history_persistent() - Persistent History
# -----------------------------------------------------------------------------
# Expected: Shows all plots saved to disk with names and timestamps

cat("\n=== Section 18: plot_history_persistent() ===\n")
plot_history_persistent()


# -----------------------------------------------------------------------------
# SECTION 19: Additional Configuration
# -----------------------------------------------------------------------------
# Expected: Alignment and relative sizing work correctly

cat("\n=== Section 19: Additional Configuration ===\n")

# Test set_plot_align (if available)
if (exists("set_plot_align")) {
  cat("Current alignment:", .plot_align, "\n")
  set_plot_align("left")
  zzplot(1:5, main = "Left Aligned")
  set_plot_align("center")
  cat("Reset to center alignment\n")
}

# Test set_plot_size_relative (if available)
if (exists("set_plot_size_relative")) {
  cat("\nTesting relative sizing...\n")
  set_plot_size_relative(0.5, 0.6)
  zzplot(1:10, main = "Relative Sized Plot (50% x 60%)")
  # Reset to defaults
  set_plot_size(600, 450, 1200, 900)
}


# -----------------------------------------------------------------------------
# SECTION 20: Vim Integration Commands
# -----------------------------------------------------------------------------
# Run these commands in Vim to test integration:

cat("\n=== Section 20: Vim Commands to Test ===\n")
cat("
In Vim, test these commands:

  :RPlotConfig        - Show current plot configuration
  :RPlotDebug         - Show watcher debug info
  :RPlotGallery       - Open plot gallery buffer
  :RPlotThumbs        - Open thumbnail grid (requires ImageMagick)
  :RPlotShow          - Force display current plot
  :RPlotPreview       - Open in macOS Preview
  :RPlotZoom          - Open hi-res in new Kitty window
  :RPlotZoomPreview   - Open hi-res in Preview
  :RPlotPrev          - Previous plot in R history
  :RPlotNext          - Next plot in R history
  :RPlotReset         - Reset watcher state

Keyboard shortcuts (in R/Rmd/Qmd files):
  <LocalLeader>[      - Open current plot in Preview
  <LocalLeader>]      - Zoom plot in Kitty window
  <LocalLeader><      - Previous plot
  <LocalLeader>>      - Next plot
  <LocalLeader>G      - Open gallery
  <LocalLeader>T      - Open thumbnail grid

Plot family (<LocalLeader>p + action):
  <LocalLeader>pz     - Zoom in Preview
  <LocalLeader>pk     - Zoom in Kitty window
  <LocalLeader>pv     - Split view
  <LocalLeader>pp     - Previous plot
  <LocalLeader>pn     - Next plot
  <LocalLeader>pg     - Goto (prompt for ID/name)
  <LocalLeader>p/     - Search history
  <LocalLeader>ph     - Show history
  <LocalLeader>pH     - Show persistent history
  <LocalLeader>pG     - Gallery buffer
  <LocalLeader>pt     - Thumbnail grid
  <LocalLeader>ps     - Save as PNG
  <LocalLeader>pS     - Save as PDF
  <LocalLeader>pm     - Set mode
  <LocalLeader>pa     - Set alignment
  <LocalLeader>pd     - Set dimensions
  <LocalLeader>pc     - Close pane
  <LocalLeader>pr     - Redisplay
  <LocalLeader>p?     - Show config
  <LocalLeader>pw     - Toggle window mode (main + 2x4 grid)
  <LocalLeader>p1-p8  - Select from thumbnail grid

Gallery/Thumbnail navigation:
  - Press 1-8 to select plot by number
  - Press Enter on a line to select that plot
  - Press q or Esc to close
")


# -----------------------------------------------------------------------------
# SECTION 21: plot_window_toggle() - Window Mode (Main + 2x4 Grid)
# -----------------------------------------------------------------------------
# Expected: Toggles composite display with main plot + 2x4 thumbnail grid

cat("\n=== Section 21: plot_window_toggle() ===\n")
cat("Enabling plot window mode...\n")
plot_window_toggle()

cat("\nCreating plots in window mode (watch the grid update)...\n")
zzplot(1:10, main = "Window Test 1", .name = "window_test_1")
Sys.sleep(0.5)
zzplot(1:20, main = "Window Test 2", .name = "window_test_2")
Sys.sleep(0.5)
zzplot(1:30, main = "Window Test 3", .name = "window_test_3")

cat("\nDisabling window mode...\n")
plot_window_toggle()


# -----------------------------------------------------------------------------
# SECTION 22: plot_window_select() - Select from Thumbnail Grid
# -----------------------------------------------------------------------------
# Expected: Selects plot 1-8 from the thumbnail grid and displays it

cat("\n=== Section 22: plot_window_select() ===\n")
cat("Re-enabling window mode to test selection...\n")
plot_window_toggle()

cat("\nSelecting plot 1 from grid...\n")
plot_window_select(1)
Sys.sleep(0.5)

cat("\nSelecting plot 3 from grid...\n")
plot_window_select(3)
Sys.sleep(0.5)

cat("\nDisabling window mode...\n")
plot_window_toggle()


# -----------------------------------------------------------------------------
# SECTION 23: History Stats
# -----------------------------------------------------------------------------

cat("\n=== Section 23: History Stats ===\n")
cat("Session history limit:", .plot_history_limit, "\n")
cat("Session plot count:", length(.plot_history), "plots\n")

# Check persistent history count
idx <- .read_history_index()
cat("Persistent history count:", length(idx$plots), "plots\n")


# -----------------------------------------------------------------------------
# TEST COMPLETE
# -----------------------------------------------------------------------------

cat("\n")
cat("=" |> rep(60) |> paste(collapse = ""), "\n")
cat("  TEST COMPLETE\n")
cat("=" |> rep(60) |> paste(collapse = ""), "\n")
cat("\n")
cat("Core Functions Tested:\n")
cat("  [_] zzplot()                   - Base R plotting\n")
cat("  [_] zzggplot()                 - ggplot2 plotting\n")
cat("  [_] plot_zoom()                - Open hi-res in Preview\n")
cat("  [_] plot_zoom_kitty()          - Open hi-res in Kitty window\n")
cat("  [_] plot_history()             - View plot history\n")
cat("  [_] plot_prev()                - Navigate to previous plot\n")
cat("  [_] plot_next()                - Navigate to next plot\n")
cat("  [_] save_plot()                - Save current plot as PNG\n")
cat("  [_] plot_to_pdf()              - Save current plot as PDF\n")
cat("  [_] set_plot_size()            - Set small/large dimensions\n")
cat("  [_] set_plot_mode()            - Display mode (pane/inline/auto)\n")
cat("  [_] close_plot_pane()          - Close the plot pane\n")
cat("  [_] plot_split()               - Display in split pane\n")
cat("  [_] plot_redisplay_if_resized() - Redisplay after resize\n")
cat("  [_] plot_window_toggle()       - Toggle window mode (main + grid)\n")
cat("  [_] plot_window_select()       - Select from thumbnail grid\n")
cat("\n")
cat("Additional Functions Tested:\n")
cat("  [_] plot_goto()                - Navigate by ID or name\n")
cat("  [_] plot_search()              - Search history\n")
cat("  [_] plot_history_persistent()  - View persistent history\n")
cat("  [_] set_plot_align()           - Set plot alignment\n")
cat("  [_] set_plot_size_relative()   - Set size as % of terminal\n")
cat("\n")
cat("Environment:\n")
cat("  - Terminal:", .terminal, "\n")
cat("  - Session plots:", length(.plot_history), "\n")
cat("  - Persistent plots:", length(.read_history_index()$plots), "\n")
cat("  - jsonlite:", ifelse(get(".jsonlite_available", envir = .GlobalEnv),
                            "available", "NOT available"), "\n")
cat("\n")
