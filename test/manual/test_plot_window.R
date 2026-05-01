# =============================================================================
# Test Script: Plot Window Mode (Main + 2x4 Thumbnail Grid)
# =============================================================================
# Quick workflow to test the composite plot window feature
# Requires: Kitty terminal, ImageMagick on HOST (not in Docker)
#
# NOTE: Plot window mode is controlled via Vim mappings (not R functions)
#       because ImageMagick runs on the host, not inside Docker.
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
# 2. Enable window mode (USE VIM MAPPING)
# -----------------------------------------------------------------------------
cat("\n--- To enable plot window mode ---\n")
cat("Press <Space>pw in Vim (normal mode) to toggle window mode\n")
cat("This uses host ImageMagick to create composite image\n\n")

# Create more plots after enabling window mode
cat("After enabling window mode, run these plots:\n")


# -----------------------------------------------------------------------------
# 3. Create more plots - grid should update
# -----------------------------------------------------------------------------
zzplot(cars$speed, cars$dist, main = "Plot F: Cars", .name = "plot_f")
Sys.sleep(0.5)

zzplot(density(rnorm(500)), main = "Plot G: Density", .name = "plot_g")
Sys.sleep(0.5)

zzplot(1:30, (1:30)^2, type = "l", main = "Plot H: Quadratic", .name = "plot_h")


# -----------------------------------------------------------------------------
# 4. Select from grid (USE VIM MAPPINGS)
# -----------------------------------------------------------------------------
cat("\n--- To select from grid ---\n")
cat("Press <Space>p1 through <Space>p8 in Vim to select plots\n")
cat("  <Space>p1 - Select oldest plot in grid\n")
cat("  <Space>p8 - Select newest plot in grid\n\n")


# -----------------------------------------------------------------------------
# 5. Test thumbnail gallery
# -----------------------------------------------------------------------------
cat("\n--- To view thumbnail gallery ---\n")
cat("Press <Space>T in Vim to open thumbnail gallery pane\n")
cat("Press 1-8 to select, q to close\n\n")


# -----------------------------------------------------------------------------
# 6. Available Vim mappings for plot window mode
# -----------------------------------------------------------------------------
cat("\n=== Plot Window Mode Vim Mappings ===\n")
cat("  <Space>pw     - Toggle window mode (main + 2x4 grid)\n")
cat("  <Space>p1-p8  - Select plot from grid\n")
cat("  <Space>T      - Open thumbnail gallery pane\n")
cat("  <Space>G      - Open full plot gallery\n\n")


# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
cat("=== Test Script Complete ===\n")
cat("Use Vim mappings above to test plot window features\n")
