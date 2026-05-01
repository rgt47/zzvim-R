# zzvim-R: Install and Try 10 Features (Vim on macOS/Linux)
*2026-04-16 16:37 PDT*

## Prerequisites

- Vim 8.0+ with `+terminal` (`vim --version | grep +terminal`)
- R installed and on `$PATH` (`which R`)
- A terminal emulator (any; Kitty/Ghostty/WezTerm/iTerm2 for
  inline plots)

## Step 1: Install the plugin

### vim-plug (recommended)

Add to your vimrc:

```vim
Plug 'rgt47/zzvim-R'
```

Then restart Vim and run `:PlugInstall`.

### Alternative: native Vim packages

```bash
mkdir -p ~/.vim/pack/plugins/start/
git clone https://github.com/rgt47/zzvim-R.git \
  ~/.vim/pack/plugins/start/zzvim-R
vim -c 'helptags ALL' -c 'quit'
```

## Step 2: Set your LocalLeader

zzvim-R mappings are all prefixed with `<LocalLeader>`. Add to
your vimrc if not already set:

```vim
let maplocalleader = ' '
```

This makes the spacebar the prefix. If you skip this, the
default LocalLeader is `\`.

**Note on potential conflicts:** if you also map
`<space><space>` to something (e.g., `<C-d>` for half-page
scroll), Vim's `timeoutlen` governs how long it waits after the
first space before deciding whether a second key is coming.
The default 1000 ms works well; lower values (e.g., 200 ms)
may cause LocalLeader mappings to misfire.

Other recommended vimrc settings that complement zzvim-R:

```vim
set splitright        " R terminal opens on the right
set hidden            " switch buffers without saving
set autoread          " reload files changed outside Vim
```

## Step 3: Create a demo R file

```bash
mkdir -p /tmp/zzvim-demo && cd /tmp/zzvim-demo
```

Create `/tmp/zzvim-demo/demo.R` with this content:

```r
library(datasets)

data(mtcars)
data(iris)

# --- Feature 3: Smart single-line submission ---
x <- mean(mtcars$mpg)
print(x)

# --- Feature 4: Multi-line function detection ---
summarize_column <- function(df, col) {
  values <- df[[col]]
  list(
    mean = mean(values, na.rm = TRUE),
    sd = sd(values, na.rm = TRUE),
    n = length(values)
  )
}

# --- Feature 5: Pipe chain detection ---
result <- mtcars |>
  subset(cyl == 6) |>
  transform(kpl = mpg * 0.425144) |>
  head(5)

# --- Feature 6: ggplot + chain ---
library(ggplot2)
p <- ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point(aes(color = factor(cyl))) +
  labs(title = 'Weight vs MPG') +
  theme_minimal()
print(p)
```

## Step 4: Create a demo Rmd file

Create `/tmp/zzvim-demo/demo.Rmd`:

````markdown
---
title: 'zzvim-R Demo'
output: html_document
---

```{r setup}
library(datasets)
data(mtcars)
```

Some analysis prose here.

```{r analysis}
summary(mtcars$mpg)
```

More prose between chunks.

```{r plot}
hist(mtcars$mpg, main = 'MPG Distribution')
```
````

## Now open demo.R and try each feature

```bash
cd /tmp/zzvim-demo
vim demo.R
```

---

### Feature 1: Launch an R terminal

Press: `<LocalLeader>rh`

(That is: spacebar, then `r`, then `h` -- if your LocalLeader
is space.)

Three launch variants are available:

| Keys | What it starts |
|------|----------------|
| `<LocalLeader>rh` | Host R, vanilla (no `.Rprofile`) |
| `<LocalLeader>rr` | Host R with renv (loads `.Rprofile`) |
| `<LocalLeader>r`  | Container R via `make r` (Docker) |

Use `rh` for this demo. An R terminal opens in a vertical
split. You should see the R prompt. Press `Ctrl-W h` to move
your cursor back to the code buffer.

---

### Feature 2: Send a single line

Move cursor to the line `library(datasets)` (line 1).

Press: `<CR>` (Enter)

R loads the datasets package. The plugin sends just this one
line.

---

### Feature 3: Smart single-line submission

Move cursor to `x <- mean(mtcars$mpg)`.

Press: `<CR>`

Then move to `print(x)` and press `<CR>` again.

You see the computed mean of mpg in the R terminal.

---

### Feature 4: Multi-line function detection

Move cursor to **any line** inside the `summarize_column`
function (e.g., the line with `values <- df[[col]]`).

Press: `<CR>`

The plugin detects the entire function body (from
`summarize_column <- function(...)` through the closing `}`)
and sends all of it. You should see no error in R -- the
function is now defined.

Verify by moving to a blank line at the bottom, typing in
Vim's insert mode:

```
summarize_column(mtcars, 'mpg')
```

Then press `<Esc>` and `<CR>` to send it.

---

### Feature 5: Pipe chain detection

Move cursor to the line `result <- mtcars |>`.

Press: `<CR>`

The plugin detects the `|>` continuation and sends all four
lines (through `head(5)`) as one block.

---

### Feature 6: Object inspection

Move cursor so it is on the word `mtcars` (any occurrence).

Try each:

- `<LocalLeader>h` -- runs `head(mtcars)` in R
- `<LocalLeader>s` -- runs `str(mtcars)` in R
- `<LocalLeader>d` -- runs `dim(mtcars)` in R
- `<LocalLeader>n` -- runs `names(mtcars)` in R

Each sends the inspection command to R without you typing it.

---

### Feature 7: Pipe insertion

Place cursor at the end of a line (e.g., on `data(iris)`).

Press: `<LocalLeader>o`

The plugin appends ` |>` to the current line, creates a new
line below, and puts you in insert mode -- ready to type the
next step of a pipe chain. Press `<Esc>` and `u` to undo if
you want to revert.

---

### Feature 8: Workspace HUD dashboard

Press: `<LocalLeader>0` (that is LocalLeader then zero)

A tabbed display opens showing 6 workspace panels: memory
usage, data frames, loaded packages, environment variables, R
options, and (if plots exist) plot history. Navigate tabs with
`gt` / `gT`. Close with `:q`.

---

### Feature 9: R Markdown chunk navigation

Open the Rmd file:

```vim
:e demo.Rmd
```

Press `<LocalLeader>rh` to open an R terminal for this buffer
(each buffer gets its own terminal session).

Then try:

- `<LocalLeader>j` -- jump to the next R code chunk (cursor
  lands inside the chunk)
- `<LocalLeader>k` -- jump to the previous chunk
- `<LocalLeader>l` -- execute the current chunk (sends all
  lines between the fences to R)

Navigate through the three chunks (`setup`, `analysis`, `plot`)
and execute each one in sequence.

---

### Feature 10: Visual selection submission

Go back to `demo.R`:

```vim
:e demo.R
```

Use Vim's visual mode to select any arbitrary lines: press `V`
to enter visual-line mode, move down to highlight 2-3 lines,
then press `<CR>`.

The plugin sends exactly the selected lines to R -- useful when
you want to run a specific subset of code that is not a
complete function or pipe chain.

---

## Cleanup

```bash
rm -rf /tmp/zzvim-demo
# To uninstall the plugin:
rm -rf ~/.vim/pack/plugins/start/zzvim-R
```

## Next steps

- `:help zzvim-R` for the full command and mapping reference
- Try `<LocalLeader>v` with cursor on a data frame name for a
  formatted data viewer
- Try `<LocalLeader>m` for a standalone memory usage panel
- Explore `<LocalLeader>"` for the vim-peekaboo style object
  browser

---
*Rendered on 2026-04-16 at 16:43 PDT.*<br>
*Source: ~/prj/sfw/04-zzvim-r/zzvim-R/docs/quickstart.md*
