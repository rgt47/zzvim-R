" Test long lines with temp file approach
echo "=== TESTING LONG LINES WITH TEMP FILE APPROACH ==="
echo ""

" Force reload
if exists('g:loaded_zzvim_r')
    unlet g:loaded_zzvim_r
endif
source plugin/zzvim-R.vim

echo "✅ Plugin reloaded"

" Open the long lines test file
edit test_files/test_long_lines.R

echo "✅ Opened test_long_lines.R"
echo ""

" Test the very long line
normal! 6G
let long_line = getline('.')
let line_length = len(long_line)

echo "Testing long line execution:"
echo "- Line " . line('.') . ": " . long_line[0:50] . "..."
echo "- Line length: " . line_length . " characters"

if line_length > 80
    echo "✅ Line exceeds 80 characters (would break R terminal)"
    echo "✅ Temp file approach will handle this correctly"
else
    echo "⚠️  Line is shorter than expected for stress testing"
endif

echo ""
echo "Testing multi-line pipe operation:"
normal! 7G
echo "- Line " . line('.') . ": " . getline('.')
echo "- This is a multi-line operation that should be detected as a block"

echo ""
echo "=== EXPECTED BEHAVIOR ==="
echo "1. Long single lines: Written to temp file, source() command in terminal"
echo "2. Multi-line blocks: Detected as blocks, sent via temp file"
echo "3. No character limit errors in R terminal"
echo "4. Clean source() format without verbose parameters"
echo ""
echo "Manual test: Place cursor on line 6 (long variable assignment)"
echo "Press <CR> and verify R terminal shows only: > source(\"/path/temp\")"