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

  ; remove comments from toretract list to be able to compare to list of already
  ; retracted; should look like "HH:MM:SS PPP.PP deg"
  _toretract = toretract
  valid = bytarr(n_elements(_toretract))
  for c = 0L, n_toretract - 1L do begin
    pos = strsplit(_toretract[c], count=count, length=len)
    case count of
      0: valid[c] = 0B
      1: begin
          time = strmid(_toretract[c], pos[0], len[0])
          angle = 0.0
          valid[c] = 1B
        end
      else: begin
          time = strmid(_toretract[c], pos[0], len[0])
          angle = float(strmid(_toretract[c], pos[1], len[1]))
          valid[c] = 1B
        end
    endcase
    if (valid[c]) then _toretract[c] = string(time, angle, format=kcor_cme_list_format())
  endfor

  valid_indices = where(valid, /null)
  _toretract = _toretract[valid_indices]
  toretract = toretract[valid_indices]

  ; now compare the list of CMEs to retract to the list of already retracted
  n_matches = mg_match(_toretract, retracted, a_matches=retracted_indices)
  not_retracted_indices = mg_complement(retracted_indices, n_toretract, count=count)
  if (count eq 0L) then return, !null

  return, toretract[not_retracted_indices]
end


; main-level example program

list_dir = '.'
date = '20260821'

to_retract = kcor_cme_find_retractions(date, list_dir, count=count)
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
  ; kcor_cme_update_list, date, tokens[0], float(tokens[1]), 'retracted', list_dir
endfor

end

