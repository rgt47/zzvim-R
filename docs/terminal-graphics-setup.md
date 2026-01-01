# Terminal Graphics Setup for zzvim-R

## Overview

zzvim-R automatically sets up R plot display in modern terminal emulators:
- **Kitty** - Full support with alignment control (Linux, macOS)
- **Ghostty** - Full support via Kitty graphics protocol (Linux, macOS)
- **WezTerm** - Full support via Kitty graphics protocol (Linux, macOS, Windows)
- **iTerm2** - Full support via imgcat (macOS only)
- Other terminals - Gracefully degrades without errors

Plots display inline in your terminal during R development, eliminating the need for separate plot windows.

## How It Works

When you open vim in a supported terminal within an R project:

1. **Automatic Detection** - zzvim-R detects which terminal emulator is running
2. **Project Detection** - Checks if you're in an R project (has `.Rprofile` or `DESCRIPTION`)
3. **Setup** - Creates `.Rprofile.local` with terminal-specific graphics configuration
4. **Launch R** - When you run R in zzvim-R terminal, plots display automatically

## Features

### Plot Display
```r
zzplot(1:10, (1:10)^2)         # Base R plots with auto-display
zzggplot(p)                     # ggplot2 plots with auto-display
```

### Plot History
```r
plot_history()                  # View all plots in session
plot_prev()                     # Show previous plot
plot_next()                     # Show next plot
```

### Export
```r
save_plot("myplot.png")        # Save as PNG
plot_to_pdf("myplot.pdf")      # Save as PDF
```

### Configuration
```r
set_plot_size(1200, 800)       # Fixed dimensions
set_plot_size_relative()        # Auto-size to terminal (40% x 75% by default)
set_plot_align("left")          # Kitty only: left/center/right
plot_redisplay_if_resized()    # Redisplay after terminal resize
```

## Architecture

### File Structure
```
zzvim-R/
├── plugin/zzvim-R.vim              # Main plugin - calls terminal graphics init
├── autoload/zzvimr/
│   └── terminal_graphics.vim        # Terminal detection and setup module
└── templates/
    └── .Rprofile.local             # Terminal graphics configuration template
```

### Workflow

1. **Plugin Load** (`plugin/zzvim-R.vim`)
   - Calls `zzvimr#terminal_graphics#init()` on startup

2. **Terminal Detection** (`autoload/zzvimr/terminal_graphics.vim`)
   - Checks `KITTY_WINDOW_ID` environment variable
   - Checks `ITERM_SESSION_ID` or `TERM_PROGRAM`
   - Returns terminal type or 'none'

3. **Project Detection**
   - Checks for `.Rprofile` or `DESCRIPTION` file
   - Only proceeds if in an R project

4. **Setup**
   - Copies template `.Rprofile.local` to project root
   - Adds to `.gitignore` if needed
   - No modification to tracked `.Rprofile`

5. **R Session**
   - R's `.Rprofile` sources `.Rprofile.local` (already configured in zzcollab)
   - Graphics functions are available immediately

## Integration with zzcollab

zzcollab projects already source `.Rprofile.local` automatically:

```r
# In zzcollab's .Rprofile (lines 183-190):
if (file.exists(".Rprofile.local")) {
  tryCatch(
    source(".Rprofile.local"),
    error = function(e) {
      warning(".Rprofile.local failed to load: ", conditionMessage(e))
    }
  )
}
```

This means:
- **Tracked file** `.Rprofile` - Reproducibility options only
- **Local file** `.Rprofile.local` - Personal customizations (in `.gitignore`)
- **zzvim-R** - Auto-creates `.Rprofile.local` with terminal graphics setup

## Terminal-Specific Details

### Kitty
- **Detection**: Checks `KITTY_WINDOW_ID` environment variable
- **Display**: Uses `kitty +kitten icat` command
- **Alignment**: Supports left/center/right alignment via `--align` flag
- **Platforms**: Linux, macOS

### Ghostty
- **Detection**: Checks `GHOSTTY_RESOURCES_DIR` or `TERM=xterm-ghostty`
- **Display**: Uses Kitty graphics protocol (`kitty +kitten icat`)
- **Alignment**: Supports left/center/right alignment via `--align` flag
- **Platforms**: Linux, macOS

### WezTerm
- **Detection**: Checks `WEZTERM_EXECUTABLE` or `TERM_PROGRAM=WezTerm`
- **Display**: Uses Kitty graphics protocol (`kitty +kitten icat`)
- **Alignment**: Supports left/center/right alignment via `--align` flag
- **Platforms**: Linux, macOS, Windows

### iTerm2
- **Detection**: Checks `ITERM_SESSION_ID` or `TERM_PROGRAM=iTerm.app`
- **Display**: Uses `imgcat` command (built into iTerm2)
- **Alignment**: Displays centered (iTerm2 limitation)
- **Platform**: macOS only

### Other Terminals
- **Graceful Degradation**: If terminal not detected, no error
- **Fallback**: R works normally without plot display
- **Extensible**: Detection function can be extended for additional terminals

## Customization

### Change Plot Size
```r
# Fixed dimensions
set_plot_size(1200, 800, res = 150)

# Relative to terminal (auto-resizes)
set_plot_size_relative(width_pct = 0.5, height_pct = 0.8)
```

### Change Alignment (Kitty only)
```r
set_plot_align("left")     # or "center", "right"
```

### Disable Auto-Display
If you prefer the old workflow without auto-display:
```r
# Use explicit dev.off()
plot(data)
grDevices::dev.off()  # Displays plot
```

## Troubleshooting

### Plots not displaying
1. Verify terminal: `echo $KITTY_WINDOW_ID` (Kitty) or `echo $ITERM_SESSION_ID` (iTerm2)
2. Check `.Rprofile.local` exists: `ls -la .Rprofile.local`
3. Check R sourced it: `cat(.kitty_plot_file, useBytes = TRUE)`
4. Test icat manually: `kitty +kitten icat /path/to/image.png` or `imgcat /path/to/image.png`

### Terminal graphics disabled on some workspaces
- zzvim-R only creates `.Rprofile.local` if it doesn't exist
- Manually copy: `cp ~/.vim/autoload/zzvimr/../templates/.Rprofile.local .Rprofile.local`
- Or create manually from template

### Performance issues
- PNG rendering adds minimal overhead (~100ms per plot)
- Relative sizing recalculates on each plot (negligible overhead)
- Remove features you don't need by editing `.Rprofile.local`

## Related Documentation

- **zzcollab Integration**: See `docs/COLLABORATIVE_REPRODUCIBILITY.md`
- **R Project Setup**: See `docs/DEVELOPMENT.md`
- **zzvim-R Features**: See README.md
