scriptencoding utf-8
" CI-specific test suite for zzvim-R plugin
" This script runs basic validation tests suitable for headless CI environments

" Load the plugin (handle relative path)
if filereadable('plugin/zzvim-R.vim')
    source plugin/zzvim-R.vim
elseif filereadable('../plugin/zzvim-R.vim')
    source ../plugin/zzvim-R.vim
else
    echo "ERROR: Cannot find plugin/zzvim-R.vim"
    cquit!
endif

echo "=========================================="
echo "         zzvim-R CI Test Suite"
echo "=========================================="

let failed_tests = 0

" Test 1: Plugin loads successfully
if exists('g:loaded_zzvim_r') && g:loaded_zzvim_r == 1
    echo "✓ PASS | Plugin loaded successfully"
else
    echo "✗ FAIL | Plugin failed to load"
    let failed_tests += 1
endif

" Test 2: Version variable exists
if exists('g:zzvim_r_version')
    echo "✓ PASS | Version variable exists: " . g:zzvim_r_version
else
    echo "✗ FAIL | Version variable missing"
    let failed_tests += 1
endif

" Test 3: Vim version compatibility
if v:version >= 800
    echo "✓ PASS | Vim version compatible: " . v:version
else
    echo "✗ FAIL | Vim version too old: " . v:version
    let failed_tests += 1
endif

" Test 4: Basic configuration variables exist
let config_vars = ['zzvim_r_command', 'zzvim_r_chunk_start', 'zzvim_r_chunk_end']
for var in config_vars
    if exists('g:' . var)
        echo "✓ PASS | Config variable exists: g:" . var
    else
        echo "✗ FAIL | Config variable missing: g:" . var
        let failed_tests += 1
    endif
endfor

" Test 5: Test helper functions exist
let test_functions = ['ZzvimRTestIsBlockStart', 'ZzvimRTestGetTextByType']
for func in test_functions
    if exists('*' . func)
        echo "✓ PASS | Test function exists: " . func
    else
        echo "✗ FAIL | Test function missing: " . func
        let failed_tests += 1
    endif
endfor

" Test 6: Basic pattern matching
if exists('*ZzvimRTestIsBlockStart')
    let test_line = 'my_func <- function(x) {'
    let result = ZzvimRTestIsBlockStart(test_line)
    if result == 1
        echo "✓ PASS | Pattern matching works for function definition"
    else
        echo "✗ FAIL | Pattern matching failed for function definition"
        let failed_tests += 1
    endif
else
    echo "✗ FAIL | Cannot test pattern matching - function missing"
    let failed_tests += 1
endif

echo "=========================================="
if failed_tests == 0
    echo "🎉 ALL CI TESTS PASSED! (" . (7 + len(config_vars) + len(test_functions)) . " tests)"
    echo "Plugin is ready for production use."
    qall!
else
    echo "❌ " . failed_tests . " TEST(S) FAILED!"
    echo "Plugin needs fixes before deployment."
    cquit!
endif