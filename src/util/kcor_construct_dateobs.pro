; docformat = 'rst'

;+
; Construct a date/time string from a structure with the date/time components as
; fields, i.e., as returned by `kcor_parse_dateobs`.
;
; :Returns:
;   string
;
; :Params:
;   date_struct : in, required, type=structure
;     structure with year, month, day, hour, minute, and second fields
;-
function kcor_construct_dateobs, date_struct
  compile_opt strictarr

  return, string(date_struct.year, $
                 date_struct.month, $
                 date_struct.day, $
                 date_struct.hour, $
                 date_struct.minute, $
                 date_struct.second, $
                 format='(%"%04d-%02d-%02dT%02d:%02d:%02d")')
end
