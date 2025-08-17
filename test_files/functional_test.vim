" Test actual function execution after force loading
echo "=== FUNCTIONAL TEST ==="

" Force load to ensure we have current version
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "Plugin reloaded. Testing function execution..."

" Test if functions exist
echo "s:RWorkspaceOverview exists: " . (exists('*s:RWorkspaceOverview') ? 'YES' : 'NO')
echo "s:RInspectObject exists: " . (exists('*s:RInspectObject') ? 'YES' : 'NO')
echo "s:Send_to_r exists: " . (exists('*s:Send_to_r') ? 'YES' : 'NO')

" Try calling RWorkspace command (will fail if no R terminal, but should not error on command level)
echo ""
echo "Testing RWorkspace command..."
try
    RWorkspace
    echo "✅ RWorkspace command executed (may need R terminal)"
catch
    echo "❌ RWorkspace error: " . v:exception
endtry

" Try calling RInspect command
echo ""
echo "Testing RInspect command..."
try
    RInspect test_object
    echo "✅ RInspect command executed (may need R terminal)"
catch
    echo "❌ RInspect error: " . v:exception
endtry

echo ""
echo "=== END FUNCTIONAL TEST ==="