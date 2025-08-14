" Simple test to reproduce the cursor jumping issue
" Open an R file and simulate pressing Enter

" Create test content in a buffer
enew
set filetype=r
call setline(1, 'library(pacman)')
call setline(2, 'library(tidyverse)')
call setline(3, 'df0 = read_csv("../data/raw_data/d_level3top.csv")')

" Position on line 1
call cursor(1, 1)

echo "Before: cursor on line " . line('.')

" Load the plugin
source plugin/zzvim-R.vim

" Simulate pressing <CR> but with debugging
" We'll manually call the function that would be called
echo "Simulating <CR> press..."

" This should call s:SendToR('') but we can't access it directly
" Let's see what key is mapped to <CR>
redir => mappings
nmap <CR>
redir END
echo "Current mapping: " . mappings

" Check if we have the function available through any public interface