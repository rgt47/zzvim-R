" Specs for s:EndsWithInfixOperator.
"
" Detects whether an R code line ends with an operator that implies
" the statement continues on the next line. Used by <CR> submission
" to keep incomplete pipe/assignment chains together.

let s:suite = themis#suite('EndsWithInfixOperator')
let s:assert = themis#helper('assert')

" Moved to autoload in Phase 4 batch 1.
let s:EndsWithInfixOperator = function('zzvim_r#ends_with_infix_operator')

function! s:suite.native_pipe_is_incomplete() abort
    call s:assert.truthy(s:EndsWithInfixOperator('x |>'))
    call s:assert.truthy(s:EndsWithInfixOperator('x |>  '))
endfunction

function! s:suite.magrittr_pipe_is_incomplete() abort
    call s:assert.truthy(s:EndsWithInfixOperator('x %>%'))
    call s:assert.truthy(s:EndsWithInfixOperator('x %>% '))
endfunction

function! s:suite.custom_infix_is_incomplete() abort
    " Any %anything% suffix should count as a continuing infix.
    call s:assert.truthy(s:EndsWithInfixOperator('x %in%'))
    call s:assert.truthy(s:EndsWithInfixOperator('x %op%'))
endfunction

function! s:suite.assignment_arrow_is_incomplete() abort
    call s:assert.truthy(s:EndsWithInfixOperator('y <-'))
    call s:assert.truthy(s:EndsWithInfixOperator('y <-  '))
endfunction

function! s:suite.arithmetic_operators_are_incomplete() abort
    for op in ['+', '-', '*', '/', '^']
        call s:assert.truthy(s:EndsWithInfixOperator('a ' . op))
        call s:assert.truthy(s:EndsWithInfixOperator('a ' . op . '  '))
    endfor
endfunction

function! s:suite.logical_and_comparison_operators_are_incomplete() abort
    for op in ['&', '|', '<', '>', '=', '!']
        call s:assert.truthy(s:EndsWithInfixOperator('a ' . op))
    endfor
endfunction

function! s:suite.trailing_comma_is_incomplete() abort
    " Common inside function-argument lists split across lines.
    call s:assert.truthy(s:EndsWithInfixOperator('fun(x,'))
endfunction

function! s:suite.complete_statement_is_not_flagged() abort
    call s:assert.falsy(s:EndsWithInfixOperator('x <- 1'))
    call s:assert.falsy(s:EndsWithInfixOperator('print(x)'))
    call s:assert.falsy(s:EndsWithInfixOperator('library(dplyr)'))
    call s:assert.falsy(s:EndsWithInfixOperator(''))
endfunction

function! s:suite.operator_mid_line_is_not_flagged() abort
    " Only trailing operators count; operators inside the line do not.
    call s:assert.falsy(s:EndsWithInfixOperator('x + 1'))
    call s:assert.falsy(s:EndsWithInfixOperator('a |> b()'))
endfunction
