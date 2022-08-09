; docformat = 'rst'

;+
; Check for any human observer alerts and send JSON alert for any new alerts.
;-
pro kcor_cme_handle_human
  compile_opt strictarr
  @kcor_cme_det_common

  list_dir = run->config('cme/list_dir')
  cmes_to_send = kcor_cme_find_human(simple_date, list_dir, $
                                     count=n_cmes_to_send)

  if (n_cmes_to_send gt 0L) then begin
    mg_log, 'sending %d observer alerts for CMEs...', n_cmes_to_send, name='kcor/cme', /warn
    for c = 0L, n_cmes_to_send - 1L do begin
      kcor_cme_parse_human, cmes_to_send[c], $
                            time=time, $
                            position_angle=position_angle, $
                            width=width, $
                            comment=comment
      mg_log, 'send CME at %s at position angle %s', $
              time, position_angle, $
              name='kcor/cme', /warn
      kcor_cme_human, simple_date, time, position_angle, width, list_dir, comment=comment
    endfor
  endif
end
