; docformat = 'rst'

;+
; Return the text of the JSON summary alert.
;
; :Returns:
;   string
;
; :Params:
;-
function kcor_cme_alert_summary, issue_time, $
                                 last_data_time, $
                                 start_time, $
                                 end_time, $
                                 mode, $
                                 position_angle=position_angle, $
                                 speed=speed, $
                                 height=height, $
                                 time_for_height=time_for_height, $
                                 interim=interim
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

  observations = list({all_clear: {all_clear_boolean: keyword_set(interim) ? boolean(0B) : boolean(1B), $
                                   all_clear_type: 'cme'}, $
                       alert: {alert_type: keyword_set(interim) ? 'INTERIM' : 'SUMMARY', $
                               start_time: start_time, $
                               end_time: time_for_height}})

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

issue_time = '2021-06-28T13:47:00Z'
last_data_time = '2021-06-28T13:46Z'
start_time = '2021-06-28T19:28:12Z'
end_time = '2021-06-28T20:30:15Z'

summary_json = kcor_cme_alert_summary(issue_time, $
                                      last_data_time, $
                                      start_time, $
                                      end_time, $
                                      'realtime', $
                                      position_angle=315, $
                                      speed=320.24, $
                                      height=1.26, $
                                      time_for_height='2021-06-28T19:28:12Z')
end
