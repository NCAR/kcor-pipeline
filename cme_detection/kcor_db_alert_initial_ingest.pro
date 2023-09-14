; docformat = 'rst'

pro kcor_db_alert_initial_ingest, alert_json
  compile_opt strictarr
  @kcor_cme_detection

  alert = json_parse(alert_json, /toarray, /tostructure)

  obsday_index = mlso_obsday_insert(datedir, $
                                    run=run, $
                                    database=db, $
                                    status=db_status, $
                                    log_name='kcor/cme')

  kcor_sw_insert, datedir, run=run, $
                  database=db, $
                  sw_index=sw_index, $
                  log_name='kcor/cme'

  ; create kcor_cme entry to get CME ID
  db->execute, 'insert into kcor_cme (obs_day)', obsday_index, $
               sql_statement=sql_query, $
               error_message=error_message
               status=status
  if (status ne 0L) then begin
    mg_log, 'insert into kcor_cme failed with status %d', status, $
            name='kcor/cme', /error
    mg_log, error_message, name='kcor/cme', /error
    goto, done
  endif

  ; get current CMD ID (common block variable)
  current_cme_id = db->query('select last_insert_id()')

  ; create kcor_cme_alert entry
  fields = [{name: 'obs_day', type: '%d'}, $
            {name: 'cme_id', type: '%d'}, $
            {name: 'alert_type', type: '''%s'''}, $
            {name: 'event_type', type: '''%s'''}, $
            {name: 'cme_type', type: '''%s'''}, $
            {name: 'retracted', type: '%d'}, $
            {name: 'issue_time', type: '''%s'''}, $
            {name: 'last_data_time', type: '''%s'''}, $
            {name: 'start_time', type: '''%s'''}, $
            {name: 'in_progress', type: '%d'}, $
            {name: 'position_angle', type: '%s'}, $
            {name: 'speed', type: '%s'}, $
            {name: 'height', type: '%s'}, $
            {name: 'time_for_height', type: '%s'}, $
            {name: 'kcor_sw_id', type: '%d'}]
  sql_cmd = string(strjoin(fields.name, ', '), $
                   strjoin(fields.type, ', '), $
                   format='(%"insert into kcor_cme_alert (%s) values (%s)")')
  db->execute, sql_cmd, $
               obsday_index, $
               current_cme_id, $
               'initial', $
               '', $
               'cme', $
               0B, $
               alert.sep_forecast_submission.issue_time, $
               alert.sep_forecast_submission.inputs.coronagraph.products.last_data_time, $
               alert.sep_forecast_submission.triggers.cme.start_time, $
               1B, $
               kcor_fitsfloat2db(alert.sep_forecast_submission.triggers.cme.pa), $
               kcor_fitsfloat2db(alert.sep_forecast_submission.triggers.cme.speed), $
               kcor_fitsfloat2db(alert.sep_forecast_submission.triggers.cme.time_at_height.height), $
               alert.sep_forecast_submission.triggers.cme.time_at_height.time, $
               sw_index, $
               status=status, $
               error_message=error_message, $
               sql_statement=sql_cmd

  if (status ne 0L) then begin
    mg_log, 'insert initial alert failed with status %d', status, $
            name='kcor/cme', /error
    mg_log, error_message, name='kcor/cme', /error
    goto, done
  endif

  done:
  obj_destroy, db
end
