# AI HUD Tools for R Developers

This document summarizes available tools that can serve as a "heads-up display" (HUD)
to support R development. It includes code visualization, debugging, environment context,
and experiment tracking.

## AI HUD Tools

### 1. GitHub Copilot
- Autocompletion and inline documentation for R (RStudio via extension, or VS Code).
- **Link**: https://github.com/features/copilot

### 2. gptstudio
- RStudio add-in to interact with GPT models in a pane.
- Helps generate, refactor, or explain R code inline.
- **Link**: https://github.com/MichelNivard/gptstudio

### 3. chattr
- RStudio add-in for chat-driven coding with LLMs.
- **Link**: https://github.com/coatless/chattr

### 4. chores
- Automates repetitive R tasks with GPT assistance.
- **Link**: https://github.com/kieranjmartin/chores

### 5. gander
- Inspects R session objects and integrates them into LLM context.
- Useful for HUD-like awareness of data objects.
- **Link**: https://github.com/milesmcbain/gander

### 6. R-LSP + Neovim (R.nvim)
- Language Server Protocol integration in Neovim with R support.
- Provides completions, diagnostics, and REPL integration.
- **Link**: https://github.com/R-nvim/R.nvim

---

## Appendix: R Options and Environment Variables HUD

You can capture **R options** and **environment variables** into a unified data frame for
a HUD-like display. This is useful for debugging, reproducibility, or building overlays
in RStudio, VS Code, or Neovim (R.nvim).

### Example Code

```r
library(tibble)
library(dplyr)

# ---- R options ----
opts_df <- tibble(
  type   = "option",
  name   = names(options()),
  value  = vapply(options(), function(x) {
    paste(capture.output(str(x, give.attr = FALSE)), collapse = " ")
  }, character(1))
)

# ---- Environment variables ----
env_df <- tibble(
  type   = "env",
  name   = names(Sys.getenv()),
  value  = unname(Sys.getenv())
)

# ---- Combine ----
hud_df <- bind_rows(opts_df, env_df)

# ---- Examples ----
# Show first few rows
print(head(hud_df, 12), right = FALSE)

# View in RStudio HUD-style
# View(hud_df)

# Search/filter example
# filter(hud_df, grepl("path", name, ignore.case = TRUE))
```

### Example Output

```
type    name               value
option  add.smooth         function (x, y, bar = TRUE, col = "lightgray", ...)
option  browserNLdisabled  FALSE
option  digits             7
option  dplyr.show_progress TRUE
env     HOME               /Users/rg
env     LANG               en_US.UTF-8
env     PATH               /usr/local/bin:/usr/bin:/bin
env     SHELL              /bin/zsh
env     TERM               xterm-256color
```

---

## Appendix: `session_hud()` Function

For convenience, you can wrap the HUD code into a reusable function.  
This will let you quickly inspect **R options** and **environment variables** together.

### Function Definition

```r
session_hud <- function() {
  library(tibble)
  library(dplyr)
  
  # ---- R options ----
  opts_df <- tibble(
    type   = "option",
    name   = names(options()),
    value  = vapply(options(), function(x) {
      paste(capture.output(str(x, give.attr = FALSE)), collapse = " ")
    }, character(1))
  )
  
  # ---- Environment variables ----
  env_df <- tibble(
    type   = "env",
    name   = names(Sys.getenv()),
    value  = unname(Sys.getenv())
  )
  
  # ---- Combine ----
  hud_df <- bind_rows(opts_df, env_df)
  
  return(hud_df)
}

# Example usage
df <- session_hud()
print(head(df, 12), right = FALSE)
# View(df)   # for RStudio HUD-like browsing
```

This gives you a **single call** (`session_hud()`) to inspect your session’s runtime
configuration in a structured data frame.
