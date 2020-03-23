" Vim indent file
" Language:	Vim script
" Maintainer:	Bram Moolenaar <Bram@vim.org>
" Last Change:	2019 Oct 31

" Only load this indent file when no other was loaded.
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

setlocal indentexpr=GetVimIndent()
setlocal indentkeys+==end,=else,=cat,=fina,=END,0\\,0=\"\\\ 

let b:undo_indent = "setl indentkeys< indentexpr<"

" Only define the function once.
if exists("*GetVimIndent")
  finish
endif
let s:keepcpo= &cpo
set cpo&vim

function GetVimIndent()
  let ignorecase_save = &ignorecase
  try
    let &ignorecase = 0
    return GetVimIndentIntern()
  finally
    let &ignorecase = ignorecase_save
  endtry
endfunc

let s:lineContPat = '^\s*\(\\\|"\\ \)'

function GetVimIndentIntern()
  " Find a non-blank line above the current line.
  let lnum = prevnonblank(v:lnum - 1)

  " If the current line doesn't start with '\' or '"\ ' and below a line that
  " starts with '\' or '"\ ', use the indent of the line above it.
  let cur_text = getline(v:lnum)
  if cur_text !~ s:lineContPat
    while lnum > 0 && getline(lnum) =~ s:lineContPat
      let lnum = lnum - 1
    endwhile
  endif

  " At the start of the file use zero indent.
  if lnum == 0
    return 0
  endif
  let prev_text = getline(lnum)

  " Add a 'shiftwidth' after :if, :while, :try, :catch, :finally, :function
  " and :else.  Add it three times for a line that starts with '\' or '"\ '
  " after a line that doesn't (or g:vim_indent_cont if it exists).
  let ind = indent(lnum)

  " In heredoc indenting works completely differently.
  if has('syntax_items') 
    let syn_here = synIDattr(synID(v:lnum, 1, 1), "name")
    if syn_here =~ 'vimLetHereDocStop'
      " End of heredoc: use indent of matching start line
      let lnum = v:lnum - 1
      while lnum > 0
	if synIDattr(synID(lnum, 1, 1), "name") !~ 'vimLetHereDoc'
	  return indent(lnum)
	endif
	let lnum -= 1
      endwhile
      return 0
    endif
    if syn_here =~ 'vimLetHereDoc'
      if synIDattr(synID(lnum, 1, 1), "name") !~ 'vimLetHereDoc'
	" First line in heredoc: increase indent
	return ind + shiftwidth()
      endif
      " Heredoc continues: no change in indent
      return ind
    endif
  endif

  if cur_text =~ s:lineContPat && v:lnum > 1 && prev_text !~ s:lineContPat
    if exists("g:vim_indent_cont")
      let ind = ind + g:vim_indent_cont
    else
      let ind = ind + shiftwidth() * 3
    endif
  elseif prev_text =~ '^\s*aug\%[roup]\s\+' && prev_text !~ '^\s*aug\%[roup]\s\+[eE][nN][dD]\>'
    let ind = ind + shiftwidth()
  else
    " A line starting with :au does not increment/decrement indent.
    if prev_text !~ '^\s*au\%[tocmd]'
      let i = match(prev_text, '\(^\||\)\s*\(if\|wh\%[ile]\|for\|try\|cat\%[ch]\|fina\%[lly]\|fu\%[nction]\|el\%[seif]\)\>')
      if i >= 0
	let ind += shiftwidth()
	if strpart(prev_text, i, 1) == '|' && has('syntax_items')
	      \ && synIDattr(synID(lnum, i, 1), "name") =~ '\(Comment\|String\)$'
	  let ind -= shiftwidth()
	endif
      endif
    endif
  endif

  " If the previous line contains an "end" after a pipe, but not in an ":au"
  " command.  And not when there is a backslash before the pipe.
  " And when syntax HL is enabled avoid a match inside a string.
  let i = match(prev_text, '[^\\]|\s*\(ene\@!\)')
  if i > 0 && prev_text !~ '^\s*au\%[tocmd]'
    if !has('syntax_items') || synIDattr(synID(lnum, i + 2, 1), "name") !~ '\(Comment\|String\)$'
      let ind = ind - shiftwidth()
    endif
  endif


  " Subtract a 'shiftwidth' on a :endif, :endwhile, :catch, :finally, :endtry,
  " :endfun, :else and :augroup END.
  if cur_text =~ '^\s*\(ene\@!\|cat\|fina\|el\|aug\%[roup]\s\+[eE][nN][dD]\)'
    let ind = ind - shiftwidth()
  endif

  return ind
endfunction

let &cpo = s:keepcpo
unlet s:keepcpo

" vim:sw=2
