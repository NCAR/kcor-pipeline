; docformat = 'rst'

;+
; Compare two rows of a table given a set of columns.
;
; :Returns:
;   0 for equal, 1 for not equal
;-
function kcor_compare_rows, row1, row2, compare_fields=compare_fields, log_name=log_name
  compile_opt strictarr

  if (n_elements(row1) eq 0L && n_elements(row2) eq 0L) then return, 0
  if (n_elements(row1) eq 0L || n_elements(row2) eq 0L) then return, 1

  fields1 = tag_names(row1)
  fields2 = tag_names(row2)

  for f = 0L, n_elements(compare_fields) - 1L do begin
    ind1 = where(fields1 eq compare_fields[f], count1)
    ind2 = where(fields2 eq compare_fields[f], count2)
    if (count1 eq 0 && count2 eq 0L) then continue
    if (count1 eq 0 || count2 eq 0L) then return, 1
    if (row1.(ind1[0]) ne row2.(ind2[0])) then begin
      val1 = strtrim(row1.(ind1[0]), 2)
      val2 = strtrim(row2.(ind2[0]), 2)
      mg_log, '%s (%s) != %s (%s)', $
              fields1[ind1[0]], val1, fields2[ind2[0]], val2, $
              name=log_name, /debug
      return, 1
    endif
  endfor

  return, 0
end
