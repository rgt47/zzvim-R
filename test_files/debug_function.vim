source plugin/zzvim-R.vim

" Test if functions exist
echo "Function exists check:"
echo "ZzvimRTestIsBlockStart: " . exists('*ZzvimRTestIsBlockStart')
echo "s:IsBlockStart: " . exists('*s:IsBlockStart')

" Test the pattern directly
echo "Direct pattern test: " . ('library(pacman)' =~# '[a-zA-Z_][a-zA-Z0-9_.]*\s*(')

" Try calling the function
try
    echo "Function call result: " . ZzvimRTestIsBlockStart('library(pacman)')
catch
    echo "Error calling function: " . v:exception
endtry