; docformat = 'rst'

;+
; Update rolling 28-day synoptic maps.
;
; :Params:
;   date : in, required, type=string
;     date in the form YYYYMMDD
;
; :Keywords:
;   config_filename : in, required, type=string
;     config filename
;-
pro kcor_update_synoptic_maps, date, config_filename=config_filename
  compile_opt strictarr

  run = kcor_run(date, config_filename=config_filename)
  db = kcordbmysql()
  db->connect, config_filename=run->config('database/config_filename'), $
               config_section=run->config('database/config_section')

  kcor_rolling_synoptic_map, database=db, run=run
  kcor_rolling_synoptic_map, database=db, run=run, /enhanced

  obj_destroy, [db, run]
end


; main-level example program

date = '20201105'
config_filename = filepath('kcor.reprocess.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
kcor_update_synoptic_maps, date, config_filename=config_filename

end
