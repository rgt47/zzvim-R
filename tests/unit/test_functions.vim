" ==============================================================================
" Function Tests
" ==============================================================================
" Tests for plugin functions without requiring R

echo "Testing functions..."

" Test that all public API functions exist
let expected_functions = [
    \ 'zzvim_r#open_terminal',
    \ 'zzvim_r#submit_line',
    \ 'zzvim_r#submit_selection',
    \ 'zzvim_r#navigate_next_chunk',
    \ 'zzvim_r#navigate_prev_chunk', 
    \ 'zzvim_r#execute_chunk',
    \ 'zzvim_r#execute_previous_chunks',
    \ 'zzvim_r#send_quit',
    \ 'zzvim_r#send_interrupt',
    \ 'zzvim_r#inspect',
    \ 'zzvim_r#browse_workspace',
    \ 'zzvim_r#list_workspace',
    \ 'zzvim_r#install_package',
    \ 'zzvim_r#load_package',
    \ 'zzvim_r#update_package',
    \ 'zzvim_r#read_csv',
    \ 'zzvim_r#write_csv',
    \ 'zzvim_r#read_rds',
    \ 'zzvim_r#save_rds',
    \ 'zzvim_r#help_examples',
    \ 'zzvim_r#apropos_help',
    \ 'zzvim_r#find_definition',
    \ 'zzvim_r#add_pipe'
    \ ]

for func in expected_functions
    call AssertExists(func, 'Function ' . func . ' should exist')
endfor

" Test error handling for functions when R is not available
" These should fail gracefully, not crash

" Test graceful failure when no terminal exists
let result = zzvim_r#submit_line()
call Assert(result == 0, 'submit_line should return 0 when no terminal exists')

" Test chunk navigation with no R Markdown content
" Create a temporary buffer with non-R content
new
call setline(1, ['This is not R Markdown', 'No chunks here'])
let result = zzvim_r#navigate_next_chunk()
call Assert(result == 0, 'navigate_next_chunk should return 0 when no chunks exist')
bdelete!

" Test chunk navigation with R Markdown content
new
call setline(1, [
    \ 'This is R Markdown',
    \ '',
    \ '```{r}',
    \ 'x <- 1',
    \ '```',
    \ '',
    \ 'More text'
    \ ])
set filetype=rmd
" Position cursor inside chunk
normal! 4G
let result = zzvim_r#execute_chunk()
" Should handle gracefully even without R terminal
call Assert(type(result) == v:t_number, 'execute_chunk should return a number')
bdelete!

" Test package management graceful failure
let result = zzvim_r#install_package()
call Assert(result == 0, 'install_package should return 0 when cancelled/failed')

echo "Function tests completed."