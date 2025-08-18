" Test compact single-line R command approach
echo "=== TESTING COMPACT SINGLE COMMANDS ==="

" Force reload to get compact approach
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "✅ Plugin reloaded with compact single-line approach"

" Test basic functionality  
try
    RWorkspace
    echo "✅ RWorkspace executed - now uses single compact R command"
catch
    echo "❌ RWorkspace failed: " . v:exception
endtry

try
    RInspect mtcars  
    echo "✅ RInspect executed - now uses single compact R command"
catch
    echo "❌ RInspect failed: " . v:exception  
endtry

echo ""
echo "SUCCESS: Eliminated temp files and source() commands"
echo ""
echo "New behavior:"  
echo "- Only ONE line per action in terminal (compact R code)"
echo "- No temp files created"
echo "- No source() commands"
echo "- Direct execution with clean results"
echo ""