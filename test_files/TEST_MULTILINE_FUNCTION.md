# Test: Multi-Line Function Definition Fix

## What Was Fixed

The `GetCodeBlock()` function in `plugin/zzvim-R.vim` was incorrectly handling multi-line function definitions. When a function definition spanned multiple lines with the signature extending beyond the first line, pressing `<CR>` would only execute the function signature up to the closing parenthesis `)`, not the entire function including the body.

## The Problem

**Original Code (lines 1369-1375 before fix):**
```vim
" First Priority: Check current line for parentheses (function calls)
if has_paren && !has_brace && !has_bracket
    let block_type = 'paren'
    let found_opening = 1
```

When the cursor was on this line:
```r
t2f <- function(df, filename = NULL,
                sub_dir = "output",
                scolor = "blue!10", verbose = FALSE,
                extra_packages = NULL,
                document_class = "article") {
```

The algorithm would:
1. Detect `has_paren = true` (from `function(`)
2. Detect `has_brace = false` (the `{` is on line 7, not line 1)
3. Set `block_type = 'paren'` (WRONG!)
4. Look for matching `)` instead of matching `}`
5. Extract lines 1-7 only (just the signature)
6. Ignore the function body entirely

## The Solution

**Added special case handling (lines 1369-1392 after fix):**
```vim
" SPECIAL CASE: Multi-Line Function Definitions
" Function definitions like: var <- function(args)
"                              body
"                            }
" Have parentheses on line 1 but opening brace on a later line.
" Must always use brace matching for function definitions, not parenthesis matching.
if current_line =~# 'function\s*('
    let block_type = 'brace'
    if has_brace
        " Brace on current line - use normal processing
        let found_opening = 1
    else
        " Brace on a later line - search for it within reasonable distance
        let search_line = current_line_num + 1
        let search_limit = current_line_num + 10
        while search_line <= line('$') && search_line <= search_limit
            if getline(search_line) =~ '{'
                let block_line = search_line
                let found_opening = 1
                break
            endif
            let search_line += 1
        endwhile
    endif
```

Now when the cursor is on a function definition line:
1. Explicitly checks if the line contains `function\s*(`
2. Always sets `block_type = 'brace'` (not `'paren'`)
3. Searches forward for the opening `{` if it's not on the current line
4. Extracts the entire function from the opening brace to the closing brace

## How to Test

1. **Open the test file:**
   ```bash
   vim test_files/test_multiline_function_def.R
   ```

2. **Position cursor on line 2** (the first line of the function definition):
   ```r
   t2f <- function(df, filename = NULL,
   ```

3. **Press `<CR>`** (Enter) to execute

4. **Expected behavior:**
   - The entire function should execute (all 23 lines, not just 7)
   - The cursor should advance to the line after the closing brace `}`
   - In R terminal, you should see the function definition printed with all parameters and body

5. **Verify with R terminal:**
   ```r
   > # Function executes successfully
   > t2f <- function(df, filename = NULL, sub_dir = "output",
   +     scolor = "blue!10", verbose = FALSE, extra_packages = NULL,
   +     document_class = "article") {
   +   # ... function body ...
   + }
   ```

## Key Changes

- **File Modified:** `plugin/zzvim-R.vim`
- **Lines Changed:** 1369-1392 (Added special case handling)
- **Backward Compatible:** Yes - existing functionality unchanged
- **Scope:** Only affects function definitions with pattern `function\s*(`

## Why This Matters

Multi-line function definitions are common in R, especially when using modern tidyverse packages or creating parameterized functions. This fix ensures that:

1. **Full function execution:** The entire function body executes, not just the signature
2. **Correct cursor positioning:** Cursor advances to after the function definition
3. **Consistent behavior:** Works regardless of whether opening brace is on same line or different line
4. **No errors:** Prevents "unexpected token" or "incomplete expression" errors from partial execution

## Next Steps

After testing, you can confirm the fix works with your specific `t2f` function by:
1. Opening your R code file
2. Positioning cursor on the `t2f <- function(...)` line
3. Pressing `<CR>` to execute
4. Verifying the entire function executes (not just signature)
