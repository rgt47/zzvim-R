" Debug the cursor jumping issue

" Open the test file
edit test_files/test_cursor_jump.R

" Position cursor on line 1
call cursor(1, 1)

" Test what GetTextByType returns for line 1
echo "Testing line 1: " . getline(1)

" We need to test the actual functions, but they're script-local
" Let's add some debugging to understand what's happening

" Simulate what happens when we press Enter on line 1
echo "Current line: " . line('.')
echo "Line content: '" . getline('.') . "'"

" Test if it matches comment pattern
echo "Matches comment pattern: " . (getline('.') =~# '^\s*#')

" Test the logic that would be used in MoveCursorAfterSubmission
if getline('.') =~# '^\s*#'
    echo "Would call MoveToNextNonComment()"
    " Simulate MoveToNextNonComment logic
    let next_line = line('.') + 1
    echo "Starting search from line: " . next_line
    while next_line <= line('$') && getline(next_line) =~# '^\s*\(#\|$\)'
        echo "Line " . next_line . ": '" . getline(next_line) . "' - skipping"
        let next_line += 1
    endwhile
    echo "Would move to line: " . next_line
else
    echo "Would move to next line: " . (line('.') + 1)
endif