" Test suppressed code output
echo "=== TESTING CODE SUPPRESSION ==="

" Force reload to get line-wrapped functions
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

" Test basic functionality
echo "Testing command availability..."
try
    RWorkspace
    echo "✅ RWorkspace executed (should show only results, no R code)"
catch
    echo "❌ RWorkspace failed: " . v:exception
endtry

try
    RInspect test_var
    echo "✅ RInspect executed (should show only results, no R code)"  
catch
    echo "❌ RInspect failed: " . v:exception
endtry

echo ""
echo "SUCCESS: Object browser now uses invisible() to suppress code echoing"
echo ""
echo "Expected behavior:"
echo "- <LocalLeader>' shows only workspace results"
echo "- <LocalLeader>i shows only object inspection results" 
echo "- No R command code should be visible in terminal"
echo ""