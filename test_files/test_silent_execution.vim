" Test silent execution by opening R file and using commands
source plugin/zzvim-R.vim

echo "Opening R file..."
edit test_files/test_silent_r.R

echo "File opened. Testing RSendLine command..."

" Move to first line and send it
normal! gg

" Use the Ex command to send line
RSendLine

echo "Command executed. If you see this without 'Press ENTER', it worked!"

" Wait a moment
sleep 100m

echo "Test complete."