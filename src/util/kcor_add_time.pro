; docformat = 'rst'


;+
; Add the given amount of time to the given KCor raw basename or DATE-OBS
;
; :Returns:
;   a new KCor raw basename  or a DATE-OBS date/time string
;
; :Params:
;   dt_or_filename : in, required, type=string
;     either a KCor raw basename (such as "20171006_022015_kcor.fts.gz") or a
;     DATE-OBS type date/time (such as "2017-10-06T02:20:15")
;   time_increment : in, required, type=long
;     time to add to the `dt_or_filename` parameter in minutes
;-
function kcor_add_time, dt_or_filename, time_increment
  compile_opt strictarr

  is_basename = strpos(dt_or_filename, '.fts') ne -1

  filename_fmt = '%Y%m%d_%H%M%S'
  dateobs_fmt = '%Y-%m-%dT%H:%M:%S'

  if (is_basename) then begin
    dt = mg_datetime(strmid(dt_or_filename, 0, 15), format=filename_fmt)
  endif else begin
    dt = mg_datetime(dt_or_filename, format=dateobs_fmt)
  endelse

  dt_increment = mg_timedelta(minutes=time_increment)

  new_dt = dt + dt_increment

  if (is_basename) then begin
    result = new_dt->strftime(filename_fmt) + '_kcor.fts'
    is_zipped = strpos(dt_or_filename, '.gz') ne -1
    if (is_zipped) then result += '.gz'
  endif else begin
    result = new_dt->strftime(dateobs_fmt)
  endelse

  obj_destroy, [dt, dt_increment, new_dt]
  return, result
end


; main-level example

increment = 6
dts = ['20171006_022015_kcor.fts.gz', $
       '20171005_235515_kcor.fts.gz', $
       '2017-10-06T02:20:15', $
       '2017-12-31T23:56:15']
for d = 0L, n_elements(dts) - 1L do begin
  new_basename = kcor_add_time(dts[d], increment)
  print, dts[d], new_basename, format='%s -> %s'
endfor

increment = -6
dts = ['20171006_000515_kcor.fts.gz', $
       '20171005_235515_kcor.fts.gz', $
       '2017-10-06T00:05:15', $
       '2017-12-31T23:56:15']
for d = 0L, n_elements(dts) - 1L do begin
  new_basename = kcor_add_time(dts[d], increment)
  print, dts[d], new_basename, format='%s -> %s'
endfor

end
