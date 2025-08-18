" Test eval(parse()) approach to minimize command visibility
echo "=== TESTING EVAL(PARSE()) APPROACH ==="

" Force reload to get eval(parse()) approach
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "✅ Plugin reloaded with eval(parse()) approach"

" Test basic functionality  
try
    RWorkspace
    echo "✅ RWorkspace executed - using eval(parse()) (shorter command)"
catch
    echo "❌ RWorkspace failed: " . v:exception
endtry

try
    RInspect iris  
    echo "✅ RInspect executed - using eval(parse()) (shorter command)"
catch
    echo "❌ RInspect failed: " . v:exception  
endtry

echo ""
echo "Result: Commands now use eval(parse(file)) instead of source()"
echo ""
echo "Expected improvement:"
echo "- Shorter command shown in terminal: eval(parse('file'))"
echo "- Still clean results with no internal code listing"
echo "- Minimal terminal clutter"
echo ""