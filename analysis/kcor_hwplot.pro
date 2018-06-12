; docformat = 'rst'

pro kcor_hwplot, run=run
  compile_opt strictarr
  ;on_error, 2

  db = mgdbmysql()
  db->connect, config_filename=run.database_config_filename, $
               config_section=run.database_config_section

  q = 'select * from kcor_hw h order by h.date'
  hw_versions = db->query(q, $
                          status=status, error_message=error_msg, sql_statement=sql_cmd)

  if (status ne 0L) then begin
    mg_log, 'status %d', status, /error
    mg_log, error_msg, /error
    mg_log, 'cmd: %s', sql_cmd, /error
  endif

  t = mg_table(n_rows_to_print=50)

  t['id'] = hw_versions.hw_id

  t['date'] = strmid(hw_versions.date, 0, 10)
  t['diffsrid'] = hw_versions.diffsrid
  t['bopal'] = hw_versions.bopal

  t['rcamid'] = hw_versions.rcamid
  t['tcamid'] = hw_versions.tcamid

  t['rcamlut'] = hw_versions.rcamlut
  t['tcamlut'] = hw_versions.tcamlut

  t['modltrid'] = hw_versions.modltrid
  t['o1id'] = hw_versions.o1id

  t['occltrid'] = hw_versions.occltrid
  t['filterid'] = hw_versions.filterid
  t['calpolid'] = hw_versions.calpolid

  t->setProperty, column='id', format='%3d', width=3

  t->setProperty, column='date', width=10
  t->setProperty, column='diffsrid', width=8
  t->setProperty, column='bopal', format='%11.6g', width=11

  t->setProperty, column='rcamid', width=18
  t->setProperty, column='tcamid', width=18

  t->setProperty, column='rcamlut', width=14
  t->setProperty, column='tcamlut', width=14

  t->setProperty, column='modltrid', width=8
  t->setProperty, column='o1id', width=7

  t->setProperty, column='occltrid', width=10
  t->setProperty, column='filterid', width=12
  t->setProperty, column='calpolid', width=11

  print, t
  obj_destroy, t
end


; main-level example program

date = '20130930'
config_filename = filepath('kcor.mgalloy.mahi.analysis.cfg', $
                           subdir=['..', 'config'], $
                           root=mg_src_root())

run = kcor_run(date, config_filename=config_filename)

kcor_hwplot, run=run

end
