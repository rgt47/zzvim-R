scriptencoding utf-8
" Smoke tests for zzvim-R plugin, intended for headless CI.
"
" Scope: existence checks only (plugin loads, config vars registered,
" core Ex commands defined). Functional assertions on submission,
" chunk navigation, and pattern detection belong in a themis suite
" under test/functional/ (planned as a 1.0 release gate).
"
" Invoked by .github/workflows/test.yml.

" Load the plugin (handle relative path)
if filereadable('plugin/zzvim-R.vim')
    source plugin/zzvim-R.vim
elseif filereadable('../plugin/zzvim-R.vim')
    source ../plugin/zzvim-R.vim
else
    echo "ERROR: Cannot find plugin/zzvim-R.vim"
    cquit!
endif

echo "=========================================="
echo "         zzvim-R CI Test Suite"
echo "=========================================="

let failed_tests = 0

" Test 1: Plugin loads successfully
if exists('g:loaded_zzvim_r') && g:loaded_zzvim_r == 1
    echo "✓ PASS | Plugin loaded successfully"
else
    echo "✗ FAIL | Plugin failed to load"
    let failed_tests += 1
endif

" Test 2: Version variable exists and matches plugin header
if !exists('g:zzvim_r_version')
    echo "✗ FAIL | Version variable missing"
    let failed_tests += 1
else
    " Parse 'Version: X.Y.Z' out of the plugin file header and
    " compare to g:zzvim_r_version. Catches drift between the
    " comment block and the runtime constant.
    let plugin_path = filereadable('plugin/zzvim-R.vim') ? 'plugin/zzvim-R.vim' : '../plugin/zzvim-R.vim'
    let header = readfile(plugin_path, '', 20)
    let header_version = ''
    for line in header
        let m = matchlist(line, '^"\s*Version:\s*\(\S\+\)')
        if !empty(m) | let header_version = m[1] | break | endif
    endfor
    if header_version ==# ''
        echo "✗ FAIL | Could not parse Version: from plugin header"
        let failed_tests += 1
    elseif header_version !=# g:zzvim_r_version
        echo "✗ FAIL | Version mismatch: header=" . header_version . " g:zzvim_r_version=" . g:zzvim_r_version
        let failed_tests += 1
    else
        echo "✓ PASS | Version consistent: " . g:zzvim_r_version
    endif
endif

" Test 3: Vim version compatibility
if v:version >= 800
    echo "✓ PASS | Vim version compatible: " . v:version
else
    echo "✗ FAIL | Vim version too old: " . v:version
    let failed_tests += 1
endif

" Test 4: Basic configuration variables exist
let config_vars = ['zzvim_r_command', 'zzvim_r_chunk_start', 'zzvim_r_chunk_end']
for var in config_vars
    if exists('g:' . var)
        echo "✓ PASS | Config variable exists: g:" . var
    else
        echo "✗ FAIL | Config variable missing: g:" . var
        let failed_tests += 1
    endif
endfor

" Test 5: Ex commands exist
let ex_commands = ['ROpenTerminal', 'RSendLine', 'RSendChunk', 'RHead', 'RStr']
for cmd in ex_commands
    if exists(':' . cmd)
        echo "✓ PASS | Ex command exists: :" . cmd
    else
        echo "✗ FAIL | Ex command missing: :" . cmd
        let failed_tests += 1
    endif
endfor

echo "=========================================="
if failed_tests == 0
    echo "🎉 ALL CI TESTS PASSED! (" . (4 + len(config_vars) + len(ex_commands)) . " tests)"
    echo "Plugin is ready for production use."
    " Force immediate exit with success code
    execute 'qall!'
else
    echo "❌ " . failed_tests . " TEST(S) FAILED!"
    echo "Plugin needs fixes before deployment."
    " Force immediate exit with error code
    execute 'cquit!'
endif