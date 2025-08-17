" Simple test runner for object inspection
echo "Testing object inspection commands..."

" Test command existence
echo "Checking if commands exist..."
try
    command RWorkspace
    echo "✅ RWorkspace command is defined"
catch
    echo "❌ RWorkspace command not defined: " . v:exception
endtry

try
    command RInspect  
    echo "✅ RInspect command is defined"
catch
    echo "❌ RInspect command not defined: " . v:exception  
endtry

" Test if we're in an R file
echo "Current filetype: " . &filetype
if &filetype == 'r'
    echo "✅ In R file - testing functionality"
    
    " Test workspace command (this will try to send to R terminal)
    echo "Testing RWorkspace..."
    try
        RWorkspace
        echo "✅ RWorkspace executed"
    catch
        echo "❌ RWorkspace failed: " . v:exception
    endtry
    
    " Test inspect command
    echo "Testing RInspect..."
    try
        RInspect test
        echo "✅ RInspect executed"
    catch
        echo "❌ RInspect failed: " . v:exception
    endtry
    
else
    echo "⚠️  Not in R file - open an R file first"
endif

echo "Test complete."