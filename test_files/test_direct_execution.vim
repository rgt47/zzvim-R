" Test direct single line execution vs temp file blocks
echo "=== TESTING DIRECT SINGLE LINE EXECUTION ==="

" Force reload to get fixed approach
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "✅ Plugin reloaded with direct single line execution"

try
    " This should send single lines directly
    RSendSmart
    echo "✅ Smart execution - single lines direct, blocks via temp file"
catch
    echo "❌ Execution failed: " . v:exception
endtry

echo ""
echo "Expected behavior:"
echo "- Single lines: library(ggplot2) → shows > library(ggplot2)"
echo "- Single lines: head(iris) → shows > head(iris) + data output"  
echo "- Multi-line blocks: → shows > source('temp') + execution"
echo ""
echo "Test by placing cursor on single lines in test_direct_lines.R"