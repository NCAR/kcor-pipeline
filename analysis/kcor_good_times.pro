; docformat = 'rst'

;+
; Find all the date/times for good KCor data.
;-
pro kcor_good_times, run=run, output_filename=output_filename
  compile_opt strictarr

  db = mgdbmysql()
  db->connect, config_filename=run->config('database/config_filename'), $
               config_section=run->config('database/config_section'), $
               status=status, error_message=error_message

  cmd = 'select date_obs from MLSO.kcor_img where producttype = 1 order by date_obs'
  results = db->query(cmd)

  times = transpose((results.date_obs)[2:*])
  years = strmid(times, 0, 4)
  months = strmid(times, 5, 2)
  days = strmid(times, 8, 2)
  hours = strmid(times, 11, 2)
  minutes = strmid(times, 14, 2)
  seconds = strmid(times, 17, 2)

  openw, lun, output_filename, /get_lun
  printf, lun, $
          years + ' ' + months + ' ' + days + ' ' + hours + ' ' + minutes + ' ' + seconds
  free_lun, lun

  obj_destroy, db
end


; main-level example program

date = '20130930'
config_filename = filepath('kcor.production.cfg', $
                           subdir=['..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

output_filename = 'kcor_good_times.txt'

kcor_good_times, run=run, output_filename=output_filename

end
