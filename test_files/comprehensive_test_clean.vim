" Clean comprehensive test suite with no interactive prompts
" Force fresh plugin load
unlet! g:loaded_zzvim_r
source plugin/zzvim-R.vim

echo "=========================================="
echo "    zzvim-R Clean Test Suite"
echo "=========================================="

let total_tests = 0
let passed_tests = 0

" Test 1: Plugin Loading
let total_tests += 1
if exists('g:loaded_zzvim_r') && g:loaded_zzvim_r == 1
    let passed_tests += 1
    echo "✓ PASS | Plugin loading"
else
    echo "✗ FAIL | Plugin loading"
endif

" Test 2: Configuration Optimization
let total_tests += 1
if get(g:, 'zzvim_r_terminal_width', -1) == 100 && get(g:, 'zzvim_r_command', '') == 'R --no-save --quiet'
    let passed_tests += 1
    echo "✓ PASS | Configuration optimization"
else
    echo "✗ FAIL | Configuration optimization"
endif

" Test 3: Pattern Matching Optimization
let total_tests += 1
let pattern_test_cases = [
    \ ['library(pacman)', 1],
    \ ['p_load(dplyr)', 1], 
    \ ['my_func <- function(x) {', 1],
    \ ['if (x > 0) {', 1],
    \ ['for (i in 1:10) {', 1],
    \ ['x <- 5', 0],
    \ ['# comment', 0]
\ ]

let pattern_passed = 1
for [line, expected] in pattern_test_cases
    let result = ZzvimRTestIsBlockStart(line)
    if result != expected
        let pattern_passed = 0
        echo "    ✗ Pattern '" . line . "' expected " . expected . " got " . result
    endif
endfor

if pattern_passed
    let passed_tests += 1
    echo "✓ PASS | Pattern matching optimization"
else
    echo "✗ FAIL | Pattern matching optimization"
endif

" Test 4: Core Functions Exist
let total_tests += 1
if exists('*ZzvimRTestIsBlockStart') && exists('*ZzvimRTestGetTextByType') && exists('*ZzvimRTestGetCodeBlock')
    let passed_tests += 1
    echo "✓ PASS | Core functions exist"
else
    echo "✗ FAIL | Core functions exist"
endif

" Test 5: Key Ex Commands
let total_tests += 1
let key_commands = ['ROpenTerminal', 'RSendLine', 'RSendSmart', 'RSendFunction']
let commands_ok = 1

for cmd in key_commands
    try
        execute 'command ' . cmd
    catch /E184:/
        let commands_ok = 0
        break
    endtry
endfor

if commands_ok
    let passed_tests += 1
    echo "✓ PASS | Key Ex commands exist"
else
    echo "✗ FAIL | Key Ex commands exist"
endif

" Final Summary
echo "=========================================="
echo "              FINAL RESULTS"
echo "=========================================="
echo printf("Tests Passed: %d/%d", passed_tests, total_tests)

if passed_tests == total_tests
    echo "🎉 ALL TESTS PASSED!"
    echo "✅ Optimizations successful and functional"
else
    echo "⚠️  Some tests failed"
endif

echo "=========================================="