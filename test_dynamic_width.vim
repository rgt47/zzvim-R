" Test script for conditional terminal width functionality
" Tests both user-configured width and dynamic width fallback

echo "Testing conditional terminal width functionality..."

" Test 1: Check current window width
let current_width = winwidth(0)
echo "Current window width: " . current_width

" Test 2: Check if g:zzvim_r_terminal_width is set
if exists('g:zzvim_r_terminal_width')
    echo "g:zzvim_r_terminal_width is SET to: " . g:zzvim_r_terminal_width
    echo "Expected terminal width: " . g:zzvim_r_terminal_width . " (user configured)"
else
    echo "g:zzvim_r_terminal_width is NOT SET"
    echo "Expected terminal width: " . (current_width / 2) . " (dynamic: half window width)"
endif

" Test 3: Create test R file
write test_width_demo.R
call setline(1, 'x <- 1:10')
call setline(2, 'mean(x)')

echo ""
echo "=== Test Instructions ==="
echo "SCENARIO 1 - Dynamic width (default behavior):"
echo "1. Ensure g:zzvim_r_terminal_width is NOT set in your .vimrc"
echo "2. Send a line to R (press <CR> on line 1 or 2)"
echo "3. Verify terminal width = " . (current_width / 2)
echo ""
echo "SCENARIO 2 - User configured width:"
echo "1. Set: let g:zzvim_r_terminal_width = 80"
echo "2. Restart vim and run this test again"
echo "3. Send a line to R and verify terminal width = 80"
echo ""
echo "SCENARIO 3 - Window resize test:"
echo "1. Resize your vim window to a different size"
echo "2. Open a new R file and send a line"
echo "3. Verify dynamic width adjusts to new window size"