" Simple test runner for block matching tests
" Usage: vim -S test_files/run_block_tests.vim

echo "Starting Block Matching Test Suite..."
echo ""

" Run the comprehensive block matching tests
source test_files/test_block_matching.vim

echo ""
echo "Block matching tests completed."
echo "To run full test suite: vim -S test_files/comprehensive_test.vim"

" Exit vim after running tests (useful for automated testing)
" Uncomment the next line if you want vim to exit automatically
" quit