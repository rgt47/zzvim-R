" Simulate actual usage to test clean execution
echo "=== SIMULATING REAL USAGE ==="

" Force reload
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "Testing clean code execution by sending actual code..."

" Test RSendLine command (single line)
try
    RSendLine
    echo "✅ RSendLine executed (should be direct, no source)"
catch
    echo "❌ RSendLine failed: " . v:exception
endtry

" Test RSendSmart command (auto-detection)  
try
    RSendSmart
    echo "✅ RSendSmart executed (should use clean format)" 
catch
    echo "❌ RSendSmart failed: " . v:exception
endtry

echo ""
echo "Check the R terminal for:"
echo "- No source('/var/folders/...') commands"
echo "- Direct code execution or {block} format"  
echo "- Much cleaner output"