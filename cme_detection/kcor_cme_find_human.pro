; docformat = 'rst'

function kcor_cme_find_human, observing_date, list_dir, count=count
  compile_opt strictarr

  count = 0L
  human_basename = string(observing_date, format='(%"%s.kcor.cme.human.txt")')
  human_filename = filepath(human_basename, root=list_dir)
  if (~file_test(human_filename)) then return, !null
  n_human = file_lines(human_filename)
  if (n_human eq 0L) then return, !null
  human = strarr(n_human)
  openr, lun, human_filename, /get_lun
  readf, lun, human
  free_lun, lun

  sent_human_basename = string(observing_date, format='(%"%s.kcor.cme.human-sent.txt")')
  sent_human_filename = filepath(sent_human_basename, root=list_dir)
  if (~file_test(sent_human_filename)) then begin
    count = n_human
    return, human
  endif

  n_sent_human = file_lines(sent_human_filename)
  if (n_sent_human eq 0L) then return, human
  sent_human = strarr(n_sent_human)
  openr, lun, sent_human_filename, /get_lun
  readf, lun, sent_human
  free_lun, lun
  
  ; now compare the list of CMEs to retract to the list of already retracted
  n_matches = mg_match(human, sent_human, a_matches=sent_human_indices)
  not_sent_human_indices = mg_complement(sent_human_indices, n_human, count=count)
  if (count eq 0L) then return, !null

  return, human[not_sent_human_indices]
end
