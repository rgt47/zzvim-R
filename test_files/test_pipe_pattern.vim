" Test pipe pattern detection

let test_lines = [
    \ 'missing_summary <- raw_data %>%',
    \ '  summarise_all(~sum(is.na(.))) %>%',
    \ '  t() %>%',
    \ '  as.data.frame() %>%',
    \ '  setNames("Missing_Count") %>%'
    \ ]

echo "Testing pipe pattern '%[^%]*%\\s*$':"
for line in test_lines
    echo "'" . line . "' -> " . (line =~# '%[^%]*%\s*$')
endfor

echo ""
echo "Testing specific patterns:"
echo "'%>%' matches: " . ('%>%' =~# '%[^%]*%')
echo "'%>% ' matches: " . ('%>% ' =~# '%[^%]*%\s*$')
echo "'data %>%' matches: " . ('data %>%' =~# '%[^%]*%\s*$')