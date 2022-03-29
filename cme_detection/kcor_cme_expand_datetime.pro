; docformat = 'rst'

;+
; Example a UT date/time from simple notation to ISO notation, e.g.:
;
;   20220329.075337
;
; to
;
;   2022-03-29T07:53:37Z
;
; :Returns:
;   expanded date as a string
;
; :Params:
;   datetime : in, required, type=string
;     date in simple form, "YYYYMMDD.HHMMSS"
;-
function kcor_cme_expand_datetime, datetime
  compile_opt strictarr

  date_parts = kcor_decompose_date(strmid(datetime, 0, 8))
  time_parts = kcor_decompose_time(strmid(datetime, 9, 6))

  fmt = '(%"%s-%s-%sT%s:%s:%sZ")'
  return, string(date_parts, time_parts, format=fmt)
end


; main-level example program

end
