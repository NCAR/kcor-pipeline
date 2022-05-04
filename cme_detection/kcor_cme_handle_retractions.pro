; docformat = 'rst'

;+
; Check for any retractions and retract any CMEs that have been flagged to be
; retracted.
;-
pro kcor_cme_handle_retractions
  compile_opt strictarr
  @kcor_cme_det_common

  list_dir = run->config('cme/list_dir')
  cmes_to_retract = kcor_cme_find_retractions(simple_date, list_dir, $
                                              count=n_cmes_to_retract)

  if (n_cmes_to_retract gt 0L) then begin
    mg_log, 'retracting %d CMEs...', n_cmes_to_retract, name='kcor/cme', /warn
    for c = 0L, n_cmes_to_retract - 1L do begin
      tokens = strsplit(cms_to_retract, /extract)
      time = tokens[0]
      position_angle = tokens[1]
      mg_log, 'retracting CME at %s at position angle %s', $
              time, position_angle, $
              name='kcor/cme', /warn
      kcor_cme_retract, simple_date, time, position_angle, list_dir
    endfor
  endif
end

