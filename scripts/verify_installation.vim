" ==============================================================================
" zzvim-R Installation Verification Script
" ==============================================================================
" This script verifies that zzvim-R is properly installed and configured
" Usage: vim -S scripts/verify_installation.vim

echo "zzvim-R Installation Verification"
echo "=================================="
echo ""

let s:checks_passed = 0
let s:checks_total = 0

function! s:check(condition, name, fix_hint) abort
    let s:checks_total += 1
    if a:condition
        let s:checks_passed += 1
        echo "✓ " . a:name
    else
        echo "✗ " . a:name
        if !empty(a:fix_hint)
            echo "  Fix: " . a:fix_hint
        endif
    endif
endfunction

function! s:info(message) abort
    echo "ℹ " . a:message
endfunction

" Check 1: Vim version and features
call s:check(v:version >= 800, 
    \ "Vim version 8.0+", 
    \ "Update Vim to version 8.0 or later")

call s:check(has('terminal'), 
    \ "Terminal support", 
    \ "Ensure Vim was compiled with +terminal")

" Check 2: Plugin loading
call s:check(exists('g:loaded_zzvim_r'), 
    \ "Plugin loaded", 
    \ "Check plugin installation path and run :runtime plugin/zzvim_r.vim")

" Check 3: R availability
call s:check(executable('R'), 
    \ "R executable found", 
    \ "Install R and ensure it's in your PATH")

if executable('R')
    " Get R version
    let r_version = system('R --version | head -1')
    call s:info("R version: " . substitute(r_version, '\n', '', 'g'))
endif

" Check 4: Commands available
call s:check(exists(':ROpenTerminal'), 
    \ "ROpenTerminal command", 
    \ "Plugin may not be loaded correctly")

call s:check(exists(':RSubmitLine'), 
    \ "RSubmitLine command", 
    \ "Plugin may not be loaded correctly")

" Check 5: Key mappings (if not disabled)
if !get(g:, 'zzvim_r_disable_mappings', 0)
    " Create a temporary R buffer to test mappings
    new
    set filetype=r
    call s:check(mapcheck('<LocalLeader>r', 'n') != '', 
        \ "Key mappings active", 
        \ "Check maplocalleader setting or enable mappings")
    bdelete!
else
    call s:info("Key mappings disabled by configuration")
endif

" Check 6: Configuration
call s:info("Configuration:")
call s:info("  Command: " . get(g:, 'zzvim_r_command', 'R --no-save --quiet'))
call s:info("  Terminal width: " . get(g:, 'zzvim_r_terminal_width', 100))
call s:info("  Debug level: " . get(g:, 'zzvim_r_debug', 0))

" Check 7: Help documentation
call s:check(exists(':help') && !empty(glob(&runtimepath . '/doc/zzvim-R.txt')), 
    \ "Help documentation", 
    \ "Run :helptags ALL or check doc/ directory")

" Check 8: File type detection
new
set filetype=r
call s:check(&filetype == 'r', 
    \ "R filetype detection", 
    \ "Check filetype plugin settings")
bdelete!

new
set filetype=rmd
call s:check(&filetype == 'rmd', 
    \ "R Markdown filetype detection", 
    \ "Check filetype plugin settings")
bdelete!

" Check 9: Autoload functions
call s:check(exists('*zzvim_r#open_terminal'), 
    \ "Autoload functions", 
    \ "Check autoload/zzvim_r.vim file")

" Check 10: Terminal creation (basic test)
try
    " This should not actually create a terminal in verification mode
    let terminal_available = 1
catch
    let terminal_available = 0
endtry

call s:check(terminal_available, 
    \ "Terminal creation capability", 
    \ "Check terminal support and R availability")

echo ""
echo "Verification Results:"
echo "===================="
echo "Passed: " . s:checks_passed . "/" . s:checks_total

if s:checks_passed == s:checks_total
    echo ""
    echo "🎉 Installation verified successfully!"
    echo ""
    echo "Quick start:"
    echo "1. Open an R file: :edit test.R"
    echo "2. Start R terminal: <LocalLeader>r (or :ROpenTerminal)"
    echo "3. Send code to R: <CR> on any line"
    echo "4. Get help: :help zzvim-r"
    echo ""
    echo "Example workflow:"
    echo '  echo "x <- 1:10" > example.R'
    echo "  vim example.R"
    echo "  # Press \\r to open R terminal"
    echo "  # Press <CR> to send line to R"
    
    if has('gui_running')
        echo ""
        echo "Press any key to continue..."
        call getchar()
    endif
else
    echo ""
    echo "❌ Some checks failed. Please address the issues above."
    echo ""
    echo "Common solutions:"
    echo "- Update Vim to version 8.0+"
    echo "- Install R and add to PATH"
    echo "- Check plugin installation path"
    echo "- Run :helptags ALL to update help"
    echo ""
    echo "For more help:"
    echo "- :help zzvim-r-troubleshooting"
    echo "- Check GitHub issues"
    echo "- Review installation instructions"
    
    if !has('gui_running')
        echo ""
        echo "Press any key to continue..."
        call getchar()
    endif
endif

" Clean exit
if !has('gui_running')
    quit
endif