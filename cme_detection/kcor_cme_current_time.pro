; docformat = 'rst'

;+
; Return the "current" time in ISO 8601 format, i.e.,
; "YYYY-MM-DDTHH:MM:SSZ". The "current" time depends on the mode of doing the
; CME detection: either the actual current time in "nowcase" mode or the current
; time of the simulator in "simulated_realtime_nowcast" mode.
;
; :Returns:
;   string
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
function kcor_cme_current_time, run=run
  compile_opt strictarr

  mode = run->config('cme/mode')
  time_dir = run->config('simulator/time_dir')

  if (strlowcase(mode) eq 'simulated_realtime_nowcast' && n_elements(time_dir) gt 0L) then begin
    basename = string(run.date, format='(%"%s.time.txt")')
    filename = filepath(basename, root=time_dir)

    datetime = ''
    openr, lun, filename, /get_lun
    readf, lun, datetime
    free_lun, lun

    date = long(kcor_decompose_date(strmid(datetime, 0, 8)))
    time = long(kcor_decompose_time(strmid(datetime, 9, 6)))

    now = string(date, time, format='(%"%04d-%02d-%02dT%02d-%02d-%02dZ")')
  endif else begin
    iso8601_fmt = '(C(CYI4.4, "-", CMOI2.2, "-", CDI2.2, "T", CHI2.2, ":", CMI2.2, ":", CSI2.2, "Z"))'
    ; add 10 hours to get UT time
    now = string(julday() + 10.0D/24.0D, format=iso8601_fmt)
  endelse

  return, now
end


; main-level example program

date = '20170904'
config_basename = 'kcor.cme-test.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

print, kcor_cme_current_time(run=run)

obj_destroy, run

end
