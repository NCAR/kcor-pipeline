; docformat = 'rst'

function kcor_cme_ut_date, ut_time, observing_day
  compile_opt strictarr

  hour  = long(strmid(ut_time, 0, 2))

  year  = long(strmid(observing_day, 0, 4))
  month = long(strmid(observing_day, 4, 2))
  day   = long(strmid(observing_day, 6, 2))

  if (hour lt 10) then begin
    jd = julday(month, day, year) + 1.0d
    caldat, jd, month, day, year
  endif

  ut_date = string(year, month, day, format='(%"%04d-%02d-%02d")')
  return, ut_date
end
