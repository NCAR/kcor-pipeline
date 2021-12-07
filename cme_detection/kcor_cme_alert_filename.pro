; docformat = 'rst'

;+
; Create the filename of an alert file from the event and issue date/times. For
; example::
;
;   /usr/tmp/mlso_kcor.2021-12-07T132806Z.2021-12-07T120308Z.json
;
; :Params:
;   event_dt : in, required, type=string
;     UT date/time of the time of the first images of the event in the form
;     "YYYY-MM-DDTHH:MM:SSZ"
;   issue_dt : in, required, type=string
;     UT date/time of the time the alert is issued in the form
;     "YYYY-MM-DDTHH:MM:SSZ"
;-
function kcor_cme_alert_filename, event_dt, issue_dt
  compile_opt strictarr

  event_date = strmid(event_dt, 0, 10)
  event_time = strjoin(strmid(event_dt, [11, 14, 17], 2))
  issue_date = strmid(issue_dt, 0, 10)
  issue_time = strjoin(strmid(issue_dt, [11, 14, 17], 2))

  basename = string(event_date, event_time, issue_date, issue_time, $
                    format='(%"mlso_kcor.%sT%sZ.%sT%sZ.json")')

  return, filepath(basename, /tmp)
end

