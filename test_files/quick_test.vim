" Quick automated test of key functionality
echo "Running Quick Test Suite..."

" Load plugin
source plugin/zzvim-R.vim

let test_count = 0
let pass_count = 0

" Test 1: Configuration loading
let test_count += 1
if exists('g:zzvim_r_terminal_width') && g:zzvim_r_terminal_width == 100
    let pass_count += 1
    echo "✓ Configuration loading"
else
    echo "✗ Configuration loading"
endif

" Test 2: Plugin loading
let test_count += 1
if exists('g:loaded_zzvim_r') && g:loaded_zzvim_r == 1
    let pass_count += 1
    echo "✓ Plugin loaded"
else
    echo "✗ Plugin loaded"
endif

" Test 3: Core functions exist
let test_count += 1
if exists('*ZzvimRTestIsBlockStart')
    let pass_count += 1
    echo "✓ Test functions exist"
else
    echo "✗ Test functions exist"
endif

" Test 4: Pattern matching
let test_count += 1
let pattern_tests = [
    \ ['my_func <- function(x) {', 1, 'Function definition'],
    \ ['if (x > 0) {', 1, 'If statement'],
    \ ['library(pacman)', 1, 'Function call'],
    \ ['x <- 5', 0, 'Assignment']
\ ]

let pattern_pass = 1
for [line, expected, desc] in pattern_tests
    let result = ZzvimRTestIsBlockStart(line)
    if result != expected
        let pattern_pass = 0
        echo "  ✗ " . desc . " (expected " . expected . ", got " . result . ")"
    endif
endfor

if pattern_pass
    let pass_count += 1
    echo "✓ Pattern matching"
else
    echo "✗ Pattern matching"
endif

" Test 5: Commands exist
let test_count += 1
let commands_exist = 1
let test_commands = ['ROpenTerminal', 'RSendLine', 'RSendSmart']

for cmd in test_commands
    try
        execute 'command ' . cmd
    catch /E184:/
        let commands_exist = 0
        break
    endtry
endfor

if commands_exist
    let pass_count += 1
    echo "✓ Commands exist"
else
    echo "✗ Commands exist"
endif

" Summary
echo ""
echo "========================"
echo "Quick Test Results"
echo "========================"
echo printf("Passed: %d/%d", pass_count, test_count)
if pass_count == test_count
    echo "🎉 ALL TESTS PASSED!"
else
    echo "⚠️  Some tests failed."
endif
echo "========================"