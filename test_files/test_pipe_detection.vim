" Test pipe chain detection with your exact code

edit test_files/debug_pipe_chain.R
call cursor(1, 1)

echo "=== Testing pipe chain detection ==="
echo "Current line: " . line('.')
echo "Total lines: " . line('$')

" Test each line to see which ones match the pipe pattern
echo ""
echo "=== Line-by-line pipe pattern testing ==="
for line_num in range(1, line('$'))
    let line_content = getline(line_num)
    let matches_pipe = line_content =~# '%[^%]*%\s*$'
    let matches_native_pipe = line_content =~# '|>\s*$'
    let matches_any_operator = line_content =~# '[+\-*/^&|<>=!]\s*$' || line_content =~# '%[^%]*%\s*$' || line_content =~# '<-\s*$' || line_content =~# '|>\s*$'
    echo 'Line ' . line_num . ': "' . line_content[0:50] . '..."'
    echo '  Matches %>%: ' . matches_pipe
    echo '  Matches |>: ' . matches_native_pipe  
    echo '  Matches any operator: ' . matches_any_operator
    echo ''
endfor

" Test what happens if we simulate the GetCodeBlock logic
echo "=== Simulating GetCodeBlock logic from line 1 ==="
let current_line_num = 1
let current_line = getline(current_line_num)
echo "Starting line: " . current_line[0:50] . "..."

if current_line =~# '[+\-*/^&|<>=!]\s*$' || current_line =~# '%[^%]*%\s*$' || current_line =~# '<-\s*$' || current_line =~# '|>\s*$'
    echo "Line 1 matches infix pattern - would trigger pipe chain detection"
    
    let end_line = current_line_num
    echo "Starting end_line: " . end_line
    
    while end_line < line('$')
        let end_line += 1
        let next_line = getline(end_line)
        echo "Checking line " . end_line . ': "' . next_line[0:40] . '..."'
        
        if next_line =~# '^\s*$' || next_line =~# '^\s*#'
            echo "  -> Skipping empty/comment line"
            continue
        else
            echo "  -> Found non-empty line"
            if next_line =~# '[+\-*/^&|<>=!]\s*$' || next_line =~# '%[^%]*%\s*$' || next_line =~# '<-\s*$' || next_line =~# '|>\s*$'
                echo "  -> Line ends with operator, continuing chain"
                continue
            else
                echo "  -> Line does NOT end with operator, stopping here"
                break
            endif
        endif
    endwhile
    
    echo "Would return lines " . current_line_num . " to " . end_line
else
    echo "Line 1 does NOT match infix pattern"
endif