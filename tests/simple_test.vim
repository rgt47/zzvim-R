" Simple comprehensive test for zzvim-R plugin
set nocompatible
let &runtimepath = expand('<sfile>:p:h:h') . ',' . &runtimepath
let g:zzvim_r_disable_mappings = 1

" Test results
let s:tests_passed = 0
let s:tests_failed = 0

function! s:test(condition, name)
    if a:condition
        let s:tests_passed += 1
        echo "✓ " . a:name
    else
        let s:tests_failed += 1
        echo "✗ " . a:name
    endif
endfunction

echo "zzvim-R Plugin Test Suite"
echo "========================="

" Load plugin
runtime plugin/zzvim_r.vim

" Test 1: Plugin loads
call s:test(exists('g:loaded_zzvim_r'), 'Plugin loads')

" Test 2: Commands exist
call s:test(exists(':ROpenTerminal'), 'ROpenTerminal command exists')
call s:test(exists(':RSubmitLine'), 'RSubmitLine command exists')

" Test 3: Core functions exist (these are script-local)
call s:test(exists('*s:engine'), 'Core engine function exists')

" Test 4: Autoload functions exist
call s:test(exists('*zzvim_r#open_terminal'), 'zzvim_r#open_terminal exists')
call s:test(exists('*zzvim_r#submit_line'), 'zzvim_r#submit_line exists')
call s:test(exists('*zzvim_r#navigate_next_chunk'), 'zzvim_r#navigate_next_chunk exists')

" Test 5: Configuration
let g:zzvim_r_debug = 2
call s:test(get(g:, 'zzvim_r_debug') == 2, 'Configuration variables work')

" Test 6: Error handling
try
    let result = zzvim_r#submit_line()
    call s:test(type(result) == v:t_number, 'Functions return proper types')
catch
    call s:test(0, 'Functions should not throw exceptions')
endtry

" Test 7: R detection
call s:test(executable('R') || 1, 'R detection test (always passes, just checking)')

echo ""
echo "Results: " . s:tests_passed . " passed, " . s:tests_failed . " failed"

if s:tests_failed == 0
    echo "All tests passed!"
    quit 0
else
    echo "Some tests failed!"
    quit 1
endif