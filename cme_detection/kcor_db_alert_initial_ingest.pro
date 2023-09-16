; docformat = 'rst'

pro kcor_db_alert_initial_ingest, alert_json
  compile_opt strictarr
  @kcor_cme_det_common

  alert = json_parse(alert_json, /toarray, /tostruct)

  obsday_index = mlso_obsday_insert(simple_date, $
                                    run=run, $
                                    database=db, $
                                    status=obsday_insert_status, $
                                    log_name='kcor/cme')

  kcor_sw_insert, simple_date, run=run, $
                  database=db, $
                  sw_index=sw_index, $
                  log_name='kcor/cme'

  ; create kcor_cme entry to get CME ID
  db->execute, 'insert into kcor_cme (obs_day) values (%d)', obsday_index, $
               sql_statement=sql_query, $
               error_message=error_message, $
               status=status
  if (status ne 0L) then goto, done

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
            {name: 'time_for_height', type: '''%s'''}, $
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
               strmid(alert.sep_forecast_submission.issue_time, 0, 19), $
               strmid(alert.sep_forecast_submission.inputs.coronagraph.products.last_data_time, 0, 19), $
               strmid(alert.sep_forecast_submission.triggers.cme.start_time, 0, 19), $
               1B, $
               kcor_fitsfloat2db(alert.sep_forecast_submission.triggers.cme.pa), $
               kcor_fitsfloat2db(alert.sep_forecast_submission.triggers.cme.speed), $
               kcor_fitsfloat2db(alert.sep_forecast_submission.triggers.cme.time_at_height.height), $
               strmid(alert.sep_forecast_submission.triggers.cme.time_at_height.time, 0, 19), $
               sw_index, $
               status=status, $
               error_message=error_message, $
               sql_statement=sql_cmd

  if (status ne 0L) then goto, done

  done:
  obj_destroy, db
end
