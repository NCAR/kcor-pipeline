; docformat = 'rst'

;+
; Return the text of the JSON heartbeat alert.
;
; :Returns:
;   string
;
; :Params:
;   issue_time : in, required, type=string
;     UT date/time of the time the alert is issued
;   last_data_time : in, required, type=string
;     UT date/time of the last data acquired in the form "YYYY-MM-DDTHH:MM:SSZ"
;   all_clear : in, require, type=integer/boolean
;     whether we are clear of CMEs
;-
function kcor_cme_alert_heartbeat, issue_time, last_data_time, all_clear
  compile_opt strictarr

  model = {short_name: 'MLSO K-Cor', $
           spase_id: 'spase://CCMC/SimulationModel/MLSO/K-Cor/AutomatedCMEDetection'}

  inputs = [{coronagraph:{observatory: 'MLSO', instrument: 'K-Cor'}, $
             products:[{product: 'White Light', last_data_time: last_data_time}]}]

  observations = [{all_clear: {all_clear_boolean: boolean(all_clear), $
                               all_clear_type: 'cme'}}]

  submission = {sep_forecast_submission:{model: model, $
                                         issue_time: issue_time, $
                                         mode: 'nowcast', $
                                         inputs: inputs, $
                                         observations: observations}}

  json = json_serialize(submission, /lowercase)

  return, json
end


; main-level example program

event_time     = '2021-06-28T13:45:00Z'
issue_time     = '2021-06-28T13:47:00Z'
last_data_time = '2021-06-28T13:46:15Z'

heartbeat_string = kcor_cme_alert_heartbeat(issue_time, last_data_time, !true)
filename = kcor_cme_alert_filename(event_time, issue_time)

kcor_cme_alert_text2file, heartbeat_string, filename
print, filename

end
