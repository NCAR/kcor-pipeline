; docformat = 'rst'

;+
; Return the text of the JSON retraction alert.
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
function kcor_cme_alert_retract, issue_time, last_data_time, all_clear, mode, $
                                 retract_time=retract_time, $
                                 retract_position_angle=retract_position_angle, $
                                 comment=comment
  compile_opt strictarr

  model = {short_name: 'MLSO K-Cor', $
           spase_id: 'spase://NSF/Catalog/MLSO/K-Cor/AutomatedEventList'}

  inputs = list({coronagraph:{observatory: 'MLSO', $
                              instrument: 'K-Cor', $
                              products:list({product: 'White Light', $
                                             last_data_time: last_data_time})}})

  if (n_elements(comment) gt 0L && comment ne '') then begin
    _comment = comment
  endif else begin
    _comment = string(retract_position_angle, $
                      format='(%"Canceling alert for CME at position angle %s")')
  endelse

  observations = list({all_clear: {all_clear_boolean: boolean(all_clear), $
                                   all_clear_type: 'cme'}, $
                       alert: {alert_type: 'CANCEL ALERT', $
                               start_time: retract_time, $
                               comment: _comment}})

  submission = {sep_forecast_submission:{model: model, $
                                         issue_time: issue_time, $
                                         mode: mode, $
                                         inputs: inputs, $
                                         observations: observations}}

  json = json_serialize(submission, /lowercase)

  heap_free, inputs
  heap_free, observations

  return, json
end
