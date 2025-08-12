" Test script for the generalized SendToR functions
" Source this file in Vim to test the functions

" Test the pattern matching function
function! TestIsBlockStart()
    echo "Testing s:IsBlockStart()..."
    
    " Test function detection
    let test_lines = [
        \ 'my_func <- function(x, y) {',
        \ '  function(data) {',
        \ 'if (x > 0) {',
        \ 'for (i in 1:10) {',
        \ 'while (condition) {',
        \ '  {',
        \ 'x <- 5',
        \ '  result <- x + y'
    \ ]
    
    let expected = [1, 1, 1, 1, 1, 1, 0, 0]
    
    for i in range(len(test_lines))
        let result = s:IsBlockStart(test_lines[i])
        let status = result == expected[i] ? 'PASS' : 'FAIL'
        echo printf("Line: %-25s Expected: %d Got: %d [%s]", 
                   \ test_lines[i], expected[i], result, status)
    endfor
    echo ""
endfunction

" Test text extraction for simple cases
function! TestGetTextByType()
    echo "Testing s:GetTextByType()..."
    
    " Test line extraction
    call cursor(1, 1)
    let result = s:GetTextByType('line')
    echo "Line extraction: " . string(result)
    
    " Test default behavior
    let result = s:GetTextByType('')
    echo "Default behavior: " . string(result)
    echo ""
endfunction

" Test the complete workflow
function! TestCompleteWorkflow()
    echo "Testing complete workflow..."
    echo "Open the test file: :e test_files/test_generalized_send.R"
    echo "Then position cursor on different lines and call:"
    echo "  :call s:SendToR('')  (for smart detection)"
    echo "  :call s:SendToR('line')  (for current line)"
    echo "  :call s:SendToR('function')  (for function block)"
    echo ""
endfunction

" Run all tests
function! RunAllTests()
    echo "===================="
    echo "Testing GeneralizedSendToR Functions"
    echo "===================="
    echo ""
    
    call TestIsBlockStart()
    call TestGetTextByType() 
    call TestCompleteWorkflow()
    
    echo "===================="
    echo "Tests completed!"
    echo "===================="
endfunction

" Auto-run tests when sourcing this file
call RunAllTests()