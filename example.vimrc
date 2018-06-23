" +++++++++++ SYNTAX ++++++++++++++
au BufRead,BufNewFile *.ncl set filetype=ncl
au! Syntax newlang source $VIM/ncl.vim
syntax on

filetype plugin indent on

" general completion options
set completeopt=longest,menu

" autointend
set ai
set ru

set showmatch

"tab = 4 spaces
set tabstop=4

" autocompletion for file
set autochdir
imap <F7> <C-X><C-F>

" list left side
"set nu

" supress autointend when pasting, press <F2> before
set pastetoggle=<F2>

" Use <Tab> instead of <C-N> for autocompletion if already written letter
" Use TAB to complete when typing words, else inserts TABs as usual.
" Uses dictionary and source files to find matching words to complete.
"
" See help completion for source,
" Note: usual completion is on <C-n> but more trouble to press all the time.
" Never type the same word twice and maybe learn a new spellings!
" Use the Linux dictionary when spelling is in doubt.
" Window users can copy the file to their machine.
function! Tab_Or_Complete()
  if col('.')>1 && strpart( getline('.'), col('.')-2, 3 ) =~ '^\w'
    return "\<C-N>"
  else
 	  return "\<Tab>"
  endif
endfunction
:inoremap <Tab> <C-R>=Tab_Or_Complete()<CR>


"++++++++++++++++++++++++++++++++++++
"++++++++ Variable COMPLETION +++++++
"++++++++++++++++++++++++++++++++++++
" reads in all variables from certain datasets
" by executing cdo vardes datasets and completes those if
"  * you hit <C-X><C-U>
"  * vars_completion is enabled
"  * cdo is installed
"  * ncl_completion or cdo_completion are enabled

" 'ENABLE' variablecompletion or 'DISABLE'
let s:vars_completion = 'DISABLE' 

" variable completion data gathering
" set path for file to act cdo vardes on
" CHANGE for your own data
if s:vars_completion == 'ENABLE'
  silent echo "vars completion enabled"
  let s:vars_data_dir = '/your_outdata_path/'
  let s:vars_data_strs = ['hamocc/lkm0101_hamocc_data_2d_mm_19990101_19991231.nc', 'mpiom/lkm0101_mpiom_data_2d_mm_19990101_19991231.nc', 'mpiom/lkm0101_mpiom_data_3d_mm_19990101_19991231.nc', 'hamocc/lkm0101_hamocc_data_3d_ym_19990101_19991231.nc' ]

  let s:vars_data = [] 
  for s:vars_data_str in s:vars_data_strs
    let s:cdo_vardes_str = 'cdo vardes ' . s:vars_data_dir . s:vars_data_str
    let s:vars_data += split(system(s:cdo_vardes_str), nr2char(10))
  endfor
endif



"++++++++++++++++++++++++++++++++++++
"++++++++++ NCL COMPLETION ++++++++++
"++++++++++++++++++++++++++++++++++++
" reads in all ncl functions and resources from .txt-files and completes those if
"  * you hit <C-X><C-U>
"  * ncl_completion is enabled
"  * filename extension is 'ncl'
"
" also a variable completion for your most-used files is done if
"  * cdo is installed
"  * filepath of those datasets is set
"  * vars completion is enabled

" 'ENABLE' ncl completion or 'DISABLE'
let s:ncl_completion = 'ENABLE'
if bufname("%")[-3:] == 'ncl' && s:ncl_completion == 'ENABLE'
  let s:completion_language='ncl'

  " read in ncl functions and resources
  let s:ncl_func = readfile($HOME . '/.vim/NCL_functions.txt')
  let s:ncl_resources = readfile($HOME . '/.vim/NCL_resources.txt')
 
  " vars complete
  " check if cdo is installed
  let s:cdo_installed = system('cdo --version 2>&1 | head -n 1 | grep -o "[0-9].[0-9].[0-9]"')
  if empty(s:cdo_installed) && s:vars_completion == 'ENABLE'
    echo "cdo not found"
    let s:vars_completion = 'DISABLE'
  endif 

  set completefunc=NCLComplete
  " modify completition options, more info in :help completeopt or
  " http://vimdoc.sourceforge.net/htmldoc/options.html#'completeopt' 
  set completeopt=longest,menu

    " to be executed by user by C-X C-U
    fun! NCLComplete(findstart, base)
      if a:findstart && s:ncl_completion == 'ENABLE'
        let l:line = getline('.')
        let l:start = col('.') - 1
        while l:start > 0 && l:line[l:start - 1] =~ '\a'
          let l:start -= 1
        endwhile
        return start
      elseif s:ncl_completion == 'ENABLE'
        " Record what matches − we pass this to complete() later
        let l:res = []
        " Find cdo matches
        for l:line in s:ncl_func
        " Check if it matches what we're trying to complete
          if split(l:line)[0] =~ '^' . a:base
          " It matches! See :help complete() for the full docs on the key names
          " for this dict.
            call add(l:res, {
              \ 'icase': 1,
              \ 'word': split(l:line)[0],
              \ 'abbr': split(l:line)[0],
              \ 'menu': 'NCL Func: ' . join(split(l:line)[1:]),
              \ })
          endif
        endfor

		for l:line in s:ncl_resources
        " Check if it matches what we're trying to complete
          if split(l:line)[0] =~ '^' . a:base
          " It matches! See :help complete() for the full docs on the key names
          " for this dict. 
		  " change length of description, now 12 words are shown, last part
		  " shows the default
            call add(l:res, {
              \ 'icase': 1,
              \ 'word': split(l:line)[0],
              \ 'abbr': split(l:line)[0],
              \ 'menu': 'NCL Res: ' . join(split(l:line)[1:12]) . '... ' . join(split(l:line)[-2:]),
              \ })
          endif
        endfor

        " varibale completion
        if s:vars_completion == 'ENABLE'
          " Find variable matches
          for l:line in s:vars_data
          " Check if it matches what we're trying to complete
            if split(l:line)[1] =~ '^' . a:base
            " It matches! See :help complete() for the full docs on the key names
            " for this dict.
              call add(l:res, {
                \ 'icase': 1,
                \ 'word': split(l:line)[1],
                \ 'abbr': split(l:line)[1],
                \ 'menu': 'Variable: ' . join(split(l:line)[2:]),
                \ })
            endif
          endfor
        endif

        return res
      endif
    endfun

endif
