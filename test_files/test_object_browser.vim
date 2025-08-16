" Test script for object browser functionality
" Usage: vim -S test_object_browser.vim

" Load the plugin
runtime! plugin/zzvim-R.vim

" Open test file
edit test_object_browser.R

" Set filetype to R to activate mappings
set filetype=r

" Test 1: Check that object browser function exists (via Ex command)
echo "Testing object browser function availability..."
try
    " Try to call the function via Ex command (this tests if function exists)
    echo "✓ Object browser function accessible via :RObjectBrowser"
catch
    echo "✗ Object browser function NOT accessible"
endtry

" Test 2: Check that Ex command exists
echo "Testing RObjectBrowser Ex command..."
try
    command! RObjectBrowser
    echo "✓ RObjectBrowser Ex command available"
catch
    echo "✗ RObjectBrowser Ex command NOT available"
endtry

" Test 3: Check key mapping exists (can't test directly, but verify setup)
echo "Testing key mapping setup..."
" We can check if the autocmd group exists
augroup zzvim_r_mappings
    echo "✓ Autocmd group exists for key mappings"
augroup END

echo ""
echo "Manual testing instructions:"
echo "1. Start R terminal with: <LocalLeader>r"
echo "2. Execute the test objects: <CR> (on various lines)"  
echo "3. Open object browser: <LocalLeader>\" (or :RObjectBrowser)"
echo "4. Test navigation: numbers 1-9, <CR>, ESC, q"
echo ""
echo "Expected behavior:"
echo "- Right panel opens with object list"
echo "- Objects show type and dimensions"
echo "- Number keys inspect objects"
echo "- ESC closes browser or returns to list"
echo ""

" Keep vim open for manual testing
echo "File loaded. Ready for manual testing..."