" Debug script for testing zzvim-R with simple R file
" Test with a file containing just '1'

echo "=== zzvim-R Debug Test ==="

" Enable debug logging
let g:zzvim_r_debug = 4

" Open the test file
edit debug_simple.R

" Check file type detection
echo "File type: " . &filetype

" Check if plugin is loaded
echo "Plugin loaded: " . (exists('g:loaded_zzvim_r') ? 'YES' : 'NO')

" Check if R is available
echo "R executable: " . (executable('R') ? 'FOUND' : 'NOT FOUND')

" Test terminal status
echo "\n=== Terminal Status ==="
call zzvim_r#terminal_status()

" Test opening terminal
echo "\n=== Opening R Terminal ==="
call zzvim_r#open_terminal()

" Wait a moment then check status again
sleep 2
echo "\n=== Terminal Status After Opening ==="
call zzvim_r#terminal_status()

" Test sending the line (should send '1' to R)
echo "\n=== Sending Current Line to R ==="
normal! gg
call zzvim_r#submit_line()

echo "\n=== Debug Test Complete ==="