; docformat = 'rst'

function kcor_jd2time, jd, datetime=datetime
  compile_opt strictarr

  caldat, jd, month, day, year, hour, min, sec
  return, keyword_set(datetime)
              ? string(year, month, day, hour, min, sec, $
                       format='%04d-%02d-%02dT%02d:%02d:%02d')
              : string(hour, min, sec, format='%02d:%02d:%02d')
end
