" Debug object inspection issue
echo "=== DEBUGGING OBJECT INSPECTION ==="

" Check if commands exist
echo "1. Command existence:"
try
    command RWorkspace
    echo "   RWorkspace exists"
catch
    echo "   RWorkspace missing: " . v:exception
endtry

try
    command RInspect
    echo "   RInspect exists"  
catch
    echo "   RInspect missing: " . v:exception
endtry

" Check if functions exist
echo ""
echo "2. Function existence:"
try
    echo "   s:RWorkspaceOverview callable: " . (exists('*s:RWorkspaceOverview') ? 'YES' : 'NO')
catch
    echo "   Error checking s:RWorkspaceOverview: " . v:exception
endtry

try
    echo "   s:RInspectObject callable: " . (exists('*s:RInspectObject') ? 'YES' : 'NO')
catch
    echo "   Error checking s:RInspectObject: " . v:exception
endtry

" Check if terminal support exists
echo ""
echo "3. Terminal support:"
echo "   Terminal available: " . (has('terminal') ? 'YES' : 'NO')
echo "   Job support: " . (has('job') ? 'YES' : 'NO')

" Check if Send_to_r function exists
echo ""
echo "4. Core function availability:"
echo "   s:Send_to_r exists: " . (exists('*s:Send_to_r') ? 'YES' : 'NO')

" Test manual execution of the functions (if they exist)
echo ""
echo "5. Manual function test:"
if exists('*s:RWorkspaceOverview')
    echo "   Attempting to call s:RWorkspaceOverview()..."
    try
        call s:RWorkspaceOverview()
        echo "   SUCCESS: Function executed"
    catch
        echo "   ERROR: " . v:exception
    endtry
else
    echo "   SKIP: Function not available"
endif

echo ""
echo "=== END DEBUG ==="