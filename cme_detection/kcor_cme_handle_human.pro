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
      if (strpos(time, ':') eq -1L) then begin
        start_time = string(strmid(time, 0, 2), $
                            strmid(time, 2, 2), $
                            strmid(time, 4, 2), $
                            format='(%"%s:%s:%s")')
      endif else begin
        start_time = time
      endelse
      mg_log, 'send CME at %s at position angle %0.1f', $
              start_time, position_angle, $
              name='kcor/cme', /warn
      kcor_cme_human, simple_date, start_time, position_angle, width, list_dir, $
                      comment=comment, line=cmes_to_send[c]
    endfor
  endif
end
