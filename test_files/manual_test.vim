" Manual test - Run this in vim to debug the cursor issue
" Instructions:
" 1. Open vim
" 2. :source test_files/manual_test.vim
" 3. Observe the output

echo "=== Cursor Movement Debug Test ==="

" Create the test file content
let test_content = [
    \ 'library(pacman)',
    \ 'library(tidyverse)',
    \ 'df0 = read_csv("../data/raw_data/d_level3top.csv")'
    \ ]

" Create a new buffer with the test content
enew
call setline(1, test_content)
setfiletype r

" Position cursor on line 1
call cursor(1, 1)

echo "File content created:"
for i in range(1, line('$'))
    echo 'Line ' . i . ': "' . getline(i) . '"'
endfor
echo ""

echo "Current cursor position: line " . line('.') . ", column " . col('.')
echo "Current line content: '" . getline('.') . "'"

" Test what the cursor movement function would do
echo ""
echo "Testing cursor movement logic for current line:"
echo "Line matches comment pattern (^\\s*#): " . (getline('.') =~# '^\s*#')

if getline('.') =~# '^\s*#'
    echo "Would call MoveToNextNonComment()"
    " Simulate MoveToNextNonComment
    let next_line = line('.') + 1
    echo "Starting search from line: " . next_line
    while next_line <= line('$')
        let line_content = getline(next_line)
        let should_skip = line_content =~# '^\s*\(#\|$\)'
        echo "  Line " . next_line . ': "' . line_content . '" -> skip: ' . should_skip
        if !should_skip
            break
        endif
        let next_line += 1
    endwhile
    echo "Would move cursor to line: " . next_line
else
    echo "Would move cursor to next line: " . (line('.') + 1)
endif

echo ""
echo "To test manually:"
echo "1. Position cursor on line 1"
echo "2. Press <CR> (if plugin is loaded)"
echo "3. Check where cursor ends up"