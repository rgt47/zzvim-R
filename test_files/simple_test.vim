" Simple test for pattern matching

function! SimpleTest()
    echo "Testing basic patterns:"
    
    " Test function pattern
    let line1 = 'my_func <- function(x) {'
    let pattern1 = '.*function\s*('
    echo "Line: " . line1
    echo "Pattern: " . pattern1  
    echo "Match: " . (line1 =~# pattern1 ? 'YES' : 'NO')
    echo ""
    
    " Test if pattern  
    let line2 = 'if (x > 0) {'
    let pattern2 = '^\s*if\s*('
    echo "Line: " . line2
    echo "Pattern: " . pattern2
    echo "Match: " . (line2 =~# pattern2 ? 'YES' : 'NO')
    echo ""
    
    " Test non-matching line
    let line3 = 'x <- 5'
    echo "Line: " . line3  
    echo "Pattern: " . pattern1
    echo "Match: " . (line3 =~# pattern1 ? 'YES' : 'NO')
endfunction

call SimpleTest()