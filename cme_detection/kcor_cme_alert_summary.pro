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
                                 time_for_height=time_for_height
  compile_opt strictarr

  model = {short_name: 'MLSO K-Cor', $
           spase_id: 'spase://CCMC/SimulationModel/MLSO/K-Cor/AutomatedCMEDetection'}

  triggers = list({cme: {start_time: start_time, $
                         pa: position_angle, $
                         speed: speed, $
                         time_at_height: {height: height, time: time_for_height}, $
                         catalog: 'MLSO_KCOR'}})

  inputs = list({coronagraph:{observatory: 'MLSO', $
                              instrument: 'K-Cor', $
                              products:list({product: 'White Light', $
                                             last_data_time: last_data_time})}})

  observations = list({all_clear: {all_clear_boolean: boolean(1B), $
                                   all_clear_type: 'cme'}, $
                       alert: {alert_type: 'SUMMARY', $
                               start_time: start_time, $
                               end_time: end_time}})

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

