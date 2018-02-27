; docformat = 'rst'

;+
; Compare two rows of the `kcor_sw` table.
;
; :Returns:
;   0 for equal, 1 for not equal
;-
function kcor_compare_sw, sw1, sw2, log_name=log_name
  compile_opt strictarr

  if (n_elements(sw1) eq 0L && n_elements(sw2) eq 0L) then return, 0
  if (n_elements(sw1) eq 0L || n_elements(sw2) eq 0L) then return, 1

  compare_fields = ['dmodswid', $
                    'distort', $
                    'sw_version', $
                    'bunit', $
                    'bzero', $
                    'bscale', $
                    'labviewid', $
                    'socketcamid', $
                    'sw_revision', $
                    'sky_pol_factor', $
                    'sky_bias']

  compare_fields = strupcase(compare_fields)
  fields1 = tag_names(sw1)
  fields2 = tag_names(sw2)

  for f = 0L, n_elements(compare_fields) - 1L do begin
    ind1 = where(fields1 eq compare_fields[f], count1)
    ind2 = where(fields2 eq compare_fields[f], count2)
    if (count1 eq 0 && count2 eq 0L) then continue
    if (count1 eq 0 || count2 eq 0L) then return, 1
    if (sw1.(ind1[0]) ne sw2.(ind2[0])) then begin
      mg_log, '%s (%s) field does not match %s (%s)', $
              fields1[ind1[0]], sw1.(ind1[0]), field2[ind2[0]], sw2.(ind2[0]), $
              name=log_name, /debug
      return, 1
    endif
  endfor

  return, 0
end
