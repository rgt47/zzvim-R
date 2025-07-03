" Test script for zzvim-R error handling
" This script tests the error handling in the autoload file when plugin 
" functions are not available.

" Clear any existing functions
runtime! autoload/zzvim_r.vim

" Test function to call autoload functions without plugin loaded
function! TestZzvimRErrorHandling() abort
  " Create a buffer for results
  new
  file TestResults
  
  " Test results
  call append(line('$'), '=== zzvim-R Error Handling Tests ===')
  call append(line('$'), '')
  
  " Test a few key functions
  let tests = [
    \ 'zzvim_r#open_terminal()',
    \ 'zzvim_r#submit_line()',
    \ 'zzvim_r#execute_chunk()',
    \ 'zzvim_r#browse_workspace()',
    \ 'zzvim_r#install_package()',
    \ 'zzvim_r#read_csv()',
    \ 'zzvim_r#directory_operation("pwd")',
    \ 'zzvim_r#show_class()',
    \ 'zzvim_r#inspect_head()'
  \ ]
  
  " Run each test and capture output
  for test in tests
    redir => output
    silent! execute 'call ' . test
    redir END
    
    " Append test name and results 
    call append(line('$'), 'Test: ' . test)
    call append(line('$'), 'Output: ' . substitute(output, '^\n\+', '', ''))
    call append(line('$'), '')
  endfor
  
  call append(line('$'), '=== Tests Complete ===')
  
  " Set buffer options
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nomodified
  normal! gg
endfunction

" Run tests when script is executed
call TestZzvimRErrorHandling()