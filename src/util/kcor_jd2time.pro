; docformat = 'rst'

function kcor_jd2time, jd
  compile_opt strictarr

  caldat, jd, month, day, year, hour, min, sec
  return, string(hour, min, sec, format='%02d:%02d:%02d')
end
