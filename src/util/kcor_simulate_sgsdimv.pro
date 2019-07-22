; docformat = 'rst'

;+
; Simulate an SGS DIMV value using a model. 
;
; :Returns:
;   float
;
; :Params:
;   date_obs : in, required, type=string
;     date/time to simulate SGS DIMV for in the form "2013-11-23T20:10:07"
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
function kcor_simulate_sgsdimv, date_obs, run=run
  compile_opt strictarr
  on_error, 2

  if (run->epoch('use_sgs')) then begin
    message, string(date_obs, format='(%"this model not valid for %s")')
  endif

  date = kcor_parse_dateobs(date_obs, hst_date=hst_date)
  t = hst_date.ehour + 10.0

  coeffs = run->epoch('sgsdimv_model_coeffs')
  powers = t ^ lindgen(n_elements(coeffs))

  dimv = total(coeffs * powers, /preserve_type)

  return, dimv
end


; main-level example program

date_obs = '2013-10-01T23:30:00'
;date_obs = '2013-10-05T23:30:00'
ut_date = kcor_parse_dateobs(date_obs, hst_date=hst_date)

date = string(hst_date.year, hst_date.month, hst_date.day, $
              format='(%"%04d%02d%02d")')

config_filename = filepath('kcor.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
sgsdimv = kcor_simulate_sgsdimv(date_obs, run=run)
print, date_obs, sgsdimv, format='(%"%s: %0.2f")'
obj_destroy, run

end
