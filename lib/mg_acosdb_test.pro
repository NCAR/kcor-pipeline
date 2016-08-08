; docformat = 'rst'

db = mgdbmysql()
db->setProperty, mysql_secure_auth=0
db->connect, config_filename='~/.mysqldb', $
             config_section='mgalloy@athena'
db->getProperty, host_name=host
print, host, format='(%"connected to %s...\n")'

print, db, format='(A, /, 4(A-20))'
print

db->setProperty, database='MLSO'

print, db, format='(A, /, 4(A-20))'
print

result = db->query('select * from file limit 10')

print, 'ID', 'Date/time', 'Observer', 'Location', 'Filename', format='(%"%-4s  %-20s  %-12s  %-12s  %s")'
lines = string(bytarr(30) + (byte('-'))[0])
print, lines, lines, lines, lines, lines, format='(%"%-4s  %-20s  %-12s  %-12s  %s")'

;help, result[0]

for i = 0L, n_elements(result) - 1L do begin
  observers = db->query('select * from observer where id=%d', result[i].observer)
  location = db->query('select * from location where id=%d', result[i].location)

  print, result[i].id, $
         result[i].time_obs, $
         observers.observer, $
         location.location, $
         result[i].filename, $
         format='(%"%4d  %-20s  %-12s  %-12s  %s")'
endfor



end
