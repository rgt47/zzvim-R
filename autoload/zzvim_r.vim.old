" =============================================================================
" Public API for zzvim-R core functions
" =============================================================================
" This file provides public access to core plugin functions for modular components

" Get buffer-specific R terminal
function! zzvim_r#GetBufferTerminal() abort
    " Need to call the main plugin's function
    " This requires access to script-local functions, which is tricky
    " For now, we'll implement a fallback
    
    " Try to find R terminal for current buffer
    let buffer_name = expand('%:t:r')  " Get filename without extension
    let terminal_name = 'R-' . buffer_name
    
    " Look for terminal with this name
    for buf_nr in range(1, bufnr('$'))
        if bufname(buf_nr) ==# terminal_name && term_getstatus(buf_nr) =~# 'running'
            return buf_nr
        endif
    endfor
    
    " Fallback: look for any R terminal
    for buf_nr in term_list()
        if bufname(buf_nr) =~# '^R-' && term_getstatus(buf_nr) =~# 'running'
            return buf_nr
        endif
    endfor
    
    return -1
endfunction

" Send command to R terminal
function! zzvim_r#Send_to_r(cmd, stay_on_line) abort
    let terminal_id = zzvim_r#GetBufferTerminal()
    if terminal_id == -1
        return 0
    endif
    
    " Send command to terminal
    call term_sendkeys(terminal_id, a:cmd . "\n")
    
    " Small delay to let command process
    sleep 50m
    
    return 1
endfunction