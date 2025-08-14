" Debug the multiline detection issue

edit test_files/test_multiline.R
call cursor(1, 1)

echo "=== Testing multiline c() detection ==="
echo "Current line: " . line('.')
echo "Line content: '" . getline('.') . "'"

" Test IsBlockStart detection
let current_line = getline('.')
echo ""
echo "=== Testing patterns ==="
echo "Line contains 'c(': " . (current_line =~ 'c(')
echo "Line contains function call pattern: " . (current_line =~# '^\s*[a-zA-Z_][a-zA-Z0-9_.]*\s*(')
echo "Line matches exclusion pattern: " . (current_line =~ '^\s*[)}\],]')

" Test the actual IsBlockStart logic manually
echo ""
echo "=== Manual IsBlockStart logic ==="

" Function definitions
if current_line =~# 'function\s*('
    echo "Would match: function definition"
endif

" Control structures
if current_line =~# '^\s*\(if\|for\|while\)\s*('
    echo "Would match: control structure"
endif

" Repeat and standalone blocks
if current_line =~# '^\s*\(repeat\s*\)\?{'
    echo "Would match: repeat/block"
endif

" Function calls - this should match
if current_line =~# '^\s*[a-zA-Z_][a-zA-Z0-9_.]*\s*(' && current_line !~ '^\s*[)}\],]'
    echo "Would match: function call (this should trigger for your line)"
    if current_line !~ '^\s*[a-zA-Z_][a-zA-Z0-9_.]*\s*)\s*$'
        echo "And passes final validation (not just closing paren)"
    else
        echo "But fails final validation (is just closing paren)"
    endif
else
    echo "Would NOT match: function call pattern failed"
    echo "  First part: " . (current_line =~# '^\s*[a-zA-Z_][a-zA-Z0-9_.]*\s*(')
    echo "  Exclusion: " . (current_line !~ '^\s*[)}\],]')
endif