" Test multi-terminal functionality
echo "=========================================="
echo "  Multi-Terminal R Session Test"  
echo "=========================================="

" Force clean plugin load
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "✓ Plugin loaded"

" Create first R file
new
call setline(1, ['# File 1', 'file1_var <- 100', 'print("This is file 1")', 'print(file1_var)'])
write test_files/file1.R

echo "✓ Created file1.R"

" Send code from first file
normal! 2G
RSendLine
echo "✓ Sent code from file1.R"

" Brief pause
sleep 300m

" Create second R file in new buffer
new  
call setline(1, ['# File 2', 'file2_var <- 200', 'print("This is file 2")', 'print(file2_var)'])
write test_files/file2.R

echo "✓ Created file2.R"

" Send code from second file
normal! 2G
RSendLine
echo "✓ Sent code from file2.R (should create new terminal)"

" Brief pause
sleep 300m

" Test isolation - check if variables are separate
" Go back to file1
buffer test_files/file1.R
normal! G
call append(line('.'), 'print(exists("file2_var"))  # Should be FALSE')
normal! G
RSendLine
echo "✓ Testing variable isolation in file1"

sleep 300m

" Go to file2 and test the other way
buffer test_files/file2.R
normal! G  
call append(line('.'), 'print(exists("file1_var"))  # Should be FALSE')
normal! G
RSendLine
echo "✓ Testing variable isolation in file2"

echo ""
echo "=========================================="
echo "Multi-Terminal Test Complete!"
echo ""
echo "Check the terminal windows:"
echo "- file1.R should have its own R terminal"
echo "- file2.R should have its own R terminal" 
echo "- Variables should be isolated between files"
echo "=========================================="

" Clean up
bdelete! test_files/file1.R
bdelete! test_files/file2.R