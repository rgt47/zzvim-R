" Quick test of assignment pattern

let test_line = 'missing_summary <- raw_data %>%'

echo "Testing line: " . test_line
echo "Assignment pattern match: " . (test_line =~# '\(<-\|=\).*[a-zA-Z_][a-zA-Z0-9_.]*\s*(')
echo "Pipe pattern match: " . (test_line =~# '%[^%]*%\s*$')

" Break down the assignment pattern
echo ""
echo "Assignment pattern breakdown:"
echo "Has <- or =: " . (test_line =~# '\(<-\|=\)')
echo "Has identifier: " . (test_line =~# '[a-zA-Z_][a-zA-Z0-9_.]*')
echo "Has opening paren: " . (test_line =~# '(')
echo "Full pattern: " . (test_line =~# '\(<-\|=\).*[a-zA-Z_][a-zA-Z0-9_.]*\s*(')