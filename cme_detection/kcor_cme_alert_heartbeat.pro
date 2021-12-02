; docformat = 'rst'

;+
; Return the text of the JSON heartbeat alert.
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
function kcor_cme_alert_heartbeat, issue_time, last_data_time, all_clear
  compile_opt strictarr

  model = {short_name: 'MLSO K-Cor', $
           spase_id: 'spase://CCMC/SimulationModel/MLSO/K-Cor/AutomatedCMEDetection'}

  ;date_format = '(C(CYI4.4, "-", CMOI2.2, "-", CDI2.2, "T", CHI2.2, ":", CMI2.2, ":", CSI2.2, "Z"))'
  ;issue_time = string(julday(), format=date_format)

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

print, kcor_cme_alert_heartbeat('2021-06-28T13:47:00Z', '2021-06-28T13:46Z', !true)

end
