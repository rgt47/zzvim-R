" Comprehensive test suite for block matching functionality
" Tests both parenthesis () and brace {} matching in s:GetCodeBlock()

" Load the plugin
source plugin/zzvim-R.vim

" Test helper functions for accessing plugin internals
function! ZzvimRTestGetCodeBlock() abort
    " Direct access to the s:GetCodeBlock function for testing
    return s:GetCodeBlock()
endfunction

function! ZzvimRTestIsBlockStart(line) abort
    " Direct access to the s:IsBlockStart function for testing  
    return s:IsBlockStart(a:line)
endfunction

" Test parenthesis matching
function! TestParenthesisMatching()
    echo "=========================================="
    echo "Testing Parenthesis Matching"
    echo "=========================================="
    
    let passed = 0
    let total = 0
    
    " Test Case 1: Simple single-line function call
    new
    call setline(1, ['library(pacman)'])
    call cursor(1, 1)
    let result = ZzvimRTestGetCodeBlock()
    let expected = ['library(pacman)']
    let test1 = result == expected
    let total += 1
    let passed += test1 ? 1 : 0
    echo printf("%s | Single-line function call: %s", test1 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    " Test Case 2: Multi-line function call
    new
    call setline(1, [
        \ 'p_load(',
        \ '  dplyr,',
        \ '  ggplot2',
        \ ')'
    \ ])
    call cursor(1, 1)
    let result = ZzvimRTestGetCodeBlock()
    let expected = ['p_load(', '  dplyr,', '  ggplot2', ')']
    let test2 = result == expected
    let total += 1
    let passed += test2 ? 1 : 0
    echo printf("%s | Multi-line function call: %s", test2 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    " Test Case 3: Nested parentheses
    new
    call setline(1, [
        \ 'outer_func(',
        \ '  inner_func(x, y),',
        \ '  z',
        \ ')'
    \ ])
    call cursor(1, 1)
    let result = ZzvimRTestGetCodeBlock()
    let expected = ['outer_func(', '  inner_func(x, y),', '  z', ')']
    let test3 = result == expected
    let total += 1
    let passed += test3 ? 1 : 0
    echo printf("%s | Nested parentheses: %s", test3 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    " Test Case 4: Function call inside function definition (should detect parens)
    new
    call setline(1, [
        \ 'bb = function(x){',
        \ '  library(pacman)',
        \ '  p_load(dplyr)',
        \ '}'
    \ ])
    call cursor(2, 1)  " Position on library(pacman) line
    let result = ZzvimRTestGetCodeBlock()
    let expected = ['  library(pacman)']
    let test4 = result == expected
    let total += 1
    let passed += test4 ? 1 : 0
    echo printf("%s | Function call inside function: %s", test4 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    " Test Case 5: Multi-line function call inside function definition
    new
    call setline(1, [
        \ 'bb = function(x){',
        \ '  p_load(',
        \ '    ggplot2',
        \ '  )',
        \ '}'
    \ ])
    call cursor(2, 1)  " Position on p_load( line
    let result = ZzvimRTestGetCodeBlock()
    let expected = ['  p_load(', '    ggplot2', '  )']
    let test5 = result == expected
    let total += 1
    let passed += test5 ? 1 : 0
    echo printf("%s | Multi-line call inside function: %s", test5 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    echo ""
    echo printf("Parenthesis Matching: %d/%d tests passed", passed, total)
    echo ""
    return passed == total
endfunction

" Test brace matching
function! TestBraceMatching()
    echo "=========================================="
    echo "Testing Brace Matching"
    echo "=========================================="
    
    let passed = 0
    let total = 0
    
    " Test Case 1: Simple function definition
    new
    call setline(1, [
        \ 'my_func <- function(x) {',
        \ '  result <- x * 2',
        \ '  return(result)',
        \ '}'
    \ ])
    call cursor(1, 1)
    let result = ZzvimRTestGetCodeBlock()
    let expected = ['my_func <- function(x) {', '  result <- x * 2', '  return(result)', '}']
    let test1 = result == expected
    let total += 1
    let passed += test1 ? 1 : 0
    echo printf("%s | Function definition: %s", test1 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    " Test Case 2: If statement
    new
    call setline(1, [
        \ 'if (x > 0) {',
        \ '  print("positive")',
        \ '} else {',
        \ '  print("negative")',
        \ '}'
    \ ])
    call cursor(1, 1)
    let result = ZzvimRTestGetCodeBlock()
    let expected = ['if (x > 0) {', '  print("positive")', '} else {', '  print("negative")', '}']
    let test2 = result == expected
    let total += 1
    let passed += test2 ? 1 : 0
    echo printf("%s | If-else statement: %s", test2 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    " Test Case 3: Nested functions
    new
    call setline(1, [
        \ 'outer_func <- function(x) {',
        \ '  inner_func <- function(y) {',
        \ '    return(y * 2)',
        \ '  }',
        \ '  return(inner_func(x))',
        \ '}'
    \ ])
    call cursor(1, 1)
    let result = ZzvimRTestGetCodeBlock()
    let expected = ['outer_func <- function(x) {', '  inner_func <- function(y) {', '    return(y * 2)', '  }', '  return(inner_func(x))', '}']
    let test3 = result == expected
    let total += 1
    let passed += test3 ? 1 : 0
    echo printf("%s | Nested functions: %s", test3 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    " Test Case 4: For loop
    new
    call setline(1, [
        \ 'for (i in 1:10) {',
        \ '  print(i)',
        \ '  if (i > 5) {',
        \ '    break',
        \ '  }',
        \ '}'
    \ ])
    call cursor(1, 1)
    let result = ZzvimRTestGetCodeBlock()
    let expected = ['for (i in 1:10) {', '  print(i)', '  if (i > 5) {', '    break', '  }', '}']
    let test4 = result == expected
    let total += 1
    let passed += test4 ? 1 : 0
    echo printf("%s | For loop with nested if: %s", test4 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    echo ""
    echo printf("Brace Matching: %d/%d tests passed", passed, total)
    echo ""
    return passed == total
endfunction

" Test mixed parentheses and braces
function! TestMixedMatching()
    echo "=========================================="
    echo "Testing Mixed Paren/Brace Matching"
    echo "=========================================="
    
    let passed = 0
    let total = 0
    
    " Test Case 1: Function definition with both () and {} on same line (should prioritize braces)
    new
    call setline(1, [
        \ 'if (x > 0) { print("test") }',
        \ 'another_line()'
    \ ])
    call cursor(1, 1)
    let result = ZzvimRTestGetCodeBlock()
    let expected = ['if (x > 0) { print("test") }']
    let test1 = result == expected
    let total += 1
    let passed += test1 ? 1 : 0
    echo printf("%s | Mixed chars - prioritize braces: %s", test1 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    " Test Case 2: Function call with parentheses only (no braces on line)
    new
    call setline(1, [
        \ 'data.frame(',
        \ '  x = 1:5,',
        \ '  y = letters[1:5]',
        \ ')'
    \ ])
    call cursor(1, 1)
    let result = ZzvimRTestGetCodeBlock()
    let expected = ['data.frame(', '  x = 1:5,', '  y = letters[1:5]', ')']
    let test2 = result == expected
    let total += 1
    let passed += test2 ? 1 : 0
    echo printf("%s | Parentheses only: %s", test2 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    " Test Case 3: Cursor inside function on line with parentheses
    new
    call setline(1, [
        \ 'my_func <- function(x) {',
        \ '  result <- some_func(x, y)',
        \ '  return(result)',
        \ '}'
    \ ])
    call cursor(2, 1)  " Position on some_func(x, y) line
    let result = ZzvimRTestGetCodeBlock()
    let expected = ['  result <- some_func(x, y)']
    let test3 = result == expected
    let total += 1
    let passed += test3 ? 1 : 0
    echo printf("%s | Parens inside brace block: %s", test3 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    echo ""
    echo printf("Mixed Matching: %d/%d tests passed", passed, total)
    echo ""
    return passed == total
endfunction

" Test error handling for malformed code
function! TestErrorHandling()
    echo "=========================================="
    echo "Testing Error Handling"
    echo "=========================================="
    
    let passed = 0
    let total = 0
    
    " Test Case 1: Missing closing parenthesis
    new
    call setline(1, [
        \ 'p_load(dplyr',
        \ 'another_line'
    \ ])
    call cursor(1, 1)
    let result = ZzvimRTestGetCodeBlock()
    let expected = []  " Should return empty list on error
    let test1 = result == expected
    let total += 1
    let passed += test1 ? 1 : 0
    echo printf("%s | Missing closing paren: %s", test1 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    " Test Case 2: Missing closing brace
    new
    call setline(1, [
        \ 'if (x > 0) {',
        \ '  print("test")',
        \ 'another_line'
    \ ])
    call cursor(1, 1)
    let result = ZzvimRTestGetCodeBlock()
    let expected = []  " Should return empty list on error
    let test2 = result == expected
    let total += 1
    let passed += test2 ? 1 : 0
    echo printf("%s | Missing closing brace: %s", test2 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    " Test Case 3: No opening character found
    new
    call setline(1, [
        \ 'simple_assignment <- 5',
        \ 'another_assignment <- 10'
    \ ])
    call cursor(1, 1)
    let result = ZzvimRTestGetCodeBlock()
    let expected = []  " Should return empty list on error
    let test3 = result == expected
    let total += 1
    let passed += test3 ? 1 : 0
    echo printf("%s | No opening character: %s", test3 ? '✓ PASS' : '✗ FAIL', string(result))
    bdelete!
    
    echo ""
    echo printf("Error Handling: %d/%d tests passed", passed, total)
    echo ""
    return passed == total
endfunction

" Test pattern recognition for IsBlockStart
function! TestPatternRecognition()
    echo "=========================================="
    echo "Testing Pattern Recognition"
    echo "=========================================="
    
    let passed = 0
    let total = 0
    
    let test_cases = [
        \ ['library(pacman)', 1, 'Function call with parens'],
        \ ['p_load(dplyr)', 1, 'Function call with parens'],
        \ ['data.frame(', 1, 'Multi-line function call start'],
        \ ['ggplot(data = mtcars,', 1, 'ggplot function call'],
        \ ['my_func <- function(x) {', 1, 'Function definition'],
        \ ['if (x > 0) {', 1, 'If statement'],
        \ ['for (i in 1:10) {', 1, 'For loop'],
        \ ['while (condition) {', 1, 'While loop'],
        \ ['repeat {', 1, 'Repeat loop'],
        \ ['{', 1, 'Standalone block'],
        \ ['x <- 5', 0, 'Simple assignment'],
        \ ['result <- x + y', 0, 'Assignment without parens/braces'],
        \ ['# This is a comment', 0, 'Comment line'],
        \ ['', 0, 'Empty line']
    \ ]
    
    for i in range(len(test_cases))
        let [line, expected, description] = test_cases[i]
        let result = ZzvimRTestIsBlockStart(line)
        let test_passed = result == expected
        let total += 1
        let passed += test_passed ? 1 : 0
        echo printf("%s | %-35s | Expected: %d, Got: %d", 
                    \ test_passed ? '✓ PASS' : '✗ FAIL', 
                    \ description, expected, result)
    endfor
    
    echo ""
    echo printf("Pattern Recognition: %d/%d tests passed", passed, total)
    echo ""
    return passed == total
endfunction

" Main test runner for block matching
function! RunBlockMatchingTests()
    echo "=========================================="
    echo "    Block Matching Test Suite"
    echo "=========================================="
    echo ""
    
    let test_results = []
    
    " Run all test suites
    call add(test_results, TestPatternRecognition())
    call add(test_results, TestParenthesisMatching())
    call add(test_results, TestBraceMatching())
    call add(test_results, TestMixedMatching())
    call add(test_results, TestErrorHandling())
    
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
        echo "🎉 ALL BLOCK MATCHING TESTS PASSED!"
    else
        echo "⚠️  Some block matching tests failed."
    endif
    echo "=========================================="
    
    return passed_suites == len(test_results)
endfunction

" Auto-run when sourced
call RunBlockMatchingTests()