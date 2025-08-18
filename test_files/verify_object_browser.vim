" Verify object browser specifically (not general code execution)
echo "=== VERIFYING OBJECT BROWSER FUNCTIONS ==="

" Force reload current version
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "Testing ONLY object browser functions (not general code execution):"

" Test workspace browser specifically
try
    echo "Calling RWorkspace command..."
    RWorkspace
    echo "✅ RWorkspace should show compact command, not source()"
catch
    echo "❌ RWorkspace failed: " . v:exception
endtry

" Test object inspection specifically  
try
    echo "Calling RInspect iris..."
    RInspect iris
    echo "✅ RInspect should show compact command, not source()"
catch
    echo "❌ RInspect failed: " . v:exception
endtry

echo ""
echo "EXPECTED for object browser:"
echo "- Workspace: {cat(...);for(o in ls())cat(...)} - NO source() commands"
echo "- Inspect: {cat(...);if(exists(...))...} - NO source() commands"
echo ""
echo "The source() commands you see are from regular code execution (<CR>)"
echo "NOT from the object browser (<LocalLeader>' and <LocalLeader>i)"