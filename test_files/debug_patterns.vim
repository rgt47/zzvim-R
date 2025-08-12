" Debug pattern matching issues

function! TestPatterns()
    echo "Testing current s:IsBlockStart patterns..."
    
    " Test cases from the comprehensive test
    let test_cases = [
        \ ['my_func <- function(x) {', 1, 'Function definition'],
        \ ['  function(data) {', 1, 'Anonymous function'],
        \ ['if (x > 0) {', 1, 'If statement'],
        \ ['  for (i in 1:10) {', 1, 'For loop'],
        \ ['while (condition) {', 1, 'While loop'],
        \ ['repeat {', 1, 'Repeat loop'],
        \ ['  {', 1, 'Standalone block'],
        \ ['x <- 5', 0, 'Simple assignment'],
        \ ['  result <- x + y', 0, 'Assignment inside block'],
        \ ['print(x)', 0, 'Function call']
    \ ]
    
    echo "Testing with current optimized pattern:"
    let optimized_pattern = '\v(.*function\s*\(|^\s*(if|for|while)\s*\(|^\s*(repeat\s*)?\{)'
    
    for [line, expected, description] in test_cases
        let result = line =~# optimized_pattern ? 1 : 0
        let status = result == expected ? '✓' : '✗'
        echo printf("%s | Pattern: %s | Line: %-30s | Expected: %d, Got: %d", 
               \ status, optimized_pattern, line, expected, result)
    endfor
    
    echo ""
    echo "Testing with individual patterns:"
    
    " Test individual patterns
    for [line, expected, description] in test_cases
        echo "Testing: " . line
        
        " Function pattern
        let func_match = line =~# '.*function\s*(' ? 1 : 0
        echo "  Function pattern (.*function\\s*(): " . func_match
        
        " Control structure patterns
        let if_match = line =~# '^\s*if\s*(' ? 1 : 0
        let for_match = line =~# '^\s*for\s*(' ? 1 : 0
        let while_match = line =~# '^\s*while\s*(' ? 1 : 0
        echo "  Control patterns (if/for/while): " . (if_match || for_match || while_match)
        
        " Block patterns
        let repeat_match = line =~# '^\s*repeat\s*{' ? 1 : 0
        let standalone_match = line =~# '^\s*{' ? 1 : 0
        echo "  Block patterns (repeat/{): " . (repeat_match || standalone_match)
        
        let total_match = func_match || if_match || for_match || while_match || repeat_match || standalone_match
        echo "  Total match: " . total_match . " (expected: " . expected . ")"
        echo ""
    endfor
endfunction

call TestPatterns()