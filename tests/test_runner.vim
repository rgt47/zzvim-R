" ==============================================================================
" zzvim-R Test Runner
" ==============================================================================
" This file runs all tests for the zzvim-R plugin
" Usage: vim -u NONE -S tests/test_runner.vim

" Set up minimal environment
set nocompatible
filetype plugin indent on
syntax on

" Add plugin to runtime path
let &runtimepath = expand('<sfile>:p:h:h') . ',' . &runtimepath

" Load the plugin manually
let g:zzvim_r_disable_mappings = 1  " Disable mappings for testing
runtime plugin/zzvim_r.vim

" Test results tracking
let g:test_results = {'passed': 0, 'failed': 0, 'errors': []}

" Test framework functions
function! Assert(condition, message) abort
    if a:condition
        let g:test_results.passed += 1
        echo "✓ " . a:message
    else
        let g:test_results.failed += 1
        call add(g:test_results.errors, a:message)
        echo "✗ " . a:message
    endif
endfunction

function! AssertEqual(expected, actual, message) abort
    if a:expected ==# a:actual
        call Assert(1, a:message)
    else
        call Assert(0, a:message . " (expected: " . string(a:expected) . ", got: " . string(a:actual) . ")")
    endif
endfunction

function! AssertExists(funcname, message) abort
    call Assert(exists('*' . a:funcname), a:message)
endfunction

function! RunTest(testfile) abort
    echo ""
    echo "Running " . a:testfile . "..."
    echo "----------------------------------------"
    try
        execute 'source ' . a:testfile
    catch
        let g:test_results.failed += 1
        call add(g:test_results.errors, "Failed to run " . a:testfile . ": " . v:exception)
        echo "✗ Failed to run " . a:testfile . ": " . v:exception
    endtry
endfunction

" Run all tests
echo "zzvim-R Plugin Test Suite"
echo "=========================="

" Unit tests
call RunTest('tests/unit/test_configuration.vim')
call RunTest('tests/unit/test_functions.vim')

" Integration tests (only if R is available)
if executable('R')
    call RunTest('tests/integration/test_basic_functionality.vim')
else
    echo ""
    echo "⚠ Skipping integration tests (R not found in PATH)"
endif

" Print results
echo ""
echo "Test Results:"
echo "============="
echo "Passed: " . g:test_results.passed
echo "Failed: " . g:test_results.failed

if g:test_results.failed > 0
    echo ""
    echo "Failures:"
    for error in g:test_results.errors
        echo "  - " . error
    endfor
    quit 1
else
    echo "All tests passed!"
    quit 0
endif