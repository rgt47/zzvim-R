" Simple pattern verification script

" Test the regex patterns manually
function! VerifyPatterns()
    let test_cases = [
        \ ['my_func <- function(x) {', '.*function\\s*(', 'should match'],
        \ ['if (x > 0) {', '^\\s*if\\s*(', 'should match'],
        \ ['  for (i in 1:10) {', '^\\s*for\\s*(', 'should match'],  
        \ ['while (condition) {', '^\\s*while\\s*(', 'should match'],
        \ ['  {', '^\\s*{', 'should match'],
        \ ['x <- 5', '.*function\\s*(', 'should NOT match'],
        \ ['  result <- x + y', '^\\s*if\\s*(', 'should NOT match']
    \ ]
    
    echo "Pattern Verification Results:"
    echo "============================="
    
    for [line, pattern, expected] in test_cases
        let matches = line =~# pattern
        let result = matches ? 'MATCHES' : 'NO MATCH'
        let status = (matches && expected =~# 'should match') || (!matches && expected =~# 'NOT') ? '✓' : '✗'
        echo printf("%s | Pattern: %-20s | Line: %-25s | %s", status, pattern, line, result)
    endfor
endfunction

call VerifyPatterns()