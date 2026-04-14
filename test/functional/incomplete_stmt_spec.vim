" Specs for s:IsIncompleteStatement.
"
" Unlike EndsWithInfixOperator (pure), this inspects the current
" buffer: the line under the cursor and the line before it. Specs
" exercise the three branches in the implementation:
"   1. Current line starts with a closing bracket or comma
"   2. Current line is a lone parameter name ending ',' or ')'
"      and previous line ended with '(' or ','
"   3. Previous line ends with an infix operator
"
" Establishes the buffer-fixture pattern reused by later specs.

let s:suite = themis#suite('IsIncompleteStatement')
let s:assert = themis#helper('assert')

let s:IsIncompleteStatement = g:ZzvimRTestFunc('IsIncompleteStatement')

" Seed the current buffer with the given lines and place the cursor
" on line `lnum`, column 1.
function! s:fixture(lines, lnum) abort
    enew!
    call setline(1, a:lines)
    call cursor(a:lnum, 1)
endfunction

" -----------------------------------------------------------------
" Branch 1: current line begins with a closing delimiter
" -----------------------------------------------------------------

function! s:suite.closing_paren_on_its_own_line() abort
    call s:fixture(['fun(', '    x,', ')'], 3)
    call s:assert.truthy(s:IsIncompleteStatement())
endfunction

function! s:suite.closing_brace_on_its_own_line() abort
    call s:fixture(['f <- function() {', '  body', '}'], 3)
    call s:assert.truthy(s:IsIncompleteStatement())
endfunction

function! s:suite.closing_bracket_on_its_own_line() abort
    call s:fixture(['x[', '  1', ']'], 3)
    call s:assert.truthy(s:IsIncompleteStatement())
endfunction

function! s:suite.leading_comma_line() abort
    call s:fixture(['list(', '  a = 1', ', b = 2', ')'], 3)
    call s:assert.truthy(s:IsIncompleteStatement())
endfunction

" -----------------------------------------------------------------
" Branch 2: lone parameter name after open paren / comma
" -----------------------------------------------------------------

function! s:suite.lone_name_after_open_paren() abort
    call s:fixture(['fun(', '  x,'], 2)
    call s:assert.truthy(s:IsIncompleteStatement())
endfunction

function! s:suite.lone_name_after_trailing_comma() abort
    call s:fixture(['fun(a,', '  b,'], 2)
    call s:assert.truthy(s:IsIncompleteStatement())
endfunction

function! s:suite.assignment_on_continuation_is_not_lone_name() abort
    " An assignment line, even if it ends with ',', is not treated
    " as a mere continuation parameter.
    call s:fixture(['fun(', '  x <- 1,'], 2)
    call s:assert.falsy(s:IsIncompleteStatement())
endfunction

" -----------------------------------------------------------------
" Branch 3: previous line ends with an infix operator
" -----------------------------------------------------------------

function! s:suite.after_native_pipe() abort
    call s:fixture(['x |>', '  filter(y > 0)'], 2)
    call s:assert.truthy(s:IsIncompleteStatement())
endfunction

function! s:suite.after_magrittr_pipe() abort
    call s:fixture(['x %>%', '  filter(y > 0)'], 2)
    call s:assert.truthy(s:IsIncompleteStatement())
endfunction

function! s:suite.after_assignment_arrow() abort
    call s:fixture(['result <-', '  compute(x)'], 2)
    call s:assert.truthy(s:IsIncompleteStatement())
endfunction

function! s:suite.after_plus() abort
    call s:fixture(['ggplot(df) +', '  geom_point()'], 2)
    call s:assert.truthy(s:IsIncompleteStatement())
endfunction

" -----------------------------------------------------------------
" Negatives: complete statement lines
" -----------------------------------------------------------------

function! s:suite.standalone_assignment_is_complete() abort
    call s:fixture(['x <- 1'], 1)
    call s:assert.falsy(s:IsIncompleteStatement())
endfunction

function! s:suite.standalone_function_call_is_complete() abort
    call s:fixture(['print(x)'], 1)
    call s:assert.falsy(s:IsIncompleteStatement())
endfunction

function! s:suite.first_line_of_buffer_with_prev_check() abort
    " Line 1 has no previous line; branch 3 must not reach into
    " negative indices.
    call s:fixture(['print(x)'], 1)
    call s:assert.falsy(s:IsIncompleteStatement())
endfunction

function! s:suite.empty_line_is_complete() abort
    call s:fixture(['', ''], 2)
    call s:assert.falsy(s:IsIncompleteStatement())
endfunction
