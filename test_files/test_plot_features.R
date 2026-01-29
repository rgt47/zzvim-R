# =============================================================================
# Test Script: Terminal Graphics Plot Management Features
# =============================================================================
# This script tests all plot management features added in v3-v5
# Run inside a Kitty terminal with zzvim-R loaded
#
# Prerequisites:
#   - Kitty terminal with allow_remote_control enabled
#   - jsonlite package (for persistent history)
#   - ImageMagick (for thumbnails, optional)
#
# Usage:
#   1. Open this file in Vim with zzvim-R loaded
#   2. Start R terminal with <LocalLeader>r or :RDockerTerminal
#   3. Send each section to R and verify behavior
# =============================================================================

# -----------------------------------------------------------------------------
# SECTION 1: Basic Setup Verification
# -----------------------------------------------------------------------------
# Expected: Startup message shows terminal type and dual-resolution info

cat("\n=== Section 1: Setup Verification ===\n")
c,,at("Terminal type:", .terminal, "\n")
cat("jsonlite available:", exists(".jsonlite_available") &&
    get(".jsonlite_available", envir = .GlobalEnv), "\n")
cat("Plot dimensions (small):", .plot_width_small, "x", .plot_height_small, "\n
")
cat("Plot dimensions (large):", .plot_width_large, "x", .plot_height_large, "\n")


# -----------------------------------------------------------------------------
# SECTION 2: Basic Plotting - zzplot()
# -----------------------------------------------------------------------------
# Expected: Plot appears in pane, dual resolution files created

cat("\n=== Section 2: zzplot() Test ===\n")
zzplot(1:10, main = "Test Plot 1: Basic Scatter")

# Verify files exist
cat("Small plot exists:", file.exists(.plot_file), "\n")
cat("Hi-res plot exists:", file.exists(.plot_file_hires), "\n")


# -----------------------------------------------------------------------------
# SECTION 3: ggplot2 Plotting - zzggplot()
# -----------------------------------------------------------------------------
# Expected: ggplot appears in pane with dual resolution

cat("\n=== Section 3: zzggplot() Test ===\n")
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
zzplot(sin(seq(0, 2*pi, length.out = 100)), type = "l",
       main = "Sine Wave", .name = "sine_wave")

zzplot(cos(seq(0, 2*pi, length.out = 100)), type = "l",
       main = "Cosine Wave", .name = "cosine_wave")

zzplot(rnorm(100), type = "h", main = "Random Histogram",
       .name = "random_hist")

cat("Created 3 named plots\n")


# -----------------------------------------------------------------------------
# SECTION 5: Session History Navigation
# -----------------------------------------------------------------------------
# Expected: Navigate through plots created this session

cat("\n=== Section 5: Session History ===\n")
plot_history()

cat("\nNavigating to previous plot...\n")
plot_prev()

cat("\nNavigating to next plot...\n")
plot_next()


# -----------------------------------------------------------------------------
# SECTION 6: Persistent History
# -----------------------------------------------------------------------------
# Expected: Shows all plots saved to disk with names and timestamps

cat("\n=== Section 6: Persistent History ===\n")
plot_history_persistent()


# -----------------------------------------------------------------------------
# SECTION 7: plot_goto() - Navigate by ID or Name
# -----------------------------------------------------------------------------
# Expected: Displays specific plot from history

cat("\n=== Section 7: plot_goto() ===\n")

# By name pattern
cat("Going to 'sine' plot...\n")
plot_goto("sine")

Sys.sleep(1)

# By ID (adjust based on your history)
cat("Going to plot ID 1...\n")
plot_goto(1)


# -----------------------------------------------------------------------------
# SECTION 8: plot_search() - Search History
# -----------------------------------------------------------------------------
# Expected: Lists matching plots by name or code pattern

cat("\n=== Section 8: plot_search() ===\n")
plot_search("wave")
plot_search("rnorm")


# -----------------------------------------------------------------------------
# SECTION 9: Configuration Functions
# -----------------------------------------------------------------------------
# Expected: Size and alignment changes applied

cat("\n=== Section 9: Configuration ===\n")

# Show current config
cat("Current alignment:", .plot_align, "\n")
cat("Current display mode:", .plot_display_mode, "\n")

# Test set_plot_align
set_plot_align("left")
zzplot(1:5, main = "Left Aligned")

set_plot_align("center")


# -----------------------------------------------------------------------------
# SECTION 10: Relative Sizing
# -----------------------------------------------------------------------------
# Expected: Plot size calculated from terminal dimensions

cat("\n=== Section 10: Relative Sizing ===\n")
set_plot_size_relative(0.5, 0.6)
zzplot(1:10, main = "Relative Sized Plot")

# Reset to defaults
set_plot_size(600, 450)


# -----------------------------------------------------------------------------
# SECTION 11: Zoom Functions
# -----------------------------------------------------------------------------
# Expected: Opens hi-res plot in Preview or Kitty window

cat("\n=== Section 11: Zoom ===\n")
zzplot(density(rnorm(1000)), main = "Density Plot for Zoom Test")

cat("Use plot_zoom() to open in Preview\n")
cat("Use plot_zoom_kitty() to open in new Kitty window\n")
# plot_zoom()        # Uncomment to test
# plot_zoom_kitty()  # Uncomment to test


# -----------------------------------------------------------------------------
# SECTION 12: Save Functions
# -----------------------------------------------------------------------------
# Expected: Plot saved to specified file

cat("\n=== Section 12: Save Plot ===\n")
zzplot(1:20, main = "Plot to Save")
save_plot("/tmp/test_saved_plot.png")
cat("Saved to /tmp/test_saved_plot.png\n")
cat("File exists:", file.exists("/tmp/test_saved_plot.png"), "\n")


# -----------------------------------------------------------------------------
# SECTION 13: Plot Mode Toggle (Kitty only)
# -----------------------------------------------------------------------------
# Expected: Switches between inline/pane/auto modes

cat("\n=== Section 13: Display Modes ===\n")
if (.terminal == "kitty") {
  cat("Current mode:", .plot_display_mode, "\n")

  # Test pane mode (default)
  set_plot_mode("pane")
  zzplot(1:5, main = "Pane Mode")

  # Close and reopen
  close_plot_pane()
  Sys.sleep(0.5)

  set_plot_mode("pane")
  zzplot(1:5, main = "Pane Mode Reopened")
} else {
  cat("Kitty-specific tests skipped\n")
}


# -----------------------------------------------------------------------------
# SECTION 14: Vim Integration Tests
# -----------------------------------------------------------------------------
# Run these commands in Vim to test integration:

cat("\n=== Section 14: Vim Commands to Test ===\n")
cat("
In Vim, test these commands:

  :RPlotConfig        - Show current plot configuration
  :RPlotDebug         - Show watcher debug info
  :RPlotGallery       - Open plot gallery buffer
  :RPlotShow          - Force display current plot
  :RPlotPreview       - Open in macOS Preview
  :RPlotZoom          - Open hi-res in new Kitty window
  :RPlotZoomPreview   - Open hi-res in Preview
  :RPlotPrev          - Previous plot in R history
  :RPlotNext          - Next plot in R history
  :RPlotReset         - Reset watcher state

Gallery navigation:
  - Press 1-9 to select plot by number

  - Press Enter on a line to select that plot
  - Press q or Esc to close gallery
")


# -----------------------------------------------------------------------------
# SECTION 15: Cleanup Test
# -----------------------------------------------------------------------------

cat("\n=== Section 15: History Limit Test ===\n")
cat("Current history limit:", .plot_history_limit, "\n")
cat("Current plot count:", length(.plot_history), "session plots\n")

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
cat("Summary:\n")
cat("  - Terminal:", .terminal, "\n")
cat("  - Session plots:", length(.plot_history), "\n")
cat("  - Persistent plots:", length(.read_history_index()$plots), "\n")
cat("  - jsonlite:", ifelse(get(".jsonlite_available", envir = .GlobalEnv),
                            "available", "NOT available"), "\n")
cat("\n")
cat("Check the following:\n")
cat("  [_] Plots displayed in pane correctly\n")
cat("  [_] Gallery shows all plots (:RPlotGallery)\n")
cat("  [_] plot_goto() navigates correctly\n")
cat("  [_] plot_search() finds matching plots\n")
cat("  [_] Zoom functions work (plot_zoom, plot_zoom_kitty)\n")
cat("  [_] Saved plot exists at /tmp/test_saved_plot.png\n")
cat("  [_] Pane closes and reopens correctly\n")
cat("\n")
