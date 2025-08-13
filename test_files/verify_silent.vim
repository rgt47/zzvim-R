" Verify silent execution 
echo "=== Verifying Silent Execution ==="

" Force clean reload
unlet! g:loaded_zzvim_r
source plugin/zzvim-R.vim

echo "Plugin reloaded."

" Create test content
new
call setline(1, 'x <- 5')

echo "About to send line to R (should be completely silent)..."

" Send line using the Ex command
RSendLine

echo "Line sent. Check: did you see any 'Sent X line' messages or 'Press ENTER' prompts above?"
echo "=== Test Complete ==="

" Close test buffer  
bdelete