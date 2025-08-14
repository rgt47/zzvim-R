" Debug script to understand the cursor jumping issue

echo "Testing cursor movement logic..."

" Test the comment detection regex
let test_lines = [
    \ 'library(pacman)',
    \ 'library(tidyverse)', 
    \ '# This is a comment',
    \ 'df0 = read_csv("../data/raw_data/d_level3top.csv")'
    \ ]

for i in range(len(test_lines))
    let line = test_lines[i]
    let is_comment = line =~# '^\s*#'
    echo 'Line ' . (i+1) . ': "' . line . '" -> Comment: ' . is_comment
endfor

echo "\nTesting MoveToNextNonComment logic..."
" Simulate the MoveToNextNonComment function logic
for i in range(len(test_lines))
    let line = test_lines[i]
    let matches_pattern = line =~# '^\s*\(#\|$\)'
    echo 'Line ' . (i+1) . ': "' . line . '" -> Skip: ' . matches_pattern
endfor