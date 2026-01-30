" ===========================================================================
" SIMPLIFIED PLOT MANAGEMENT
" ===========================================================================
" Architecture: Vim watches .plots/.signal, displays PNG, opens PDF for zoom
" R renders: PDF (vector master) + PNG (preview)
" Removed: adaptive polling, composite images, thumbnail gallery, config sync

" Track Docker R terminal buffer
let s:docker_r_terminal_bufnr = -1
let s:pane_title = 'zzvim-plot'
let s:poll_interval = 100
let s:plot_signal_mtime = 0

"------------------------------------------------------------------------------
" Path Helpers
"------------------------------------------------------------------------------
function! s:GetPlotsDir() abort
    return getcwd() . '/.plots'
endfunction

function! s:GetPlotFile() abort
    return s:GetPlotsDir() . '/current.png'
endfunction

function! s:GetPlotPdf() abort
    return s:GetPlotsDir() . '/current.pdf'
endfunction

function! s:GetSignalFile() abort
    return s:GetPlotsDir() . '/.signal'
endfunction

function! s:GetHistoryDir() abort
    return s:GetPlotsDir() . '/history'
endfunction

function! s:GetHistoryIndex() abort
    return s:GetHistoryDir() . '/index.json'
endfunction

"------------------------------------------------------------------------------
" Plot Watcher (Fixed 100ms polling)
"------------------------------------------------------------------------------
function! s:StartPlotWatcher() abort
    if exists('s:plot_watcher_timer')
        call timer_stop(s:plot_watcher_timer)
    endif
    let s:plot_watcher_timer = timer_start(s:poll_interval,
        \ function('s:CheckForNewPlot'), {'repeat': -1})
endfunction

function! s:StopPlotWatcher() abort
    if exists('s:plot_watcher_timer')
        call timer_stop(s:plot_watcher_timer)
        unlet s:plot_watcher_timer
    endif
endfunction

function! s:CheckForNewPlot(timer) abort
    let l:signal = s:GetSignalFile()
    if !filereadable(l:signal)
        return
    endif
    let l:mtime = getftime(l:signal)
    if l:mtime <= s:plot_signal_mtime
        return
    endif
    let s:plot_signal_mtime = l:mtime
    call s:DisplayPlot()
endfunction

"------------------------------------------------------------------------------
" Plot Display
"------------------------------------------------------------------------------
function! s:PlotPaneExists() abort
    let l:result = system('kitty @ ls 2>/dev/null')
    return l:result =~# s:pane_title
endfunction

function! s:DisplayPlot() abort
    let l:plot_file = s:GetPlotFile()
    if !filereadable(l:plot_file)
        return
    endif

    if s:PlotPaneExists()
        " Refresh existing pane
        call system('kitty @ send-text --match title:' . s:pane_title . " r")
    else
        " Create new pane
        call s:CreatePlotPane(l:plot_file)
    endif
endfunction

function! s:CreatePlotPane(plot_file) abort
    let l:script = '/tmp/zzvim_plot.sh'
    call writefile([
        \ '#!/bin/bash',
        \ 'PLOT_FILE="' . a:plot_file . '"',
        \ 'show_plot() {',
        \ '    clear',
        \ '    kitty +kitten icat --clear --align=left "$PLOT_FILE"',
        \ '    echo ""',
        \ '    echo "r=refresh | q=close"',
        \ '}',
        \ 'show_plot',
        \ 'while true; do',
        \ '    read -n1 -s key',
        \ '    case "$key" in',
        \ '        r|R) show_plot ;;',
        \ '        q|Q) exit 0 ;;',
        \ '    esac',
        \ 'done'
        \ ], l:script)
    call system('chmod +x ' . l:script)
    call system('kitty @ launch --location=vsplit --keep-focus --title ' .
        \ s:pane_title . ' ' . l:script . ' 2>/dev/null')
endfunction

"------------------------------------------------------------------------------
" Zoom - Open PDF (vector, infinite zoom)
"------------------------------------------------------------------------------
function! s:ZoomPlot() abort
    let l:pdf = s:GetPlotPdf()
    if filereadable(l:pdf)
        call system('open ' . shellescape(l:pdf))
        echom "Opened PDF (vector)"
    else
        call s:Error("No plot PDF available")
    endif
endfunction

"------------------------------------------------------------------------------
" Plot Navigation (via R)
"------------------------------------------------------------------------------
function! s:PlotPrev() abort
    call s:Send_to_r('plot_prev()', 1)
endfunction

function! s:PlotNext() abort
    call s:Send_to_r('plot_next()', 1)
endfunction

function! s:PlotHistory() abort
    call s:Send_to_r('plot_history()', 1)
endfunction

function! s:PlotGoto() abort
    let l:target = input('Plot ID or name: ')
    if empty(l:target)
        return
    endif
    if l:target =~# '^\d\+$'
        call s:Send_to_r('plot_goto(' . l:target . ')', 1)
    else
        call s:Send_to_r('plot_goto("' . l:target . '")', 1)
    endif
endfunction

function! s:PlotSearch() abort
    let l:pattern = input('Search pattern: ')
    if empty(l:pattern)
        return
    endif
    call s:Send_to_r('plot_search("' . l:pattern . '")', 1)
endfunction

"------------------------------------------------------------------------------
" Plot Export (via R)
"------------------------------------------------------------------------------
function! s:PlotSavePdf() abort
    let l:filename = input('Save PDF to: ', getcwd() . '/plot.pdf')
    if empty(l:filename)
        return
    endif
    call s:Send_to_r('save_plot("' . l:filename . '")', 1)
endfunction

function! s:PlotSavePng() abort
    let l:filename = input('Save PNG to: ', getcwd() . '/plot.png')
    if empty(l:filename)
        return
    endif
    call s:Send_to_r('save_plot("' . l:filename . '")', 1)
endfunction

"------------------------------------------------------------------------------
" Plot Gallery (Vim buffer with history)
"------------------------------------------------------------------------------
function! s:OpenPlotGallery() abort
    let l:index_file = s:GetHistoryIndex()
    if !filereadable(l:index_file)
        call s:Error("No plot history. Create plots with zzplot() first.")
        return
    endif

    let l:json_content = join(readfile(l:index_file), '')
    try
        let l:index = json_decode(l:json_content)
    catch
        call s:Error("Failed to parse plot history")
        return
    endtry

    if empty(get(l:index, 'plots', []))
        call s:Error("Plot history is empty")
        return
    endif

    " Create gallery buffer
    vnew
    setlocal buftype=nofile bufhidden=wipe noswapfile
    setlocal nonumber norelativenumber signcolumn=no
    file [Plot\ Gallery]

    let l:lines = []
    call add(l:lines, 'Plot Gallery')
    call add(l:lines, '============')
    call add(l:lines, 'Press 1-9 to view, Enter on line, q to close')
    call add(l:lines, '')

    let l:current = get(l:index, 'current', 0)
    for i in range(len(l:index.plots))
        let l:p = l:index.plots[i]
        let l:marker = (l:p.id == l:current) ? '> ' : '  '
        call add(l:lines, printf('%s[%d] %-20s %s', l:marker, i+1, l:p.name, l:p.created))
    endfor

    call add(l:lines, '')
    call add(l:lines, 'Total: ' . len(l:index.plots) . ' plots')

    call setline(1, l:lines)
    setlocal readonly nomodifiable

    let b:plot_index = l:index

    nnoremap <buffer> <silent> q :bwipe<CR>
    nnoremap <buffer> <silent> <Esc> :bwipe<CR>
    nnoremap <buffer> <silent> <CR> :call <SID>GallerySelectCurrent()<CR>
    for i in range(1, 9)
        execute 'nnoremap <buffer> <silent> ' . i . ' :call <SID>GallerySelect(' . i . ')<CR>'
    endfor
endfunction

function! s:GallerySelect(num) abort
    if !exists('b:plot_index')
        return
    endif
    if a:num > len(b:plot_index.plots)
        echom "Plot " . a:num . " not in history"
        return
    endif
    call s:Send_to_r('plot_goto(' . a:num . ')', 1)
    echom "Displaying plot " . a:num
endfunction

function! s:GallerySelectCurrent() abort
    let l:line = getline('.')
    let l:match = matchstr(l:line, '\[\zs\d\+\ze\]')
    if !empty(l:match)
        call s:GallerySelect(str2nr(l:match))
    endif
endfunction

"------------------------------------------------------------------------------
" Cleanup
"------------------------------------------------------------------------------
function! s:OnRTerminalClose() abort
    call s:StopPlotWatcher()
    call system('kitty @ close-window --match title:' . s:pane_title . ' 2>/dev/null')
    let s:docker_r_terminal_bufnr = -1
endfunction

function! s:CleanupPlotPaneIfRTerminal() abort
    let l:bufname = expand('<afile>')
    if l:bufname =~? 'R-\|r-\|R$\|!/.*R\|terminal.*R'
        call s:OnRTerminalClose()
    endif
endfunction

function! s:RTerminalExitCallback(job, exit_status) abort
    call s:OnRTerminalClose()
endfunction

"------------------------------------------------------------------------------
" Ex Commands
"------------------------------------------------------------------------------
command! -bar RPlotShow call s:DisplayPlot()
command! -bar RPlotZoom call s:ZoomPlot()
command! -bar RPlotPrev call s:PlotPrev()
command! -bar RPlotNext call s:PlotNext()
command! -bar RPlotHistory call s:PlotHistory()
command! -bar RPlotGallery call s:OpenPlotGallery()
command! -bar RPlotSavePdf call s:PlotSavePdf()
command! -bar RPlotSavePng call s:PlotSavePng()
command! -bar RPlotWatchStart call s:StartPlotWatcher()
command! -bar RPlotWatchStop call s:StopPlotWatcher()

" Debug command
command! -bar RPlotDebug echo "Signal: " . s:GetSignalFile() . " mtime=" . getftime(s:GetSignalFile()) . " cached=" . s:plot_signal_mtime . " | Pane exists: " . s:PlotPaneExists()

"------------------------------------------------------------------------------
" Key Mappings (to be added to autocmd section)
"------------------------------------------------------------------------------
" Plot commands:
"   <LocalLeader>]    Zoom plot (open PDF)
"   <LocalLeader>pp   Previous plot
"   <LocalLeader>pn   Next plot
"   <LocalLeader>ph   Plot history
"   <LocalLeader>pG   Plot gallery
"   <LocalLeader>ps   Save as PDF
"   <LocalLeader>pS   Save as PNG
