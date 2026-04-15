scriptencoding utf-8
set nocompatible
" Announce test-run to the plugin. Gates any input()-driven prompts
" so headless Neovim on Windows does not block the smoke step.
let g:zzvim_r_testing = 1
" Smoke tests for zzvim-R plugin, intended for headless CI.
"
" Scope: existence and consistency checks. Verifies that the plugin
" loads, the declared version matches between source locations, core
" configuration variables are registered, every :R* command declared
" in plugin/zzvim-R.vim is actually defined, and a representative
" set of <LocalLeader> mappings resolves once a filetype=r buffer
" is active.
"
" Behavioral assertions (submission correctness, chunk navigation,
" pattern detection) live in the themis suite under test/functional/.
"
" Invoked by .github/workflows/test.yml.
"
" Run locally:  vim -es -c 'source test/ci_smoke.vim'
" Exit 0 on all-green, 1 (via cquit!) on any failure.

" ---------------------------------------------------------------------------
" Load the plugin (handle relative path for in-repo vs subdirectory runs)
" ---------------------------------------------------------------------------
if filereadable('plugin/zzvim-R.vim')
    let s:repo_root = getcwd()
    let s:plugin_path = 'plugin/zzvim-R.vim'
elseif filereadable('../plugin/zzvim-R.vim')
    let s:repo_root = fnamemodify(getcwd(), ':h')
    let s:plugin_path = '../plugin/zzvim-R.vim'
else
    echo "ERROR: Cannot find plugin/zzvim-R.vim"
    cquit!
endif
" Put the repo on runtimepath so autoload/zzvimr/*.vim resolves.
" Without this, the FileType autocmd chain aborts on the first
" zzvimr#terminal_graphics#init() call and subsequent mapping
" autocmds never register, producing spurious failures here.
execute 'set runtimepath^=' . fnameescape(s:repo_root)
execute 'source' s:plugin_path

echo "=========================================="
echo "         zzvim-R CI Smoke Tests"
echo "=========================================="

let s:failed = 0
let s:passed = 0

function! s:Pass(msg) abort
    echo '✓ PASS | ' . a:msg
    let s:passed += 1
endfunction

function! s:Fail(msg) abort
    echo '✗ FAIL | ' . a:msg
    let s:failed += 1
endfunction

" ---------------------------------------------------------------------------
" Test 1: Plugin load guard set
" ---------------------------------------------------------------------------
if exists('g:loaded_zzvim_r') && g:loaded_zzvim_r == 1
    call s:Pass('Plugin loaded (g:loaded_zzvim_r = 1)')
else
    call s:Fail('Plugin failed to load')
endif

" ---------------------------------------------------------------------------
" Test 2: Version variable matches plugin header
" ---------------------------------------------------------------------------
if !exists('g:zzvim_r_version')
    call s:Fail('g:zzvim_r_version missing')
else
    let s:header = readfile(s:plugin_path, '', 20)
    let s:header_version = ''
    for s:line in s:header
        let s:m = matchlist(s:line, '^"\s*Version:\s*\(\S\+\)')
        if !empty(s:m) | let s:header_version = s:m[1] | break | endif
    endfor
    if s:header_version ==# ''
        call s:Fail('Could not parse "Version:" from plugin header')
    elseif s:header_version !=# g:zzvim_r_version
        call s:Fail('Version mismatch: header=' . s:header_version . ' runtime=' . g:zzvim_r_version)
    else
        call s:Pass('Version consistent: ' . g:zzvim_r_version)
    endif
endif

" ---------------------------------------------------------------------------
" Test 3: Vim version floor
" ---------------------------------------------------------------------------
if v:version >= 800 || has('nvim')
    call s:Pass('Vim/Neovim version acceptable: ' . v:version . (has('nvim') ? ' (Neovim)' : ''))
else
    call s:Fail('Vim version too old: ' . v:version)
endif

" ---------------------------------------------------------------------------
" Test 4: Core configuration variables registered
" ---------------------------------------------------------------------------
let s:config_vars = ['zzvim_r_command', 'zzvim_r_terminal_width', 'zzvim_r_terminal_height', 'zzvim_r_chunk_start', 'zzvim_r_chunk_end']
for s:var in s:config_vars
    if exists('g:' . s:var)
        call s:Pass('Config var: g:' . s:var)
    else
        call s:Fail('Config var missing: g:' . s:var)
    endif
endfor

" ---------------------------------------------------------------------------
" Test 5: Every :R* command declared in plugin file is actually defined.
" Parses `command! [-flags ...] RName ...` lines out of the plugin
" source and verifies exists(':RName'). Catches silent refactor
" breakage where a command declaration is removed but docs/tests
" still expect it.
" ---------------------------------------------------------------------------
let s:plugin_lines = readfile(s:plugin_path)
let s:declared_cmds = []
for s:line in s:plugin_lines
    let s:m = matchlist(s:line, '^command!\s\+\%(-\S\+\s\+\)*\(R[A-Za-z_]\+\)')
    if !empty(s:m) | call add(s:declared_cmds, s:m[1]) | endif
endfor
call sort(s:declared_cmds)
call uniq(s:declared_cmds)

if len(s:declared_cmds) < 30
    call s:Fail('Extracted only ' . len(s:declared_cmds) . ' :R* commands from plugin; regex may be broken')
else
    let s:missing_cmds = []
    for s:cmd in s:declared_cmds
        if !exists(':' . s:cmd) | call add(s:missing_cmds, s:cmd) | endif
    endfor
    if empty(s:missing_cmds)
        call s:Pass('All ' . len(s:declared_cmds) . ' declared :R* commands are defined')
    else
        call s:Fail(len(s:missing_cmds) . ' declared :R* commands not defined: ' . join(s:missing_cmds, ', '))
    endif
endif

" ---------------------------------------------------------------------------
" Test 6: Representative <LocalLeader> mappings resolve for filetype=r.
" Mappings are registered via `autocmd FileType r,rmd,quarto`, so
" they only bind after a buffer acquires filetype=r. Exercise that
" path by opening a scratch buffer, setting filetype, and using
" maparg() to confirm each expected mapping has an RHS.
"
" The checked list is the subset advertised prominently in README;
" keep this in sync with the README 'Key Mappings' table.
" ---------------------------------------------------------------------------
enew
setlocal buftype=nofile
setfiletype r
" setfiletype does not re-fire FileType for an empty unnamed buffer
" reliably in -es mode; force it:
doautocmd FileType

let s:maplocalleader = exists('g:maplocalleader') ? g:maplocalleader : '\'
let s:expected_maps = ['r', 'rr', 'rh', 'w', 'h', 's', 'd', 'j', 'k', 'l']
let s:missing_maps = []
for s:key in s:expected_maps
    let s:lhs = s:maplocalleader . s:key
    if maparg(s:lhs, 'n') ==# ''
        call add(s:missing_maps, s:lhs)
    endif
endfor
if empty(s:missing_maps)
    call s:Pass('All ' . len(s:expected_maps) . ' representative <LocalLeader> normal-mode mappings resolve')
else
    call s:Fail(len(s:missing_maps) . ' mappings missing: ' . join(s:missing_maps, ', '))
endif

if maparg('<CR>', 'n') ==# ''
    call s:Fail('<CR> normal-mode mapping not registered on filetype=r buffer')
else
    call s:Pass('<CR> mapping registered on filetype=r buffer')
endif

" ---------------------------------------------------------------------------
" Summary
" ---------------------------------------------------------------------------
echo "=========================================="
if s:failed == 0
    echo '✓ ALL SMOKE TESTS PASSED (' . s:passed . ')'
    execute 'qall!'
else
    echo '✗ ' . s:failed . ' of ' . (s:passed + s:failed) . ' TESTS FAILED'
    execute 'cquit!'
endif
