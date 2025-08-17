" =============================================================================
" Object Inspection Test Suite for zzvim-R
" =============================================================================
" Tests the simplified object browser functionality
" Usage: :source test_files/test_object_inspection.vim

echo "Starting Object Inspection Tests..."

" Test 1: Basic function existence
echo "Test 1: Function existence..."
try
    call s:RWorkspaceOverview()
    echo "✅ s:RWorkspaceOverview() exists"
catch
    echo "❌ s:RWorkspaceOverview() missing: " . v:exception
endtry

try 
    call s:RInspectObject("test")
    echo "✅ s:RInspectObject() exists"
catch
    echo "❌ s:RInspectObject() missing: " . v:exception
endtry

" Test 2: Command existence  
echo "Test 2: Command existence..."
try
    command RWorkspace
    echo "✅ :RWorkspace command exists"
catch
    echo "❌ :RWorkspace command missing: " . v:exception
endtry

try
    command RInspect
    echo "✅ :RInspect command exists" 
catch
    echo "❌ :RInspect command missing: " . v:exception
endtry

" Test 3: Key mapping existence (requires R file)
echo "Test 3: Key mapping tests (open an R file first)..."
if &filetype == 'r' || &filetype == 'rmd' || &filetype == 'quarto'
    try
        " Test if mappings exist by checking map output
        redir => mapping_output
        silent nmap <LocalLeader>'
        redir END
        
        if mapping_output =~ 'RWorkspaceOverview'
            echo "✅ <LocalLeader>' mapping exists"
        else
            echo "❌ <LocalLeader>' mapping not found"
        endif
        
        redir => mapping_output  
        silent nmap <LocalLeader>i
        redir END
        
        if mapping_output =~ 'RInspectObject'
            echo "✅ <LocalLeader>i mapping exists"
        else
            echo "❌ <LocalLeader>i mapping not found"
        endif
        
    catch
        echo "❌ Mapping test failed: " . v:exception
    endtry
else
    echo "⚠️  Not in R file - key mapping tests skipped"
    echo "   Open an R file and re-run tests to check mappings"
endif

" Test 4: Error handling
echo "Test 4: Error handling..."
try
    " Test with empty object name
    call s:RInspectObject("")
    echo "✅ Empty object name handled gracefully"
catch
    echo "❌ Empty object name caused error: " . v:exception
endtry

echo "Object Inspection Tests Complete!"
echo ""
echo "Manual Testing Instructions:"
echo "============================"
echo "1. Open an R file (test.R)"
echo "2. Start R terminal: <LocalLeader>r"  
echo "3. Create test objects:"
echo "   aa <- head(iris)"
echo "   bb <- 1:10"
echo "   cc <- list(x=1:5, y=letters[1:3])"
echo "4. Test workspace overview: <LocalLeader>'"
echo "5. Test object inspection: place cursor on 'aa' and press <LocalLeader>i"
echo "6. Test commands: :RWorkspace and :RInspect bb"
echo ""