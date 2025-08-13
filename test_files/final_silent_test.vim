" Final test to demonstrate silent execution
echo "=========================================="
echo "  Silent Execution Test"  
echo "=========================================="

" Force clean plugin load
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "✓ Plugin loaded"

" Create test R code
new
call setline(1, ['x <- 42', 'print(x)', 'y <- x * 2'])

echo "✓ Test R code created"
echo ""
echo "Now sending lines to R..."
echo "(Watch for any unwanted messages or prompts)"
echo ""

" Send first line
normal! gg
RSendLine
echo "✓ Line 1 sent"

" Brief pause
sleep 200m

" Send second line  
normal! j
RSendLine  
echo "✓ Line 2 sent"

echo ""
echo "=========================================="
echo "Test Complete!"
echo ""
echo "If you see this without any 'Press ENTER'"
echo "prompts or 'Sent X lines' messages, then"
echo "the silent execution fix is working!"
echo "=========================================="

" Clean up
bdelete!