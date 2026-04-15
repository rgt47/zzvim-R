" ============================================================================
" zzvim-R autoload entry point
" ============================================================================
" Logic extracted from plugin/zzvim-R.vim. Loaded lazily on first
" reference to a zzvim_r# function, which keeps Vim startup cost
" bounded regardless of plugin feature surface.
"
" Phase 4 proof-of-concept: contains the first extracted function
" (compare_semver). Subsequent commits migrate the remaining
" script-local functions following the same pattern.
" ============================================================================

" Compare two semver-style version strings (e.g. '1.0.0' vs '1.0.1').
" Missing components (patch, minor) default to 0, so '1.0' compares
" equal to '1.0.0'. Numeric, not lexicographic: '10.0.0' > '2.0.0'.
" Returns -1 if a < b, 0 if equal, 1 if a > b.
function! zzvim_r#compare_semver(a, b) abort
    let pa = split(a:a, '\.')
    let pb = split(a:b, '\.')
    for i in range(3)
        let na = str2nr(get(pa, i, '0'))
        let nb = str2nr(get(pb, i, '0'))
        if na < nb | return -1 | endif
        if na > nb | return 1 | endif
    endfor
    return 0
endfunction
