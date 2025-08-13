" Simple verification of multi-terminal support
echo "=== Multi-Terminal Verification ==="

" Clean plugin load
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

" Test 1: Terminal naming function
new
write /tmp/test1.R
let name1 = ZzvimRTestGetTerminalName()
echo "Terminal name for test1.R: " . name1

" Test 2: Different buffer, different name
new
write /tmp/test2.R  
let name2 = ZzvimRTestGetTerminalName()
echo "Terminal name for test2.R: " . name2

" Test 3: Verify they're different
if name1 != name2
    echo "✓ PASS - Different files get different terminal names"
else
    echo "✗ FAIL - Terminal names are the same"
endif

" Test 4: Check buffer-specific terminal function exists
if exists('*ZzvimRTestGetBufferTerminal')
    echo "✓ PASS - GetBufferTerminal function exists"
else
    echo "✗ FAIL - GetBufferTerminal function missing"
endif

echo "=== Verification Complete ==="

" Clean up
bdelete! /tmp/test1.R
bdelete! /tmp/test2.R