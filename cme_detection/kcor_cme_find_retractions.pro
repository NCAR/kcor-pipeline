; docformat = 'rst'

;+
; Compare CMEs in "to retract" list ("YYYYMMDD.kcor.cme.toretract.txt") to CMEs
; in the retracted list ("YYYYMMDD.kcor.cme.retracted.txt" to find CMEs that
; have been marked to retract by the observers, but haven't been retracted yet.
;
; :Returns:
;   `strarr(count)` of lines with the UT time and position angle, or `!null` if
;   no retractions to do
;
; :Params:
;   observing_date : in, required, type=string
;     HST date in the form "YYYYMMDD"
;   list_dir : in, required, type=string
;     directory containing list and retraction files
;-
function kcor_cme_find_retractions, observing_date, list_dir, count=count
  compile_opt strictarr

  count = 0L
  toretract_basename = string(observing_date, format='(%"%s.kcor.cme.toretract.txt")')
  toretract_filename = filepath(toretract_basename, root=list_dir)
  if (~file_test(toretract_filename)) then return, !null
  n_toretract = file_lines(toretract_filename)
  if (n_toretract eq 0L) then return, !null
  toretract = strarr(n_toretract)
  openr, lun, toretract_filename, /get_lun
  readf, lun, toretract
  free_lun, lun

  retracted_basename = string(observing_date, format='(%"%s.kcor.cme.retracted.txt")')
  retracted_filename = filepath(retracted_basename, root=list_dir)
  if (~file_test(retracted_filename)) then begin
    count = n_toretract
    return, toretract
  endif

  n_retracted = file_lines(retracted_filename)
  if (n_retracted eq 0L) then return, toretract
  retracted = strarr(n_retracted)
  openr, lun, retracted_filename, /get_lun
  readf, lun, retracted
  free_lun, lun
  
  n_matches = mg_match(toretract, retracted, a_matches=retracted_indices)
  not_retracted_indices = mg_complement(retracted_indices, n_toretract, count=count)
  if (count eq 0L) then return, !null

  return, toretract[not_retracted_indices]
end


; main-level example program

list_dir = '.'
date = '20220303'

kcor_cme_update_list, date, date + '.181500', 135.2, 'toretract', list_dir
kcor_cme_update_list, date, date + '.183700', 212.6, 'toretract', list_dir
to_retract = kcor_cme_find_retractions(date, '.', count=count)
if (count eq 0L) then begin
  print, 'No CMEs to retract'
endif else begin
  print, count, format='%d CMEs to retract'
  print, transpose(to_retract)
endelse

for c = 0L, count - 1L do begin
  tokens = strsplit(to_retract[c], /extract)
  time = tokens[0]
  angle = float(tokens[1])
  print, time, angle, format='retracting CME at %s at position angle %0.2f'
  kcor_cme_update_list, date, tokens[0], float(tokens[1]), 'retracted', list_dir
endfor

to_retract = kcor_cme_find_retractions(date, '.', count=count)
help, count

end

