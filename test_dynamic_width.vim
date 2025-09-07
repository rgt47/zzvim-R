" Test script for dynamic terminal width functionality
" This script tests that R terminals are created with half the current window width

echo "Testing dynamic terminal width functionality..."

" Test 1: Check winwidth calculation
let current_width = winwidth(0)
let expected_terminal_width = current_width / 2
echo "Current window width: " . current_width
echo "Expected terminal width: " . expected_terminal_width

" Test 2: Create a test R file to trigger terminal creation
write test_width_demo.R
call setline(1, 'x <- 1:10')
call setline(2, 'mean(x)')

" Save the current window width before terminal creation
let original_width = winwidth(0)

echo "Original window width before R terminal: " . original_width

" The user would now send a line to R with <CR> or similar
" This would trigger the dynamic width calculation

echo "Test setup complete. Now:"
echo "1. Send a line to R (press <CR> on line 1 or 2)"
echo "2. Check that the R terminal width = " . (original_width / 2)
echo "3. Try resizing the vim window and creating a new R session"
echo "4. Verify the terminal adjusts to the new window size"