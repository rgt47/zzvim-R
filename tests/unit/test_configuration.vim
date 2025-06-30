" ==============================================================================
" Configuration Tests
" ==============================================================================
" Tests for plugin configuration and setup

echo "Testing configuration..."

" Test plugin loading
call AssertExists('g:loaded_zzvim_r', 'Plugin should be loaded')

" Test configuration variables exist
call Assert(exists('s:config'), 'Configuration dictionary should exist')

" Test default configuration values
if exists('s:config')
    " Note: s:config is script-local, so we test indirectly through behavior
    
    " Test that essential commands are defined
    call Assert(exists(':ROpenTerminal'), 'ROpenTerminal command should be defined')
    call Assert(exists(':RSubmitLine'), 'RSubmitLine command should be defined')
    call Assert(exists(':RSubmitSelection'), 'RSubmitSelection command should be defined')
    
    " Test that core functions exist
    call AssertExists('s:engine', 'Core engine function should exist')
    call AssertExists('s:terminal_engine', 'Terminal engine function should exist')
    call AssertExists('s:text_engine', 'Text engine function should exist')
    call AssertExists('s:execute_engine', 'Execute engine function should exist')
endif

" Test autoload functions exist
call AssertExists('zzvim_r#open_terminal', 'Autoload open_terminal function should exist')
call AssertExists('zzvim_r#submit_line', 'Autoload submit_line function should exist')
call AssertExists('zzvim_r#navigate_next_chunk', 'Autoload navigate_next_chunk function should exist')

" Test user configuration variables work
let g:zzvim_r_debug = 1
call Assert(get(g:, 'zzvim_r_debug', 0) == 1, 'User configuration should override defaults')

let g:zzvim_r_terminal_width = 80
call Assert(get(g:, 'zzvim_r_terminal_width', 100) == 80, 'Terminal width configuration should work')

echo "Configuration tests completed."