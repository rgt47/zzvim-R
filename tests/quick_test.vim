" Quick test to verify plugin loads
set nocompatible
let &runtimepath = expand('<sfile>:p:h:h') . ',' . &runtimepath
let g:zzvim_r_disable_mappings = 1
runtime plugin/zzvim_r.vim

echo "Plugin loaded: " . (exists('g:loaded_zzvim_r') ? 'YES' : 'NO')
echo "Commands exist: " . (exists(':ROpenTerminal') ? 'YES' : 'NO')
echo "Autoload functions: " . (exists('*zzvim_r#open_terminal') ? 'YES' : 'NO')

quit