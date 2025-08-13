source plugin/zzvim-R.vim

" Debug the pattern matching
let test_line = 'library(pacman)'
echo "Testing line: " . test_line

" Test each pattern individually
echo "Pattern 1 (function): " . (test_line =~# 'function\s*(')
echo "Pattern 2 (control): " . (test_line =~# '^\s*\(if\|for\|while\)\s*(')  
echo "Pattern 3 (repeat/brace): " . (test_line =~# '^\s*\(repeat\s*\)\?{')
echo "Pattern 4 (function call): " . (test_line =~# '[a-zA-Z_][a-zA-Z0-9_.]*\s*(')

" Test the function
echo "IsBlockStart result: " . ZzvimRTestIsBlockStart(test_line)