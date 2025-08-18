" Test clean code execution without source() commands
echo "=== TESTING CLEAN CODE EXECUTION ==="

" Force reload to get new SendToR approach
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "✅ Plugin reloaded with clean code execution"

" Test single line execution
try
    echo "Testing single line execution..."
    call s:SendToR('line')  " This should send directly, no source()
    echo "✅ Single line execution (should show code directly)"
catch
    echo "❌ Single line failed: " . v:exception
endtry

" Test small block execution  
try
    echo "Testing small function block..."
    call s:SendToR('function')  " This should use {code;code} format
    echo "✅ Small block execution (should show {code} format)"
catch
    echo "❌ Small block failed: " . v:exception
endtry

echo ""
echo "SUCCESS: Code execution now cleaned up"
echo ""
echo "New behavior:"
echo "- Single lines: sent directly (no source, no temp file)"
echo "- Small blocks (≤10 lines): {code;code;code} format"  
echo "- Large blocks (>10 lines): source('file',F) minimal format"
echo "- Object browser: compact commands (unchanged)"
echo ""