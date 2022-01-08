; docformat = 'rst'

;+
; Return the text of the JSON initial alert.
;
; :Returns:
;   string
;
; :Params:
;   last_data_time : in, required, type=string
;     UT date/time of the last data acquired in the form "YYYY-MM-DDTHH:MM:SSZ"
;   all_clear : in, require, type=integer/boolean
;     whether we are clear of CMEs
;-
function kcor_cme_alert_initial, issue_time, last_data_time, start_time, $
                                 position_angle=position_angle, $
                                 speed=speed, $
                                 height=height, $
                                 time_for_height=time_for_height
  compile_opt strictarr

  model = {short_name: 'MLSO K-Cor', $
           spase_id: 'spase://CCMC/SimulationModel/MLSO/K-Cor/AutomatedCMEDetection'}

  ; TODO: should alert_time be the same as issue_time?
  date_format = '(C(CYI4.4, "-", CMOI2.2, "-", CDI2.2, "T", CHI2.2, ":", CMI2.2, ":", CSI2.2, "Z"))'
  alert_time = string(julday(), format=date_format)

  triggers = [{cme: {start_time: start_time, $
                     pa: position_angle, $
                     speed: speed, $
                     time_at_height: {height: height, time: time_for_height}, $
                     catalog: 'MLSO_KCOR'}}]

  inputs = [{coronagraph:{observatory: 'MLSO', instrument: 'K-Cor'}, $
             products:[{product: 'White Light', last_data_time: last_data_time}]}]

  observations = [{all_clear: {all_clear_boolean: 'false', $
                               all_clear_type: 'cme'}, $
                   alert: {alert_type: 'ALERT', $
                           alert_time: alert_time}}]

  submission = {sep_forecast_submission:{model: model, $
                                         issue_time: issue_time, $
                                         mode: 'nowcast', $
                                         triggers: triggers, $
                                         inputs: inputs, $
                                         observations: observations}}

  json = json_serialize(submission, /lowercase)

  return, json
end


; main-level example program

event_time = '2021-06-28T19:28:12Z'
issue_time = '2021-06-28T13:47:00Z'
json = kcor_cme_alert_initial(issue_time, $
                              '2021-06-28T13:46Z', $
                              event_time, $
                              position_angle=315, $
                              speed=320.24, $
                              height=1.26, $
                              time_for_height='2021-06-28T19:28:12Z')

alert_filename = kcor_cme_alert_filename(event_time, issue_time)
kcor_cme_alert_text2file, json, alert_filename
print, alert_filename

end