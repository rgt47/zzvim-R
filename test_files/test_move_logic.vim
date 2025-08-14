" Test the MoveToNextNonComment logic specifically

let test_lines = [
    \ 'library(pacman)',
    \ 'library(tidyverse)', 
    \ 'df0 = read_csv("../data/raw_data/d_level3top.csv")'
    \ ]

echo "Testing MoveToNextNonComment pattern matching:"
echo "Pattern: '^\\s*\\(#\\|$\\)'"
echo ""

for i in range(len(test_lines))
    let line_num = i + 1
    let line = test_lines[i]
    let matches = line =~# '^\s*\(#\|$\)'
    echo 'Line ' . line_num . ': "' . line . '"'
    echo '  Matches pattern (should skip): ' . matches
    echo '  Length: ' . len(line)
    if matches
        echo '  Reason: ' . (line =~# '^\s*#' ? 'starts with #' : 'empty line')
    endif
    echo ""
endfor

" Test with actual empty line
echo "Testing with actual empty line:"
let empty_line = ""
echo 'Empty line matches: ' . (empty_line =~# '^\s*\(#\|$\)')

" Test with line containing only whitespace
echo "Testing with whitespace-only line:"
let whitespace_line = "   "
echo 'Whitespace line matches: ' . (whitespace_line =~# '^\s*\(#\|$\)')