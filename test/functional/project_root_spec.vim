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

" Moved to autoload in Phase 4 batch 1.
let s:GetProjectRoot     = function('zzvim_r#get_project_root')
let s:IsInsideZzcollab   = function('zzvim_r#is_inside_zzcollab')
let s:IsZzCollabProject  = function('zzvim_r#is_zzcollab_project')

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
    " Portability: compare by the function's contract (returned
    " path contains the .zzcollab marker) rather than exact-string
    " equality. Git Bash on Windows exposes tempname() via a
    " translated prefix (/tmp/... vs /c/Users/.../Temp/...) that
    " resolve() does not unify, so exact comparison is fragile.
    call mkdir(s:tmpdir . '/.zzcollab', 'p')
    execute 'lcd' fnameescape(s:tmpdir)
    let root = s:GetProjectRoot()
    call s:assert.not_equals(root, '')
    call s:assert.truthy(isdirectory(root . '/.zzcollab'))
endfunction

function! s:suite.finds_zzcollab_marker_in_parent_dir() abort
    call mkdir(s:tmpdir . '/.zzcollab', 'p')
    call mkdir(s:tmpdir . '/src/analysis', 'p')
    execute 'lcd' fnameescape(s:tmpdir . '/src/analysis')
    let root = s:GetProjectRoot()
    call s:assert.not_equals(root, '')
    call s:assert.truthy(isdirectory(root . '/.zzcollab'))
    " The returned path must be an ancestor of the current cwd.
    " getcwd() and root may use different path styles on Windows,
    " so normalize with fnamemodify(':p') first.
    let cwd_p = fnamemodify(getcwd(), ':p')
    let root_p = fnamemodify(root, ':p')
    call s:assert.truthy(stridx(cwd_p, root_p) >= 0)
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
    " Realistic Makefile with a leading .PHONY declaration; the
    " plugin's r:-target regex requires a preceding newline so a
    " lone first-line 'r:' is missed (see next spec).
    call writefile(['.PHONY: r', 'r:', "\tdocker run"], s:tmpdir . '/Makefile')
    call mkdir(s:tmpdir . '/sub', 'p')
    execute 'lcd' fnameescape(s:tmpdir . '/sub')
    call s:assert.truthy(s:IsZzCollabProject())
endfunction

function! s:suite.zzcollab_project_first_line_r_target_not_detected() abort
    " Documents a plugin bug: the regex used to detect a zzcollab
    " project is '\n\s*r\s*:', which requires a newline *before*
    " the 'r:' target. A Makefile whose very first line is 'r:'
    " is therefore not recognized as a zzcollab project, even
    " though Make itself would honor the target. A future fix
    " should use '\%(^\|\n\)\s*r\s*:' or equivalent.
    call writefile(['r:', "\tdocker run"], s:tmpdir . '/Makefile')
    execute 'lcd' fnameescape(s:tmpdir)
    call s:assert.falsy(s:IsZzCollabProject())
endfunction
