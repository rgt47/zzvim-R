# HUD System Guide
*2026-04-30 06:32 PDT*

The zzvim-R Heads-Up Display (HUD) system provides RStudio-style
workspace visibility from within terminal Vim. Each HUD is a scratch
buffer rendered on demand from data captured out of the running R
session, with buffer-local mappings for navigation and inspection.

This guide is reference material. For the canonical mapping table, see
`:help zzvim-R-mappings`.

## Prerequisites

- R session attached to the buffer (`<LocalLeader>r`, `rr`, or `rh`)
- R package `jsonlite` installed (used for HUD data transport)
- For inline plot rendering: a graphics-capable terminal (Kitty,
  Ghostty, WezTerm, or iTerm2). See `docs/terminal-graphics.md`.

## The seven HUDs

| Mapping            | HUD          | Shows                                |
| ------------------ | ------------ | ------------------------------------ |
| `<LocalLeader>m`   | Memory       | Object sizes (sorted, with total)    |
| `<LocalLeader>e`   | Data frames  | Data frame name + row x col counts   |
| `<LocalLeader>z`   | Packages     | Loaded packages                      |
| `<LocalLeader>x`   | Environment  | R environment variables              |
| `<LocalLeader>a`   | Options      | R session options (digits, warn, …)  |
| `<LocalLeader>v`   | Data viewer  | Tabular preview of object at cursor  |
| `<LocalLeader>P`   | Plot history | Numbered list of past plots          |

`<LocalLeader>0` opens all of the above in a single tabbed dashboard.

### Memory (`<LocalLeader>m`)

Workspace objects sorted descending by size, with a total at the bottom:

```
=== Memory Usage ===
big_matrix     :   7.63 MB
daily_sales    :   0.01 MB
patients       :   0.00 MB
config         :   0.00 MB
TOTAL          :   7.68 MB
```

Use to identify objects that should be `rm()`'d before rendering or
saving the workspace.

### Data frames (`<LocalLeader>e`)

```
=== Data Frames ===
patients       : 50 rows x 4 cols
daily_sales    : 365 rows x 3 cols
summary_stats  : 3 rows x 4 cols
```

Use to verify dimensions after a join, filter, or pivot without typing
`dim()` on each object.

### Packages (`<LocalLeader>z`)

Lists currently attached packages. Useful before sourcing scripts that
expect particular libraries.

### Environment (`<LocalLeader>x`)

Reports `R_HOME`, `R_LIBS_USER`, `PATH`, and other shell variables as
seen from inside R. Use when diagnosing path or library-discovery
issues, especially under Docker.

### Options (`<LocalLeader>a`)

Current values of session options affecting output and behavior:
`digits`, `warn`, `width`, `stringsAsFactors`, etc.

### Data viewer (`<LocalLeader>v`)

Position the cursor on a data frame name and press `<LocalLeader>v` to
open a read-only tabular preview. If `Tabularize` or `EasyAlign` is
installed, columns are aligned automatically.

### Plot history (`<LocalLeader>P`)

```
Plot History                                              [HUD]
====================================================================
Enter=display | z=zoom PDF | s=save | d=delete | q=close | /=search

  #   Name                 Created              Code
----------------------------------------------------------------------
> [1] scatter_wt_mpg       2026-01-30T14:30     show(plot(mtcars$wt...
  [2] histogram_age        2026-01-30T14:30     show(hist(patients$...
  [3] boxplot_treatment    2026-01-30T14:30     show(boxplot(outcom...
  [4] ggplot_hp_mpg        2026-01-30T14:31     show(ggplot(mtcars,...

Total: 4 plots | Current: 4
```

Buffer-local mappings:

| Key       | Action                                         |
| --------- | ---------------------------------------------- |
| `j` / `k` | Move cursor down / up                          |
| `1`-`9`   | Jump to plot N                                 |
| `<CR>`    | Render selected plot in the graphics pane      |
| `z`       | Open the master PDF in the system viewer       |
| `s`       | Save plot (prompts for path; `.pdf` or `.png`) |
| `d`       | Delete plot from history (with confirmation)   |
| `r`       | Refresh the HUD                                |
| `/`       | Search by name or code                         |
| `q`       | Close the HUD                                  |

For details on the dual-resolution PDF + PNG plot pipeline, see
`docs/plot-guide.md`.

## Quick plot navigation (without opening the HUD)

| Mapping            | Action                       |
| ------------------ | ---------------------------- |
| `<LocalLeader><`   | Previous plot in history     |
| `<LocalLeader>>`   | Next plot in history         |
| `<LocalLeader>]`   | Open current plot's PDF      |
| `<LocalLeader>[`   | Show plot history (same as P)|
| `<LocalLeader>\`   | Save current plot            |

## The dashboard (`<LocalLeader>0`)

Opens all HUDs as tabs:

```
[Memory] [DataFrames] [Packages] [Environment] [Options] [Plots]
```

Standard Vim tab navigation applies: `gt` next, `gT` previous, `Ngt`
jump to tab N, `:tabclose` close one, `:tabonly` close all but the
current. Pressing `<LocalLeader>0` again refreshes every tab against
the live R session.

## Object inspection shortcuts

These act on the word under the cursor (no HUD; output goes to the R
terminal):

| Mapping            | Action     |
| ------------------ | ---------- |
| `<LocalLeader>h`   | `head()`   |
| `<LocalLeader>u`   | `tail()`   |
| `<LocalLeader>s`   | `str()`    |
| `<LocalLeader>p`   | `print()`  |
| `<LocalLeader>n`   | `names()`  |
| `<LocalLeader>d`   | `dim()`    |
| `<LocalLeader>g`   | `glimpse()`|
| `<LocalLeader>c`   | `class()`  |
| `K`                | `?` help   |

## Comparison with RStudio

| RStudio pane | zzvim-R equivalent          | Mapping                        |
| ------------ | --------------------------- | ------------------------------ |
| Environment  | Memory + Data frames HUDs   | `<LocalLeader>m`, `e`          |
| Plots        | Plot HUD + graphics pane    | `<LocalLeader>P`               |
| Packages     | Packages HUD                | `<LocalLeader>z`               |
| Help         | `K` on a function           | `K`                            |
| Viewer       | Data viewer                 | `<LocalLeader>v`               |
| Console      | Vim terminal                | `<LocalLeader>r` / `rr` / `rh` |

## Building a HUD demo workspace

To exercise all of the HUDs against a single workspace, source the
following into an attached R session:

```r
library(dplyr)
library(ggplot2)

# Memory HUD: a range of object sizes
x <- 1:100
y <- rnorm(100)
mtcars_copy <- mtcars
big_matrix <- matrix(rnorm(1e6), nrow = 1000, ncol = 1000)
config <- list(name = "demo", settings = list(a = 1, b = 2))

# Data frames HUD
patients <- data.frame(
  id = 1:50,
  age = sample(20:80, 50, replace = TRUE),
  treatment = sample(c('A', 'B', 'Control'), 50, replace = TRUE),
  outcome = rnorm(50, mean = 100, sd = 15)
)
daily_sales <- data.frame(
  date = seq.Date(as.Date('2024-01-01'), by = 'day', length.out = 365),
  revenue = cumsum(rnorm(365, mean = 1000, sd = 200))
)
summary_stats <- patients |>
  group_by(treatment) |>
  summarise(n = n(), mean_outcome = mean(outcome), .groups = 'drop')

# Plot HUD
show(plot(mpg ~ wt, data = mtcars), .name = 'scatter_wt_mpg')
show(hist(patients$age, breaks = 15), .name = 'histogram_age')
show(
  ggplot(mtcars, aes(hp, mpg, colour = factor(cyl))) +
    geom_point() + geom_smooth(method = 'lm', se = FALSE),
  .name = 'ggplot_hp_mpg'
)
```

After sourcing, exercise each HUD in turn (`<LocalLeader>m`, `e`, `z`,
`x`, `a`, `P`) and the dashboard (`<LocalLeader>0`).
