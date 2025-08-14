" Step by step debugging of the cursor issue

" Load the plugin first
source plugin/zzvim-R.vim

" Open the test file
edit test_files/test_cursor_jump.R

" Position cursor on line 1
call cursor(1, 1)

echo "=== Initial state ==="
echo "Current line: " . line('.')
echo "Line content: '" . getline('.') . "'"

" Test if this line would be detected as a block start
let current_line = getline('.')
echo "Is block start: " . s:IsBlockStart(current_line)

" Test if we're inside a function  
echo "Is inside function: " . s:IsInsideFunction()

" Test if it's an incomplete statement
echo "Is incomplete statement: " . s:IsIncompleteStatement()

echo "\n=== Simulating GetTextByType('') ==="
let text_lines = s:GetTextByType('')
echo "Returned lines: " . string(text_lines)
echo "Number of lines: " . len(text_lines)

echo "\n=== Testing cursor movement logic ==="
let selection_type = ''
let line_count = len(text_lines)

" This simulates the logic in SendToR function
let actual_type = selection_type
if empty(selection_type) && len(text_lines) > 1
    let actual_type = 'function'
    echo "Actual type set to: function"
else
    echo "Actual type remains: " . actual_type
endif

echo "\n=== Testing MoveCursorAfterSubmission logic ==="
if actual_type ==# 'selection'
    echo "Would not move cursor (selection)"
elseif actual_type ==# 'chunk'
    echo "Would not move cursor (chunk)"
elseif actual_type ==# 'function'
    echo "Would move to end of block"
else
    echo "Would process single line submission"
    if getline('.') =~# '^\s*#'
        echo "Detected as comment - would call MoveToNextNonComment()"
    else
        echo "Detected as regular line - would move to next line"
        let target_line = min([line('.') + 1, line('$')])
        echo "Target line: " . target_line
    endif
endif