set clipboard=unnamedplus
imap kj <Esc>
nmap gl $

unmap <Space>
exmap open_file obcommand switcher:open
exmap search_word obcommand global-search:open
exmap save_file obcommand editor:save-file
exmap close_window obcommand workspace:close
exmap buf1 obcommand workspace:goto-tab-1
exmap buf2 obcommand workspace:goto-tab-2
exmap buf3 obcommand workspace:goto-tab-3
exmap buf4 obcommand workspace:goto-tab-4
exmap buf5 obcommand workspace:goto-tab-5
exmap buf6 obcommand workspace:goto-tab-6
exmap buf7 obcommand workspace:goto-tab-7
exmap buf8 obcommand workspace:goto-tab-8
exmap buf9 obcommand workspace:goto-last-tab

nmap <Space>va ggVG
nmap <Space>ff :open_file<CR>
nmap <Space>fw :search_word<CR>
nmap <Space>w :save_file<CR>
nmap <Space>q :close_window<CR>
nmap <Space>1 :buf1<CR>
nmap <Space>2 :buf2<CR>
nmap <Space>3 :buf3<CR>
nmap <Space>4 :buf4<CR>
nmap <Space>5 :buf5<CR>
nmap <Space>6 :buf6<CR>
nmap <Space>7 :buf7<CR>
nmap <Space>8 :buf8<CR>
nmap <Space>9 :buf9<CR>
