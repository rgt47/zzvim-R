" Test that command line prompts are eliminated
" Force fresh plugin load
unlet! g:loaded_zzvim_r
source plugin/zzvim-R.vim

echo "Testing silent execution..."

" Create a temporary R file to test with
let temp_test_file = tempname() . '.R'
call writefile(['x <- 5', 'print(x)'], temp_test_file)

" Open the test file
execute 'edit' temp_test_file

" Move to first line 
normal! gg

echo "Sending line to R (should be silent)..."

" This should trigger terminal creation and code sending without prompts
call s:SendToR('line')

echo "Test completed - check if any prompts appeared above."

" Clean up
execute 'bdelete!' temp_test_file