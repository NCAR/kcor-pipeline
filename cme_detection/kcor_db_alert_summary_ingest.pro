; docformat = 'rst'

pro kcor_db_alert_summary_ingest, summary_json
  compile_opt strictarr

  summary = json_parse(summary_json, /toarray, /tostructure)

  obsday_index = mlso_obsday_insert(datedir, $
                                    run=run, $
                                    database=db, $
                                    status=db_status, $
                                    log_name='kcor/cme')

  kcor_sw_insert, datedir, run=run, $
                  database=db, $
                  sw_index=sw_index, $
                  log_name='kcor/cme'

  ; calculate time_history
  time_history = reform(kcor_dateobs2julian(date_diff.date_avg))

  ; calculate pa_history
  pa_history = reform(angle_history)
  nan_indices = where(leadingedge lt 0.0, /null)
  pa_history[nan_indices] = !values.f_nan

  ; calculate velocity_history
  velocity_history = reform(speed_history)
  nan_indices = where(leadingedge lt 0.0, /null)
  velocity_history[nan_indices] = !values.f_nan

  ; calculate height_history
  date0 = date_diff[-1L].date_avg
  rsun = (pb0r(date0))[2]
  height_history = 60.0 * (lat[leadingedge] + 90.0) / rsun
  nan_indices = where(leadingedge lt 0.0, /null)
  height_history[nan_indices] = !values.f_nan

  ; report on points that were "tracked" and valid values for velocity, angle,
  ; and height and up to 30 minutes before CME started
  prelude = 30 * 60.0
  good_indices = where(reform(tracked_pt) $
                         and finite(pa_history) $
                         and finite(velocity_history) $
                         and finite(height_history) $
                         and (date_diff.tai_avg ge (current_cme_tai - prelude)), /null)

  time_history     = time_history[good_indices]
  pa_history       = pa_history[good_indices]
  velocity_history = velocity_history[good_indices]
  height_history   = height_history[good_indices]

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

            ; blobs
            {name: 'time_history', type: '%s'}, $
            {name: 'pa_history', type: '%s'}, $
            {name: 'speed_history', type: '%s'}, $
            {name: 'height_history', type: '%s'}, $

            {name: 'kcor_sw_id', type: '%d'}]
  sql_cmd = string(strjoin(fields.name, ', '), $
                   strjoin(fields.type, ', '), $
                   format='(%"insert into kcor_cme_alert (%s) values (%s)")')
  db->execute, sql_cmd, $
               obsday_index, $
               current_cme_id, $
               'summary', $
               '', $
               'cme', $
               0B, $   ; TODO: check this?
               summary.sep_forecast_submission.issue_time, $
               summary.sep_forecast_submission.inputs.coronagraph.products.last_data_time, $
               summary.sep_forecast_submission.triggers.cme.start_time, $
               cme_occurring, $
               kcor_fitsfloat2db(summary.sep_forecast_submission.triggers.cme.pa), $
               kcor_fitsfloat2db(summary.sep_forecast_submission.triggers.cme.speed), $
               kcor_fitsfloat2db(summary.sep_forecast_submission.triggers.cme.time_at_height.height), $
               summary.sep_forecast_submission.triggers.cme.time_at_height.time, $

               db->escape_string(time_history), $
               db->escape_string(pa_history), $
               db->escape_string(velocity_history), $
               db->escape_string(height_history), $

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
