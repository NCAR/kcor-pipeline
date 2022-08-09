; docformat = 'rst'

;+
; Return the text of the JSON human observer alert.
;
;   issue_time : in, required, type=string
;     UT date/time of the time the alert is issued
;   start_time : in, required, type=string
;     UT date/time of the time the initial alert was issued
;   all_clear : in, require, type=integer/boolean
;     whether we are clear of CMEs
;-
function kcor_cme_alert_human, issue_time, start_time, all_clear, mode, $
                               comment=comment
  compile_opt strictarr

  model = {short_name: 'MLSO K-Cor', $
           spase_id: 'spase://NSF/Catalog/MLSO/K-Cor/AutomatedEventList'}

  inputs = list({coronagraph:{observatory: 'MLSO', $
                              instrument: 'K-Cor', $
                              products:list({product: 'White Light'})}})

  if (n_elements(comment) gt 0L && comment ne '') then begin
    _comment = comment
  endif else begin
    _comment = string(retract_position_angle, $
                      format='(%"Canceling alert for CME at position angle %s")')
  endelse

  observations = list({all_clear: {all_clear_boolean: boolean(all_clear), $
                                   all_clear_type: 'cme'}, $
                       alert: {alert_type: 'OBSERVER ALERT', $
                               start_time: start_time, $
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

; main-level example program

event_time = '2021-06-28T20:03:26'
issue_time = '2021-06-28T19:24:02Z'
json = kcor_cme_alert_human(issue_time, event_time, 0B, 'nowcast', comment='****Possible CME in Progress mcotter**** : Mon Jun 28 20:03:26 GMT 2021 Possible CME seen launching near PA: 310 deg at time 19:24:02 UT.')
print, json

end
