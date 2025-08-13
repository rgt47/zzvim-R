" Direct test without sourcing the plugin
function! TestIsBlockStart(line) abort
    " Function calls - any identifier followed by opening parenthesis
    if a:line =~# '[a-zA-Z_][a-zA-Z0-9_.]*\s*('
        return 1
    endif
    return 0
endfunction

echo "Direct test result: " . TestIsBlockStart('library(pacman)')
echo "Direct test result: " . TestIsBlockStart('p_load(dplyr)')
echo "Direct test result: " . TestIsBlockStart('x <- 5')