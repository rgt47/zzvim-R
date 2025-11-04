" Test script for terminal selection feature
" This tests the new functionality where zzvim-R detects existing terminals
" and prompts the user to select one or create new

" Test Scenario 1: No existing terminals
" Expected: Should create new terminal without prompting
echom "=== Test 1: No existing terminals ==="
echom "Open an R file and press <LocalLeader>r"
echom "Expected: New R terminal created automatically"
echom ""

" Test Scenario 2: One existing terminal
" Expected: Should prompt user to select existing or create new
echom "=== Test 2: One existing terminal ==="
echom "1. Open a terminal manually: :term"
echom "2. Open an R file and press <LocalLeader>r or <CR>"
echom "Expected: Prompt showing:"
echom "  1. Terminal #X [running] (buf #X)"
echom "  2. Create new R terminal"
echom ""

" Test Scenario 3: Multiple existing terminals
" Expected: Should show all terminals in selection prompt
echom "=== Test 3: Multiple existing terminals ==="
echom "1. Open multiple terminals: :term (repeat 2-3 times)"
echom "2. Open an R file and press <LocalLeader>r or <CR>"
echom "Expected: Prompt showing all terminals with option to create new"
echom ""

" Test Scenario 4: Terminal already associated
" Expected: Should reuse existing association without prompting
echom "=== Test 4: Already associated terminal ==="
echom "1. Open R file, associate with terminal (from test 2 or 3)"
echom "2. Execute R code with <CR>"
echom "Expected: Uses already-associated terminal, no prompt"
echom ""

" Test Scenario 5: User cancels selection
" Expected: Should not create terminal, show error message
echom "=== Test 5: Cancel selection ==="
echom "1. Have existing terminals open"
echom "2. Open R file, press <LocalLeader>r"
echom "3. When prompted, enter 0 (cancel)"
echom "Expected: Error message 'Terminal association cancelled'"
echom ""

" Test Scenario 6: Select stopped terminal
" Expected: Can select even stopped terminals
echom "=== Test 6: Select stopped terminal ==="
echom "1. Open terminal, exit it (type 'exit')"
echom "2. Open R file, press <LocalLeader>r"
echom "Expected: Shows terminal with [stopped] indicator, can still select"
echom ""

echom "========================================="
echom "Run these tests manually to verify the terminal selection feature"
echom "========================================="
