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
function kcor_cme_alert_initial, issue_time, last_data_time, start_time, mode, $
                                 position_angle=position_angle, $
                                 speed=speed, $
                                 height=height, $
                                 time_for_height=time_for_height
  compile_opt strictarr

  model = {short_name: 'MLSO K-Cor', $
           spase_id: 'spase://NSF/Catalog/MLSO/K-Cor/AutomatedEventList'}

  triggers = list({cme: {start_time: start_time, $
                         pa: position_angle, $
                         speed: speed, $
                         time_at_height: {height: height, time: time_for_height}, $
                         catalog: 'MLSO_KCOR'}})

  inputs = list({coronagraph:{observatory: 'MLSO', $
                              instrument: 'K-Cor', $
                              products:list({product: 'White Light', $
                                             last_data_time: last_data_time})}})

  observations = list({all_clear: {all_clear_boolean: boolean(0B), $
                                   all_clear_type: 'cme'}, $
                       alert: {alert_type: 'ALERT', $
                               start_time: issue_time}})

  submission = {sep_forecast_submission:{model: model, $
                                         issue_time: issue_time, $
                                         mode: mode, $
                                         triggers: triggers, $
                                         inputs: inputs, $
                                         observations: observations}}

  json = json_serialize(submission, /lowercase)

  heap_free, triggers
  heap_free, inputs
  heap_free, observations

  return, json
end


; main-level example program

event_time = '2021-06-28T19:28:12Z'
issue_time = '2021-06-28T13:47:00Z'
json = kcor_cme_alert_initial(issue_time, $
                              '2021-06-28T13:46Z', $
                              event_time, $
                              'realtime', $
                              position_angle=315, $
                              speed=320.24, $
                              height=1.26, $
                              time_for_height='2021-06-28T19:28:12Z')

alert_filename = kcor_cme_alert_filename(event_time, issue_time)
kcor_cme_alert_text2file, json, alert_filename
print, alert_filename

end
