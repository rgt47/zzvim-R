" Quick validation test for key optimizations
" Load the optimized plugin
source plugin/zzvim-R.vim

" Test 1: Configuration optimization - verify get() pattern works
echo "Testing configuration optimization..."
if exists('g:zzvim_r_terminal_width') && g:zzvim_r_terminal_width == 100
    echo "✓ PASS - Configuration get() pattern working"
else
    echo "✗ FAIL - Configuration issue"
endif

" Test 2: IsBlockStart optimization - verify pattern detection works
echo "Testing IsBlockStart optimization..."
let test_cases = [
    \ ['library(pacman)', 1],
    \ ['p_load(dplyr)', 1], 
    \ ['if (x > 0) {', 1],
    \ ['my_func <- function(x) {', 1],
    \ ['x <- 5', 0],
    \ ['# comment', 0]
\ ]

let all_passed = 1
for [line, expected] in test_cases
    let result = ZzvimRTestIsBlockStart(line)
    if result != expected
        echo "✗ FAIL - Pattern '" . line . "' expected " . expected . " got " . result
        let all_passed = 0
    endif
endfor

if all_passed
    echo "✓ PASS - IsBlockStart optimization working"
endif

" Test 3: Simple functionality test
echo "Testing basic plugin functionality..."
if exists('*s:SendToR') && exists('*s:GetCodeBlock')
    echo "✓ PASS - Core functions exist"
else
    echo "✗ FAIL - Core functions missing"
endif

echo "Validation complete."