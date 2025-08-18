" Test final clean execution system
echo "=== TESTING FINAL CLEAN EXECUTION ==="

" Load current version
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "Testing final clean approach:"
echo "- Single lines: direct transmission"  
echo "- Small blocks (≤5 lines): line-by-line with delays"
echo "- Large blocks (>5 lines): minimal source('file',F)"

" Test with actual R file  
try
    RSendSmart
    echo "✅ Clean execution active - check R terminal for clean output"
catch
    echo "❌ Execution failed: " . v:exception
endtry

echo ""
echo "Expected improvements:"
echo "✅ No more: source('/var/folders/.../temp123', echo=T)"  
echo "✅ Instead: direct code or minimal source('file',F)"
echo "✅ Much cleaner terminal experience"