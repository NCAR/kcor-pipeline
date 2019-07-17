; docformat = 'rst'

;+
; Determine if a string date in the form "YYYYMMDD" represents a date.
;
; :Returns:
;   1 if valid date, 0 if otherwise
;
; :Params:
;   date : in, required, type=string
;     date to check
;
; :Keywords:
;   msg : out, optional, type=string
;     message of why the date is invalid, undefined if valid
;-
function kcor_valid_date, date, msg=msg
  compile_opt strictarr
  on_error, 2

  is_valid = 1B

  if (n_elements(date) eq 0L) then begin
    msg = 'date undefined'
    is_valid = 0B
    goto, done
  endif

  type = size(date, /type)
  if (type ne 7) then begin
    msg = string(type, format='(%"invalid type %d for date")')
    is_valid = 0B
    goto, done
  endif

  if (strlen(date) ne 8) then begin
    msg = string(date, format='(%"invalid date: %s")')
    is_valid = 0B
    goto, done
  endif

  date_parts = long(kcor_decompose_date(date))

  if (date_parts[1] lt 1 || date_parts[1] gt 12) then begin
    msg = string(date_parts[1], date, format='(invalid month %02d in date %s)')
    is_valid = 0B
    goto, done
  endif

  if (date_parts[2] lt 1 || date_parts[2] gt 31) then begin
    msg = string(date_parts[2], date, format='(invalid day %02d in date %s)')
    is_valid = 0B
    goto, done
  endif

  done:
  return, is_valid
end
