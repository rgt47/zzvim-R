" Comprehensive test suite for zzvim-R plugin
" This script tests all major functionality

" Load the plugin (handle relative path)
if filereadable('plugin/zzvim-R.vim')
    source plugin/zzvim-R.vim
elseif filereadable('../plugin/zzvim-R.vim')
    source ../plugin/zzvim-R.vim
else
    echo "Error: Cannot find plugin/zzvim-R.vim"
    cquit!
endif

" Test pattern matching function
function! TestPatternMatching()
    echo "=========================================="
    echo "Testing Pattern Matching (s:IsBlockStart)"
    echo "=========================================="
    
    let test_cases = [
        \ ['my_func <- function(x) {', 1, 'Function definition'],
        \ ['  function(data) {', 1, 'Anonymous function'],
        \ ['if (x > 0) {', 1, 'If statement'],
        \ ['  for (i in 1:10) {', 1, 'For loop'],
        \ ['while (condition) {', 1, 'While loop'],
        \ ['repeat {', 1, 'Repeat loop'],
        \ ['  {', 1, 'Standalone block'],
        \ ['library(pacman)', 1, 'Function call with parentheses'],
        \ ['p_load(dplyr)', 1, 'Package load function call'],
        \ ['data.frame(', 1, 'Multi-line function call start'],
        \ ['x <- 5', 0, 'Simple assignment'],
        \ ['  result <- x + y', 0, 'Assignment inside block'],
        \ ['# Comment line', 0, 'Comment line']
    \ ]
    
    let passed = 0
    let total = len(test_cases)
    
    for i in range(len(test_cases))
        let [line, expected, description] = test_cases[i]
        let result = ZzvimRTestIsBlockStart(line)
        let status = result == expected ? '✓ PASS' : '✗ FAIL'
        let passed += result == expected ? 1 : 0
        echo printf("%s | %-30s | Expected: %d, Got: %d", status, description, expected, result)
    endfor
    
    echo ""
    echo printf("Pattern Matching: %d/%d tests passed", passed, total)
    echo ""
    return passed == total
endfunction

" Test text extraction functions
function! TestTextExtraction()
    echo "=========================================="
    echo "Testing Text Extraction Functions"
    echo "=========================================="
    
    " Create a test buffer with known content
    new
    call setline(1, ['# Test file', 'x <- 5', 'y <- 10', 'print(x + y)'])
    
    " Test line extraction
    call cursor(2, 1)
    let result = ZzvimRTestGetTextByType('line')
    let expected = ['x <- 5']
    let line_test = result == expected
    echo printf("%s | Line extraction: %s", line_test ? '✓ PASS' : '✗ FAIL', string(result))
    
    " Test default behavior (should be same as line for non-block)
    let result2 = ZzvimRTestGetTextByType('')
    let default_test = result2 == expected
    echo printf("%s | Default behavior: %s", default_test ? '✓ PASS' : '✗ FAIL', string(result2))
    
    " Clean up
    bdelete!
    
    echo ""
    echo printf("Text Extraction: %d/2 tests passed", (line_test + default_test))
    echo ""
    return line_test && default_test
endfunction

" Test configuration access
function! TestConfiguration()
    echo "=========================================="
    echo "Testing Configuration Access"
    echo "=========================================="
    
    " Test version variable exists
    let version_test = exists('g:zzvim_r_version')
    echo printf("%s | Version variable exists: %s", version_test ? '✓ PASS' : '✗ FAIL', get(g:, 'zzvim_r_version', 'NOT FOUND'))
    
    " Test plugin loaded variable
    let loaded_test = exists('g:loaded_zzvim_r') && g:loaded_zzvim_r == 1
    echo printf("%s | Plugin loaded variable: %s", loaded_test ? '✓ PASS' : '✗ FAIL', get(g:, 'loaded_zzvim_r', 'NOT FOUND'))
    
    " Test default configuration variables
    let config_tests = [
        \ ['g:zzvim_r_terminal_width', 100],
        \ ['g:zzvim_r_command', 'R --no-save --quiet'],
        \ ['g:zzvim_r_chunk_start', '^```{'],
        \ ['g:zzvim_r_chunk_end', '^```$'],
        \ ['g:zzvim_r_debug', 0]
    \ ]
    
    let config_passed = 0
    for [var_name, expected_value] in config_tests
        let actual_value = get(g:, substitute(var_name, 'g:', '', ''), 'NOT_SET')
        let test_passed = actual_value == expected_value
        let config_passed += test_passed ? 1 : 0
        echo printf("%s | %s = %s", test_passed ? '✓ PASS' : '✗ FAIL', var_name, string(actual_value))
    endfor
    
    echo ""
    echo printf("Configuration: %d/%d tests passed", (version_test + loaded_test + config_passed), (2 + len(config_tests)))
    echo ""
    return version_test && loaded_test && (config_passed == len(config_tests))
endfunction

" Test Ex commands exist
function! TestCommands()
    echo "=========================================="
    echo "Testing Ex Commands"
    echo "=========================================="
    
    let commands = [
        \ 'ROpenTerminal', 'RSendLine', 'RSendFunction', 'RSendSmart',
        \ 'RNextChunk', 'RPrevChunk', 'RSendChunk', 'RSendPreviousChunks',
        \ 'RHead', 'RStr', 'RDim', 'RPrint', 'RNames', 'RLength',
        \ 'RHelp', 'RSummary', 'RQuit', 'RInterrupt',
        \ 'RSend', 'RSource', 'RLibrary', 'RInstall', 'RSetwd', 'RGetwd'
    \ ]
    
    let command_passed = 0
    for cmd in commands
        " Check if command exists by trying to get its definition
        try
            execute 'command' cmd
            let command_passed += 1
            echo printf("✓ PASS | Command :%s exists", cmd)
        catch /E184:/
            echo printf("✗ FAIL | Command :%s not found", cmd)
        endtry
    endfor
    
    echo ""
    echo printf("Ex Commands: %d/%d tests passed", command_passed, len(commands))
    echo ""
    return command_passed == len(commands)
endfunction

" Test Vim version compatibility
function! TestCompatibility()
    echo "=========================================="
    echo "Testing Vim Compatibility"
    echo "=========================================="
    
    " Test Vim version
    let version_ok = v:version >= 800
    echo printf("%s | Vim version >= 8.0: %d", version_ok ? '✓ PASS' : '✗ FAIL', v:version)
    
    " Test terminal support (optional in CI)
    let terminal_ok = has('terminal')
    echo printf("%s | Terminal support: %s", terminal_ok ? '✓ PASS' : '⚠ SKIP', has('terminal') ? 'available' : 'missing (CI mode)')
    
    " Test job support (used by plugin)
    let job_ok = has('job')
    echo printf("%s | Job support: %s", job_ok ? '✓ PASS' : '✗ FAIL', has('job') ? 'available' : 'missing')
    
    " In CI mode, terminal support is optional
    let is_ci = exists('$CI') || exists('$GITHUB_ACTIONS')
    let required_tests = is_ci ? 2 : 3
    let passed_tests = version_ok + (is_ci ? 0 : terminal_ok) + job_ok
    
    echo ""
    echo printf("Compatibility: %d/%d tests passed%s", passed_tests, required_tests, is_ci ? ' (CI mode)' : '')
    echo ""
    return passed_tests == required_tests
endfunction

" Main test runner
function! RunComprehensiveTests()
    echo "=========================================="""
    echo "    zzvim-R Comprehensive Test Suite"
    echo "=========================================="
    echo ""
    
    let test_results = []
    
    " Run all test suites
    call add(test_results, TestCompatibility())
    call add(test_results, TestConfiguration())
    call add(test_results, TestCommands())
    call add(test_results, TestPatternMatching())
    call add(test_results, TestTextExtraction())
    
    " Note: For detailed block matching tests, run:
    " :source test_files/test_block_matching.vim
    echo ""
    echo "💡 For comprehensive block matching tests, run:"
    echo "   :source test_files/test_block_matching.vim"
    
    " Summary
    let passed_suites = 0
    for result in test_results
        let passed_suites += result ? 1 : 0
    endfor
    
    echo "=========================================="
    echo "              FINAL RESULTS"
    echo "=========================================="
    echo printf("Test Suites Passed: %d/%d", passed_suites, len(test_results))
    
    if passed_suites == len(test_results)
        echo "🎉 ALL TESTS PASSED! Plugin is working correctly."
    else
        echo "⚠️  Some tests failed. Please review the results above."
    endif
    echo "=========================================="
    
    return passed_suites == len(test_results)
endfunction

" Auto-run when sourced
let test_result = RunComprehensiveTests()

" Exit with proper code for CI
if test_result
    qall!
else
    cquit!
endif