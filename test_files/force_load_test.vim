" Force load current plugin and test
echo "=== FORCE LOADING CURRENT PLUGIN ==="

" Unlet any existing plugin guard
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif

" Force source the current plugin file
echo "Loading plugin from: " . getcwd() . "/plugin/zzvim-R.vim"
source plugin/zzvim-R.vim

echo "Plugin loaded. Testing commands..."

" Test commands again
try
    command RWorkspace
    echo "✅ RWorkspace defined correctly"
catch
    echo "❌ RWorkspace error: " . v:exception
endtry

try  
    command RInspect
    echo "✅ RInspect defined correctly"
catch
    echo "❌ RInspect error: " . v:exception
endtry

echo "=== END FORCE LOAD TEST ==="