" Simple test runner that outputs to file
set nomore
source test_files/comprehensive_test.vim
redir! > /tmp/test_output.txt
call RunComprehensiveTests()
redir END
qall!