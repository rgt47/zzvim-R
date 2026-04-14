" Specs for s:MoveNextChunk and s:MovePrevChunk.
"
" These functions move the cursor between R Markdown / Quarto
" code chunks delimited by lines matching g:zzvim_r_chunk_start
" (default '^```{'). Both mutate cursor position rather than
" return a value, so specs assert line('.') after the call.
"
" Per CLAUDE.md these functions were rewritten in v2.3 after a
" significant regression. Keep coverage dense.

let s:suite = themis#suite('ChunkNav')
let s:assert = themis#helper('assert')

let s:MoveNextChunk = g:ZzvimRTestFunc('MoveNextChunk')
let s:MovePrevChunk = g:ZzvimRTestFunc('MovePrevChunk')

" A minimal Rmd-like fixture with three chunks. Line numbers:
"   1  # Title
"   2
"   3  ```{r chunk-a}
"   4  x <- 1
"   5  ```
"   6
"   7  Some prose.
"   8
"   9  ```{r chunk-b}
"   10 y <- 2
"   11 ```
"   12
"   13 ```{r chunk-c}
"   14 z <- 3
"   15 ```
let s:rmd_fixture = [
    \ '# Title',
    \ '',
    \ '```{r chunk-a}',
    \ 'x <- 1',
    \ '```',
    \ '',
    \ 'Some prose.',
    \ '',
    \ '```{r chunk-b}',
    \ 'y <- 2',
    \ '```',
    \ '',
    \ '```{r chunk-c}',
    \ 'z <- 3',
    \ '```',
    \ ]

function! s:fixture(lnum) abort
    enew!
    call setline(1, s:rmd_fixture)
    call cursor(a:lnum, 1)
endfunction

" =================================================================
" s:MoveNextChunk
" =================================================================

function! s:suite.next_from_prose_lands_inside_next_chunk() abort
    " Cursor on line 1 (title), no chunk start above. Forward search
    " finds chunk-a at line 3, cursor lands on line 4 (x <- 1).
    call s:fixture(1)
    silent! call s:MoveNextChunk()
    call s:assert.equals(line('.'), 4)
endfunction

function! s:suite.next_from_chunk_start_moves_into_same_chunk() abort
    " On chunk-a start line 3. Current-line branch moves to line 4.
    call s:fixture(3)
    silent! call s:MoveNextChunk()
    call s:assert.equals(line('.'), 4)
endfunction

function! s:suite.next_from_prose_between_chunks_finds_following() abort
    " Cursor on line 7 (prose between chunk-a and chunk-b).
    " Forward search finds chunk-b at line 9, cursor lands on line 10.
    call s:fixture(7)
    silent! call s:MoveNextChunk()
    call s:assert.equals(line('.'), 10)
endfunction

function! s:suite.next_inside_first_chunk_finds_second() abort
    " Cursor inside chunk-a (line 4, the `x <- 1` line).
    " Forward search skips the current chunk end and finds chunk-b.
    call s:fixture(4)
    silent! call s:MoveNextChunk()
    call s:assert.equals(line('.'), 10)
endfunction

function! s:suite.next_past_last_chunk_does_not_advance() abort
    " Cursor on the final line; no further chunks forward.
    call s:fixture(15)
    silent! call s:MoveNextChunk()
    call s:assert.equals(line('.'), 15)
endfunction

" =================================================================
" s:MovePrevChunk
" =================================================================

function! s:suite.prev_from_last_chunk_content_finds_previous() abort
    " Cursor inside chunk-c (line 14). Previous chunk is chunk-b
    " at line 9; cursor should land on line 10 (first line inside).
    call s:fixture(14)
    silent! let rv = s:MovePrevChunk()
    call s:assert.equals(rv, 1)
    call s:assert.equals(line('.'), 10)
endfunction

function! s:suite.prev_from_chunk_start_finds_previous_chunk() abort
    " On chunk-b start line 9. Should move to chunk-a (line 3 + 1).
    call s:fixture(9)
    silent! let rv = s:MovePrevChunk()
    call s:assert.equals(rv, 1)
    call s:assert.equals(line('.'), 4)
endfunction

function! s:suite.prev_from_prose_before_any_chunk_fails() abort
    " Cursor on line 1 (title); no prior chunk. Expect return 0
    " and cursor restored to line 1.
    call s:fixture(1)
    silent! let rv = s:MovePrevChunk()
    call s:assert.equals(rv, 0)
    call s:assert.equals(line('.'), 1)
endfunction

function! s:suite.prev_from_between_chunks_currently_fails() abort
    " Cursor on line 7 (prose between chunk-a end at line 5 and
    " chunk-b start at line 9). The current implementation's
    " backward search for a chunk start finds chunk-a's start
    " line, then tries to move *before* it, finds nothing, and
    " returns 0. It does not check whether chunk-a has actually
    " closed at line 5.
    "
    " Arguably a bug: a user on prose line 7 pressing 'prev chunk'
    " would probably expect to land inside chunk-a. Filed for
    " follow-up; this spec documents today's behavior so a future
    " fix intentionally flips the assertion rather than breaking
    " silently.
    call s:fixture(7)
    silent! let rv = s:MovePrevChunk()
    call s:assert.equals(rv, 0)
    call s:assert.equals(line('.'), 7)
endfunction

function! s:suite.prev_inside_first_chunk_fails_and_restores() abort
    " Cursor inside chunk-a (line 4). No earlier chunk exists.
    " Expect rv=0 and cursor restored.
    call s:fixture(4)
    silent! let rv = s:MovePrevChunk()
    call s:assert.equals(rv, 0)
    call s:assert.equals(line('.'), 4)
endfunction
