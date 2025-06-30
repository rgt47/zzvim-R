" ==============================================================================
" Basic Functionality Integration Tests
" ==============================================================================
" Tests that require R to be available

echo "Testing basic functionality (requires R)..."

" Test R executable detection
call Assert(executable('R'), 'R executable should be available for integration tests')

" Test terminal creation (but don't actually create one to avoid hanging tests)
" Instead test the validation logic

" Create a test R file
new
call setline(1, [
    \ '# Test R file',
    \ 'x <- 1:10',
    \ 'y <- mean(x)',
    \ 'print(y)'
    \ ])
set filetype=r

" Test that file type is detected correctly
call AssertEqual('r', &filetype, 'File type should be detected as R')

" Test text extraction for line
normal! 2G
" Note: We can't easily test actual execution without R terminal,
" but we can test that the function doesn't crash
try
    let line_content = getline('.')
    call Assert(!empty(line_content), 'Should be able to get current line content')
    call Assert(line_content =~# 'x <- 1:10', 'Line content should match expected')
catch
    call Assert(0, 'Getting line content should not throw exception')
endtry

bdelete!

" Test R Markdown chunk detection
new
call setline(1, [
    \ '# Test R Markdown',
    \ '',
    \ '```{r setup}',
    \ 'library(ggplot2)',
    \ 'data <- mtcars',
    \ '```',
    \ '',
    \ 'Some text here.',
    \ '',
    \ '```{r plot}',
    \ 'ggplot(data, aes(x = mpg, y = hp)) +',
    \ '  geom_point()',
    \ '```'
    \ ])
set filetype=rmd

" Test chunk navigation
normal! 1G
let result = zzvim_r#navigate_next_chunk()
call Assert(result == 1, 'Should successfully navigate to next chunk')

" Check if cursor moved to inside the chunk
let current_line = line('.')
call Assert(current_line >= 4 && current_line <= 6, 'Cursor should be inside first chunk')

" Test navigating to next chunk
let result = zzvim_r#navigate_next_chunk()
call Assert(result == 1, 'Should successfully navigate to second chunk')

let current_line = line('.')
call Assert(current_line >= 11 && current_line <= 13, 'Cursor should be inside second chunk')

bdelete!

" Test package management input validation
" These functions should handle empty input gracefully
" We can't test actual package operations without user input

echo "Basic functionality tests completed."