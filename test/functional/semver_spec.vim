" Specs for s:CompareSemver.
"
" This is the canary spec: CompareSemver is pure (no buffer state,
" no side effects), so it validates the test harness wiring before
" heavier specs depend on it. If this file passes, the funcref
" factory in plugin/zzvim-R.vim works.

let s:suite = themis#suite('CompareSemver')
let s:assert = themis#helper('assert')

" After Phase 4 POC: CompareSemver now lives in autoload as
" zzvim_r#compare_semver. No test-harness indirection needed.
let s:CompareSemver = function('zzvim_r#compare_semver')

function! s:suite.equal_versions_return_zero() abort
    call s:assert.equals(s:CompareSemver('1.0.0', '1.0.0'), 0)
    call s:assert.equals(s:CompareSemver('2.3.4', '2.3.4'), 0)
endfunction

function! s:suite.a_lower_than_b_returns_negative_one() abort
    call s:assert.equals(s:CompareSemver('1.0.0', '1.0.1'), -1)
    call s:assert.equals(s:CompareSemver('1.0.0', '1.1.0'), -1)
    call s:assert.equals(s:CompareSemver('1.0.0', '2.0.0'), -1)
endfunction

function! s:suite.a_greater_than_b_returns_one() abort
    call s:assert.equals(s:CompareSemver('1.0.1', '1.0.0'), 1)
    call s:assert.equals(s:CompareSemver('1.1.0', '1.0.0'), 1)
    call s:assert.equals(s:CompareSemver('2.0.0', '1.0.0'), 1)
endfunction

function! s:suite.missing_components_default_to_zero() abort
    " '1.0' should compare equal to '1.0.0' because missing patch
    " component defaults to 0 per the implementation.
    call s:assert.equals(s:CompareSemver('1.0', '1.0.0'), 0)
    call s:assert.equals(s:CompareSemver('1', '1.0.0'), 0)
endfunction

function! s:suite.lexicographic_order_does_not_leak() abort
    " Numeric rather than string comparison: '10.0.0' > '2.0.0'.
    call s:assert.equals(s:CompareSemver('10.0.0', '2.0.0'), 1)
    call s:assert.equals(s:CompareSemver('2.0.0', '10.0.0'), -1)
endfunction
