;+
; Delete entries for a day, e.g., before reprocessing that day.
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   obsday_index : in, required, type=integer
;     index into mlso_numfiles database table
;   database : in, optional, type=KCordbMySql object
;     database connection to use
;   log_name : in, required, type=string
;     name of log to send log messages to
;-
pro kcor_nrgf_clear, run=run, $
                     database=db, $
                     obsday_index=obsday_index, $
                     log_name=log_name
  compile_opt strictarr

  query = 'select * from mlso_producttype where producttype=''nrgf'''
  producttype_results = db->query(query, fields=fields, $
                                  status=status)
  if (status ne 0L) then goto, done

  producttype_id = producttype_results.producttype_id

  mg_log, 'clearing NRGF from kcor_img table', name=log_name, /info
  db->execute, 'delete from kcor_img where producttype=%d and obs_day=%d', $
               producttype_id, obsday_index, $
               status=status, $
               n_affected_rows=n_affected_rows, $
               n_warnings=n_warnings
  if (status ne 0L) then goto, done

  mg_log, '%d rows deleted', n_affected_rows, name=log_name, /info

  fields = 'num_kcor_nrgf_' + ['fits', 'lowresgif', 'fullresgif'] + '=0'
  fields_expr = strjoin(fields, ', ')
  db->execute, 'update mlso_numfiles set %s where day_id=%d', $
               fields_expr, obsday_index, $
               status=status
  if (status ne 0L) then goto, done

  done:
end
