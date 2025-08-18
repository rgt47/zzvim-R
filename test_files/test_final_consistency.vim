" Test final consistent temp file approach
echo "=== TESTING FINAL CONSISTENT TEMP FILE APPROACH ==="
echo ""

" Force reload to ensure we're using latest code
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "✅ Plugin reloaded with consistent temp file approach"
echo ""

" Open the test R file
edit test_files/test_direct_lines.R

" Test single line execution
echo "Testing single line execution (should use temp file):"
echo "- Cursor on 'library(ggplot2)' line"
normal! 2G
echo "- Line content: " . getline('.')
echo "- Expected terminal output: > source(\"/path/temp123\")"
echo "- Expected R result: library loads without clutter"

echo ""

" Test multi-line function
echo "Testing multi-line function (should use temp file):"
echo "- Cursor on 'my_function <- function(data) {' line"
normal! 7G  
echo "- Line content: " . getline('.')
echo "- Expected: Detects function block, sends entire function via temp file"
echo "- Expected terminal output: > source(\"/path/temp456\")"

echo ""
echo "=== KEY EXPECTATIONS ==="
echo "1. ALL code execution uses temp files (no direct line transmission)"
echo "2. Clean source() format: source(\"/path/tempfile\")"
echo "3. No echo=T, no verbose parameters"
echo "4. Single lines handled same as multi-line blocks for consistency"
echo "5. R terminal character limits properly handled"
echo ""
echo "To test: Place cursor on any line and press <CR>"
echo "Terminal should show clean source() commands only"