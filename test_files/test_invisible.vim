" Test invisible() wrapper for object inspection
echo "=== TESTING INVISIBLE() WRAPPER ==="

" Force reload to get updated functions
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "✅ Plugin reloaded with invisible() wrapper"

" Test commands exist
try
    command RWorkspace
    echo "✅ RWorkspace command exists"
catch
    echo "❌ RWorkspace command missing: " . v:exception
endtry

try  
    command RInspect
    echo "✅ RInspect command exists"
catch
    echo "❌ RInspect command missing: " . v:exception
endtry

echo ""
echo "Manual Test Instructions:"
echo "1. Create test data: aa <- head(iris)"
echo "2. Test workspace: <LocalLeader>' or :RWorkspace"  
echo "3. Test inspection: <LocalLeader>i on 'aa' or :RInspect aa"
echo "4. Verify: Only results shown, no command echoing"
echo ""
echo "=== READY FOR TESTING ==="