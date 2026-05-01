" Specs for s:IsBlockStart and s:GetCodeBlock.
"
" These are the functions behind <CR> smart submission. IsBlockStart
" classifies a single line; GetCodeBlock walks the buffer from the
" current line and returns the list of lines forming one logical
" block. Together they decide what <CR> sends to R.
"
" This is the highest-risk area of the plugin. Past regressions
" (v2.3 chunk-nav rewrite era) produced silent wrong behavior —
" sending half a pipe chain or truncating a function body. Keep
" coverage dense here.

let s:suite = themis#suite('BlockDetect')
let s:assert = themis#helper('assert')

" IsBlockStart moved to autoload in Phase 4 batch 1; GetCodeBlock
" remains in plugin/ pending a later batch.
let s:IsBlockStart = function('zzvim_r#is_block_start')
let s:GetCodeBlock = g:ZzvimRTestFunc('GetCodeBlock')

function! s:fixture(lines, lnum) abort
    enew!
    call setline(1, a:lines)
    call cursor(a:lnum, 1)
endfunction

" =================================================================
" s:IsBlockStart
" =================================================================

function! s:suite.is_block_start_function_definition() abort
    call s:assert.truthy(s:IsBlockStart('f <- function(x) {'))
    call s:assert.truthy(s:IsBlockStart('f <- function(x, y)'))
endfunction

function! s:suite.is_block_start_control_structures() abort
    call s:assert.truthy(s:IsBlockStart('if (x > 0) {'))
    call s:assert.truthy(s:IsBlockStart('for (i in 1:10) {'))
    call s:assert.truthy(s:IsBlockStart('while (x > 0) {'))
endfunction

function! s:suite.is_block_start_bare_brace() abort
    call s:assert.truthy(s:IsBlockStart('{'))
    call s:assert.truthy(s:IsBlockStart('repeat {'))
endfunction

function! s:suite.is_block_start_function_call_with_open_paren() abort
    call s:assert.truthy(s:IsBlockStart('print(x)'))
    call s:assert.truthy(s:IsBlockStart('c(1, 2, 3)'))
endfunction

function! s:suite.is_block_start_unbalanced_assignment() abort
    " An assignment whose RHS opens a paren without closing it signals
    " a multi-line block. A complete single-line assignment should not.
    call s:assert.truthy(s:IsBlockStart('x <- c(1,'))
    call s:assert.truthy(s:IsBlockStart('x <- data.frame('))
endfunction

function! s:suite.is_block_start_complete_assignment_is_not_block() abort
    call s:assert.falsy(s:IsBlockStart('x <- 1'))
    call s:assert.falsy(s:IsBlockStart('x = 42'))
endfunction

function! s:suite.is_block_start_pipe_chain_start() abort
    call s:assert.truthy(s:IsBlockStart('df |>'))
    call s:assert.truthy(s:IsBlockStart('df %>%'))
endfunction

function! s:suite.is_block_start_trailing_bracket() abort
    call s:assert.truthy(s:IsBlockStart('x <- matrix[1:10,'))
    call s:assert.truthy(s:IsBlockStart('y[ '))
endfunction

function! s:suite.is_block_start_negatives() abort
    call s:assert.falsy(s:IsBlockStart(''))
    call s:assert.falsy(s:IsBlockStart('# a comment'))
    call s:assert.falsy(s:IsBlockStart(')'))
endfunction

" =================================================================
" s:GetCodeBlock — pipe chains (Phase 1 path)
" =================================================================

function! s:suite.getcodeblock_returns_full_pipe_chain() abort
    call s:fixture([
        \ 'df |>',
        \ '  filter(x > 0) |>',
        \ '  select(a, b)',
        \ ], 1)
    let block = s:GetCodeBlock()
    call s:assert.equals(len(block), 3)
    call s:assert.equals(block[0], 'df |>')
    call s:assert.equals(block[2], '  select(a, b)')
endfunction

function! s:suite.getcodeblock_ggplot_plus_chain() abort
    call s:fixture([
        \ 'ggplot(df, aes(x, y)) +',
        \ '  geom_point() +',
        \ '  theme_minimal()',
        \ ], 1)
    let block = s:GetCodeBlock()
    call s:assert.equals(len(block), 3)
    call s:assert.equals(block[2], '  theme_minimal()')
endfunction

function! s:suite.getcodeblock_pipe_chain_with_blank_lines_between() abort
    " Blank lines within a chain are skipped, not treated as terminators.
    call s:fixture([
        \ 'df |>',
        \ '',
        \ '  filter(x > 0)',
        \ ], 1)
    let block = s:GetCodeBlock()
    call s:assert.truthy(len(block) >= 2)
    call s:assert.equals(block[0], 'df |>')
endfunction

" =================================================================
" s:GetCodeBlock — function definitions (Phase 2, brace matching)
" =================================================================

function! s:suite.getcodeblock_single_line_function_body() abort
    call s:fixture([
        \ 'f <- function(x) {',
        \ '  x + 1',
        \ '}',
        \ ], 1)
    let block = s:GetCodeBlock()
    call s:assert.equals(len(block), 3)
    call s:assert.equals(block[0], 'f <- function(x) {')
    call s:assert.equals(block[2], '}')
endfunction

function! s:suite.getcodeblock_nested_braces_do_not_terminate_early() abort
    call s:fixture([
        \ 'f <- function(x) {',
        \ '  if (x > 0) {',
        \ '    x',
        \ '  } else {',
        \ '    -x',
        \ '  }',
        \ '}',
        \ ], 1)
    let block = s:GetCodeBlock()
    call s:assert.equals(len(block), 7)
    call s:assert.equals(block[6], '}')
endfunction

function! s:suite.getcodeblock_function_with_signature_spanning_lines() abort
    " Opening brace is on a later line than the function keyword.
    call s:fixture([
        \ 'f <- function(',
        \ '  x,',
        \ '  y',
        \ ') {',
        \ '  x + y',
        \ '}',
        \ ], 1)
    let block = s:GetCodeBlock()
    call s:assert.equals(len(block), 6)
    call s:assert.equals(block[5], '}')
endfunction

" =================================================================
" s:GetCodeBlock — parenthesized expressions
" =================================================================

function! s:suite.getcodeblock_multiline_function_call() abort
    call s:fixture([
        \ 'print(',
        \ '  "hello"',
        \ ')',
        \ ], 1)
    let block = s:GetCodeBlock()
    call s:assert.equals(len(block), 3)
    call s:assert.equals(block[2], ')')
endfunction

function! s:suite.getcodeblock_multiline_c_call() abort
    call s:fixture([
        \ 'v <- c(',
        \ '  1,',
        \ '  2,',
        \ '  3',
        \ ')',
        \ ], 1)
    let block = s:GetCodeBlock()
    call s:assert.equals(len(block), 5)
    call s:assert.equals(block[4], ')')
endfunction
