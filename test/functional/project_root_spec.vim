" Specs for s:GetProjectRoot, s:IsInsideZzcollab, s:IsZzCollabProject.
"
" These functions drive which R terminal-launch path zzvim-R picks
" when the user presses <LocalLeader>r: Docker (via make r) vs host
" R with renv vs vanilla. Wrong classification sends users into the
" wrong runtime, so coverage matters.
"
" Unlike earlier P0 specs these touch the filesystem. Each spec
" creates a fresh temp dir, populates project markers, lcds into
" it, asserts, and cleans up.

let s:suite = themis#suite('ProjectRoot')
let s:assert = themis#helper('assert')

let s:GetProjectRoot     = g:ZzvimRTestFunc('GetProjectRoot')
let s:IsInsideZzcollab   = g:ZzvimRTestFunc('IsInsideZzcollab')
let s:IsZzCollabProject  = g:ZzvimRTestFunc('IsZzCollabProject')

" Create an empty temp directory for a spec to populate.
function! s:mktempdir() abort
    let d = tempname()
    call mkdir(d, 'p')
    return d
endfunction

" Remove a tree. Relies on `delete(path, 'rf')` which recurses.
function! s:rmtree(path) abort
    if isdirectory(a:path)
        call delete(a:path, 'rf')
    endif
endfunction

let s:saved_cwd = ''
let s:tmpdir = ''

function! s:suite.before_each() abort
    let s:saved_cwd = getcwd()
    let s:tmpdir = s:mktempdir()
    " Ensure g:zzvim_r_project_root override is not set between specs.
    if exists('g:zzvim_r_project_root') | unlet g:zzvim_r_project_root | endif
endfunction

function! s:suite.after_each() abort
    execute 'lcd' fnameescape(s:saved_cwd)
    call s:rmtree(s:tmpdir)
endfunction

" =================================================================
" s:GetProjectRoot
" =================================================================

function! s:suite.returns_empty_when_no_marker_present() abort
    execute 'lcd' fnameescape(s:tmpdir)
    call s:assert.equals(s:GetProjectRoot(), '')
endfunction

function! s:suite.finds_zzcollab_marker_in_current_dir() abort
    call mkdir(s:tmpdir . '/.zzcollab', 'p')
    execute 'lcd' fnameescape(s:tmpdir)
    " resolve() normalizes symlinks on macOS where /var -> /private/var.
    call s:assert.equals(resolve(s:GetProjectRoot()), resolve(s:tmpdir))
endfunction

function! s:suite.finds_zzcollab_marker_in_parent_dir() abort
    call mkdir(s:tmpdir . '/.zzcollab', 'p')
    call mkdir(s:tmpdir . '/src/analysis', 'p')
    execute 'lcd' fnameescape(s:tmpdir . '/src/analysis')
    call s:assert.equals(resolve(s:GetProjectRoot()), resolve(s:tmpdir))
endfunction

function! s:suite.explicit_override_short_circuits_search() abort
    " g:zzvim_r_project_root wins even if no marker exists.
    let g:zzvim_r_project_root = s:tmpdir
    execute 'lcd' fnameescape(s:saved_cwd)
    call s:assert.equals(s:GetProjectRoot(), s:tmpdir)
endfunction

" =================================================================
" s:IsInsideZzcollab
" =================================================================

function! s:suite.is_inside_zzcollab_true_when_marker_exists() abort
    call mkdir(s:tmpdir . '/.zzcollab', 'p')
    execute 'lcd' fnameescape(s:tmpdir)
    call s:assert.truthy(s:IsInsideZzcollab())
endfunction

function! s:suite.is_inside_zzcollab_false_in_empty_dir() abort
    execute 'lcd' fnameescape(s:tmpdir)
    call s:assert.falsy(s:IsInsideZzcollab())
endfunction

" =================================================================
" s:IsZzCollabProject — Makefile with an 'r:' target
" =================================================================

function! s:suite.zzcollab_project_true_for_makefile_with_r_target() abort
    call writefile(['.PHONY: r', 'r:', "\tdocker run --rm -it r-base"], s:tmpdir . '/Makefile')
    execute 'lcd' fnameescape(s:tmpdir)
    call s:assert.truthy(s:IsZzCollabProject())
endfunction

function! s:suite.zzcollab_project_false_for_makefile_without_r_target() abort
    call writefile(['.PHONY: build', 'build:', "\techo build"], s:tmpdir . '/Makefile')
    execute 'lcd' fnameescape(s:tmpdir)
    call s:assert.falsy(s:IsZzCollabProject())
endfunction

function! s:suite.zzcollab_project_false_when_no_makefile() abort
    execute 'lcd' fnameescape(s:tmpdir)
    call s:assert.falsy(s:IsZzCollabProject())
endfunction

function! s:suite.zzcollab_project_finds_makefile_in_parent() abort
    call writefile(['r:', "\tdocker run"], s:tmpdir . '/Makefile')
    call mkdir(s:tmpdir . '/sub', 'p')
    execute 'lcd' fnameescape(s:tmpdir . '/sub')
    call s:assert.truthy(s:IsZzCollabProject())
endfunction
