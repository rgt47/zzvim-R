" Fresh test with minimal dependencies
" Force fresh load
unlet! g:loaded_zzvim_r

" Source plugin
source plugin/zzvim-R.vim

" Minimal test
echo "=== Fresh Test Results ==="

" Test 1: Basic loading
echo "Plugin version: " . get(g:, 'zzvim_r_version', 'NOT FOUND')
echo "Plugin loaded: " . get(g:, 'loaded_zzvim_r', 'NOT FOUND')

" Test 2: Configuration (optimized version)
echo "Config width: " . get(g:, 'zzvim_r_terminal_width', 'NOT FOUND')

" Test 3: Test wrapper function
if exists('*ZzvimRTestIsBlockStart')
    echo "Test function exists: YES"
    " Direct pattern test
    let result = ZzvimRTestIsBlockStart('library(pacman)')
    echo "Pattern test result: " . result
else
    echo "Test function exists: NO"
endif

echo "=== End Fresh Test ==="