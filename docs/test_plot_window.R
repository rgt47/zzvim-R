# =============================================================================
# Test Script: Plot Window Mode (Main + 3x3 Thumbnail Grid)
# =============================================================================
# Quick workflow to test the composite plot window feature
# Requires: Kitty terminal, ImageMagick (convert, montage)
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Create some plots to populate the thumbnail grid
# -----------------------------------------------------------------------------
cat("Creating initial plots for history...\n")

zzplot(1:10, main = "Plot A", .name = "plot_a")
zzplot(sin(1:50 / 5), type = "l", main = "Plot B: Sine", .name = "plot_b")
zzplot(rnorm(100), main = "Plot C: Random", .name = "plot_c")
zzplot(1:20, 20:1, main = "Plot D: Diagonal", .name = "plot_d")
zzplot(cumsum(rnorm(50)), type = "l", main = "Plot E: Walk", .name = "plot_e")

cat("Created 5 plots. Check plot_history():\n")
plot_history()


# -----------------------------------------------------------------------------
# 2. Enable window mode
# -----------------------------------------------------------------------------
cat("\n--- Enabling plot window mode ---\n")
plot_window_toggle()

# New plots should now show composite (main + grid)
cat("\nCreating plots in window mode (watch the grid)...\n")


# -----------------------------------------------------------------------------
# 3. Create more plots - grid should update
# -----------------------------------------------------------------------------
zzplot(cars$speed, cars$dist, main = "Plot F: Cars", .name = "plot_f")
Sys.sleep(0.5)

zzplot(density(rnorm(500)), main = "Plot G: Density", .name = "plot_g")
Sys.sleep(0.5)

zzplot(1:30, (1:30)^2, type = "l", main = "Plot H: Quadratic", .name = "plot_h")


# -----------------------------------------------------------------------------
# 4. Select from grid using plot_window_select()
# -----------------------------------------------------------------------------
cat("\n--- Testing grid selection ---\n")

cat("Selecting plot 1 from grid...\n")
plot_window_select(1)
Sys.sleep(1)

cat("Selecting plot 5 from grid...\n")
plot_window_select(5)
Sys.sleep(1)

cat("Selecting plot 9 from grid...\n")
plot_window_select(9)


# -----------------------------------------------------------------------------
# 5. Toggle off and verify normal mode works
# -----------------------------------------------------------------------------
cat("\n--- Disabling window mode ---\n")
plot_window_toggle()

cat("\nCreating plot in normal mode...\n")
zzplot(1:15, main = "Normal Mode Plot")


# -----------------------------------------------------------------------------
# 6. Toggle back on to verify persistence
# -----------------------------------------------------------------------------
cat("\n--- Re-enabling window mode ---\n")
plot_window_toggle()

cat("\nWindow mode restored. Try Vim mappings:\n")
cat("  <LocalLeader>pw     - Toggle window mode\n")
cat("  <LocalLeader>p1-p9  - Select from grid\n")


# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
cat("\n=== Test Complete ===\n")
cat("Window mode:", ifelse(.plot_window_mode, "ON", "OFF"), "\n")
