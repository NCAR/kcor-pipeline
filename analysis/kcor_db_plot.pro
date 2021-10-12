; docformat = 'rst'

db = mgdbmysql()
db->connect, config_filename='~/.mysqldb', config_section='mgalloy@databases'
data = db->query('select * from mlso_sgs order by date_obs', count=n_rows)
obj_destroy, db

dates = dblarr(n_rows)

for d = 0L, n_rows - 1L do begin
  dates[d] = kcor_dateobs2julian(data[d].date_obs)
endfor

plot, dates, data.sgsscint, psym=3, $
      xstyle=1, xrange=[julday(9, 30, 2013), julday()], xtickformat='label_date'

end