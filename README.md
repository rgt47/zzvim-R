# rgt-R

**rgt-R** is a Vim plugin that enhances your workflow when working with R and R Markdown files. It allows you to send code directly to an embedded R terminal, navigate and execute R Markdown code chunks, perform common R operations on objects, and even render R Markdown documents to PDF—all from within Vim.

## Features

- **Send code to R:**  
  - Press `<CR>` in Normal mode to send the current line to R and move down.
  - Select code visually and press `<CR>` to send the selection.
- **R Markdown chunk navigation:**  
  - Use `<localleader>l` to select and run the current chunk.
  - `<localleader>;` also moves to the next chunk and centers the screen.
  - `<localleader>k` and `<localleader>j` navigate to previous/next chunks.
- **Common object inspections:**  
  With `<localleader>d`, `<localleader>h`, `<localleader>s`, `<localleader>p`, `<localleader>n`, `<localleader>f`, and `<localleader>g`, run `dim()`, `head()`, `str()`, `print()`, `names()`, `length()`, and `glimpse()` on the object under the cursor.
- **R Process Control:**  
  - `<localleader>c` sends Ctrl-C to interrupt R.
  - `<localleader>q` sends 'Q' to quit R's debug browser.
- **R Markdown Rendering:**  
  - Press `ZT` to render the current R Markdown file to PDF using `rmarkdown::render()`.
- **Embedded Output:**  
  - In visual mode, `<localleader>z` captures output of the selected code, comments each line, and inserts it back into the buffer.

## Requirements

- Vim 8.0+ or Neovim with `:terminal` support.
- R installed and on your system’s PATH.
- The `rmarkdown` R package if you plan to render `.Rmd` files to PDF.

## Installation

**Using Vim’s Native Packages:**
```bash
mkdir -p ~/.vim/pack/plugins/start
cd ~/.vim/pack/plugins/start
git clone https://github.com/username/rgt-R.git

## Usage from an open R, Rmd, or qmd file:
    1.	Start R with
<localleader>r

This opens a vertical terminal running R.

	3.	Send code to R:
	•	Normal mode <CR>: send current line, move down.
	•	Visual mode <CR>: send selection.
	4.	Perform object inspections with <localleader> maps.
	5.	Navigate and execute R Markdown chunks.
	6.	Render current .Rmd to PDF with ZT.

For details on all commands and mappings, see :help rgt-R.

## Contributing

Contributions and suggestions are welcome. Please open an issue or submit a pull request on GitHub.

## License

Distributed under the GPL3. See LICENSE for details.
