" Diagnostic test to trace the pattern matching issue
source plugin/zzvim-R.vim

echo "=== Diagnostic Test ==="

" Test the internal function step by step
let test_line = 'library(pacman)'
echo "Test line: " . test_line

" Check if the internal function exists 
echo "s:IsBlockStart exists: " . exists('*s:IsBlockStart')

" Try calling it via the public wrapper
echo "Public wrapper exists: " . exists('*ZzvimRTestIsBlockStart')

" Test each pattern condition manually within the function scope
function! DiagnosticIsBlockStart(line) abort
    echo "=== Inside function ==="
    echo "Input: " . a:line
    
    " Test condition 1
    let test1 = a:line =~# 'function\s*('
    echo "Pattern 1 (function): " . test1
    if test1 | return 1 | endif
    
    " Test condition 2  
    let test2 = a:line =~# '^\s*\(if\|for\|while\)\s*('
    echo "Pattern 2 (control): " . test2
    if test2 | return 1 | endif
    
    " Test condition 3
    let test3 = a:line =~# '^\s*\(repeat\s*\)\?{'
    echo "Pattern 3 (repeat/brace): " . test3
    if test3 | return 1 | endif
    
    " Test condition 4
    let test4 = a:line =~# '[a-zA-Z_][a-zA-Z0-9_.]*\s*('
    echo "Pattern 4 (function call): " . test4
    if test4 | return 1 | endif
    
    echo "All patterns failed - returning 0"
    return 0
endfunction

let result = DiagnosticIsBlockStart(test_line)
echo "Final result: " . result

echo ""
echo "Official function result: " . ZzvimRTestIsBlockStart(test_line)