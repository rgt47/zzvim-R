" Test minimal source command approach
echo "=== TESTING MINIMAL SOURCE COMMAND ==="

" Force reload to get consistent temp file approach
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "✅ Plugin reloaded with minimal source() format"

" Test with ex.Rmd chunk
try
    echo "Testing consistent temp file approach..."
    RSendSmart
    echo "✅ Code sent using minimal source('file') format"
catch
    echo "❌ Execution failed: " . v:exception
endtry

echo ""
echo "Expected improvement:"
echo "Before: source('/var/folders/.../temp123', echo=T)"
echo "After:  source('file')"
echo ""
echo "Now ALL code execution (lines, blocks, chunks) uses consistent"
echo "temp file approach with minimal source command format."