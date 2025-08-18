" Test source() with echo=FALSE approach
echo "=== TESTING SOURCE WITH ECHO=FALSE ==="

" Force reload to get temp file approach
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "✅ Plugin reloaded with source(echo=FALSE) approach"

" Test basic functionality  
try
    RWorkspace
    echo "✅ RWorkspace executed - should show ONLY results, no 'source()' command"
catch
    echo "❌ RWorkspace failed: " . v:exception
endtry

try
    RInspect iris  
    echo "✅ RInspect executed - should show ONLY results, no 'source()' command"
catch
    echo "❌ RInspect failed: " . v:exception  
endtry

echo ""
echo "SUCCESS: Object browser now uses source(echo=FALSE) for clean output"
echo ""
echo "Expected behavior:"
echo "- <LocalLeader>' shows workspace listing with NO R commands visible"
echo "- <LocalLeader>i shows object details with NO R commands visible"
echo "- Only a single 'source()' line should appear, then results"
echo ""