; docformat = 'rst'

;+
; Send an email report and JSON alert about a completed CME.
;
; :Params:
;   time : in, required, type=double
;     Atomic International Time (TAI), seconds from midnight 1 January 1958
;
; :Keywords:
;   widget : in, optional, type=boolean
;     set to run in the widget GUI
;-
pro kcor_cme_det_report, time, widget=widget, interim=interim
  compile_opt strictarr
  @kcor_cme_det_common

  if (n_elements(speed_history) eq 0L) then goto, done

  addresses = run->config('cme/email')
  if (n_elements(addresses) eq 0L) then begin
    mg_log, 'no cme/email specified, not sending email', $
            name='kcor/cme', /warn
    return
  endif

  last_interim_report = utc2tai(kcor_cme_current_time(run=run))

  mg_log, 'CME alert email address set, will send report', name='kcor/cme', /debug

  last_time_index = n_elements(leading_edge) - 1L

  plot_dir = filepath('p', $
                      subdir=simple_date, $
                      root=run->config('processing/raw_basedir'))
  if (~file_test(plot_dir, /directory)) then file_mkdir, plot_dir

  ; create filename for plot file
  last_datetime = kcor_parse_dateobs(date_diff[last_time_index].date_avg)
  plot_file = filepath(string(last_datetime.year, $
                              last_datetime.month, $
                              last_datetime.day, $
                              last_datetime.hour, $
                              last_datetime.minute, $
                              last_datetime.second, $
                              format='(%"%04d%02d%02d.%02d%02d%02d.cme.plot.png")'), $
                       root=plot_dir)

  ; create plot to attach to email
  original_device = !d.name
  set_plot, 'Z'
  loadct, 0

  n_plots = 3
  device, decomposed=1, set_pixel_depth=24, set_resolution=[800, n_plots * 360]

  !p.multi = [0, 1, n_plots]

  ; speed plot
  velocity = reform(speed_history)
  ind = where(speed_history lt 0.0, n_nan)
  if (n_nan gt 0L) then velocity[ind] = !values.f_nan

  utplot, date_diff.date_avg, velocity, $
          color='000000'x, background='ffffff'x, charsize=1.5, $
          psym=1, symsize=0.5, $
          ytitle='velocity (km/s)', $
          title='Speed', $
          yrange=[0.0, max(velocity, /nan)]

  ; angle plot
  position = reform(angle_history)
  ind = where(angle_history lt 0.0, n_nan)
  if (n_nan gt 0L) then position[ind] = !values.f_nan

  utplot, date_diff.date_avg, position, $
          color='000000'x, background='ffffff'x, charsize=1.5, $
          psym=1, symsize=0.5, $
          ytitle='Angle (degrees)', $
          title='Position angle', $
          ystyle=1, yrange=[0.0, 360.0]

  ; leading edge plot
  date0 = date_diff[-1L].date_avg
  rsun = (pb0r(date0))[2]
  radius = 60 * (lat[leadingedge] + 90) / rsun

  ind = where(leadingedge lt 0.0, n_nan)
  if (n_nan gt 0L) then radius[ind] = !values.f_nan

  utplot, date_diff.date_avg, radius, $
          color='000000'x, background='ffffff'x, charsize=1.5, $
          psym=1, symsize=0.5, $
          ytitle='Solar radii', $
          title='Leading edge', $
          yticks=4, yminor=5, yrange=[1.0, 3.0]

  im = tvrd(true=1)
  set_plot, original_device
  write_png, plot_file, im

  mg_log, 'write CME %s report image file', $
          keyword_set(interim) ? 'interim' : 'summary', $
          name='kcor/cme', /debug

  !p.multi = 0

  ; create file of data values from plot
  plotvalues_file = filepath(string(last_datetime.year, $
                                    last_datetime.month, $
                                    last_datetime.day, $
                                    last_datetime.hour, $
                                    last_datetime.minute, $
                                    last_datetime.second, $, $
                                    format='(%"%04d%02d%02d.%02d%02d%02d.cme.plot.csv")'), $
                             root=plot_dir)
  openw, lun, plotvalues_file, /get_lun
  printf, lun, 'date, speed, position, radius'
  tracked_indices = where(reform(tracked_pt), n_tracked_indices)
  for i = 0L, n_tracked_indices - 1L do begin
    ; only add points which have at least one non-NaN parameter and that are
    ; since the last CME was detected
    good_pt = finite(velocity[tracked_indices[i]]) $
                && finite(position[tracked_indices[i]]) $
                && finite(radius[tracked_indices[i]])
    ; report on data up to 30 minutes before CME started
    current_cme = date_diff[tracked_indices[i]].tai_avg ge (current_cme_tai - 30.0 * 60.0)

    if (current_cme && good_pt) then begin
      printf, lun, $
              tai2utc(date_diff[tracked_indices[i]].tai_avg, /truncate, /ccsds) + 'Z', $
              velocity[tracked_indices[i]], $
              position[tracked_indices[i]], $
              radius[tracked_indices[i]], $
              format='(%"%s, %0.1f, %0.1f, %0.2f")'
    endif
  endfor
  free_lun, lun

  mg_log, 'write CME %s report CSV file', $
          keyword_set(interim) ? 'interim' : 'summary', $
          name='kcor/cme', /debug

  ; create a temporary file for the message
  mailfile = mk_temp_file(dir=get_temp_dir(), 'cme_mail.txt', /random)

  ; Write out the message to the temporary file. Different messages are sent
  ; depending on whether the alert was automatic or generated by the operator.
  openw, out, mailfile, /get_lun

  printf, out, 'The Mauna Loa K-coronagraph has detected a possible CME ending at ' + $
          time + ' UT with the below parameters.'
  printf, out

  spawn, 'echo $(whoami)@$(hostname)', who, error_result, exit_status=status
  if (status eq 0L) then begin
    who = who[0]
  endif else begin
    who = 'unknown'
  endelse

  printf, out
  printf, out, mg_src_root(/filename), who, format='(%"Sent from %s (%s)")'
  version = kcor_find_code_version(revision=revision, branch=branch)
  printf, out, version, revision, branch, format='(%"kcor-pipeline %s (%s) [%s]")'
  printf, out

  free_lun, out

  hour  = long(strmid(time, 0, 2))

  year  = long(strmid(simple_date, 0, 4))
  month = long(strmid(simple_date, 4, 2))
  day   = long(strmid(simple_date, 6, 2))

  if (hour lt 10) then begin
    jd = julday(month, day, year) + 1.0d
    caldat, jd, month, day, year
  endif

  ut_date = string(year, month, day, format='(%"%04d-%02d-%02d")')

  ; form a subject line for the email
  subject = string(keyword_set(interim) ? 'interim' : 'summary', $
                   ut_date, $
                   keyword_set(interim) ? 'at' : 'ending at', $
                   time, $
                   format='(%"MLSO K-Cor %s report for CME on %s %s %s UT")')

  from_email = n_elements(run->config('cme/from_email')) eq 0L $
                 ? '$(whoami)@ucar.edu' $
                 : run->config('cme/from_email')
  cmd = string(subject, $
               from_email, $
               plot_file, $
               plotvalues_file, $
               addresses, $
               mailfile, $
               format='(%"mail -s \"%s\" -r %s -a %s -a %s %s < %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status eq 0L) then begin
    mg_log, '%s report sent to %s', $
            keyword_set(interim) ? 'interim' : 'summary', $
            addresses, name='kcor/cme', /info
  endif else begin
    mg_log, 'problem with mail command: %s', cmd, name='kcor/cme', /error
    mg_log, strjoin(error_result, ' '), name='kcor/cme', /error
  endelse

  ; delete the temporary files
  file_delete, mailfile

  ; send JSON alert
  alerts_basedir = run->config('cme/alerts_basedir')
  if (n_elements(alerts_basedir) gt 0L) then begin
    alerts_dir = filepath('', $
                          subdir=kcor_decompose_date(simple_date), $
                          root=alerts_basedir)
    if (~file_test(alerts_dir, /directory)) then file_mkdir, alerts_dir
  endif
  ftp_url = run->config('cme/ftp_alerts_url')

  if (n_elements(alerts_dir) eq 0L && n_elements(ftp_url) eq 0L) then goto, done

  ; collect info for alert
  itime          = n_elements(leadingedge) - 1
  issue_time     = kcor_cme_current_time(run=run)
  end_time     = tai2utc(utc2tai(date_diff[itime].date_obs), /truncate, /ccsds) + 'Z'
  mode           = run->config('cme/mode')
  ; angle and speed are already set
  height          = 60 * (lat[leadingedge[itime]] + 90) / rsun
  time_for_height = tai2utc(tairef, /truncate, /ccsds) + 'Z'

  summary_json = kcor_cme_alert_summary(issue_time, $
                                        last_sci_data_time, $
                                        current_cme_start_time, $
                                        end_time, $
                                        mode, $
                                        position_angle=angle, $
                                        speed=speed, $
                                        height=height, $
                                        time_for_height=time_for_height, $
                                        interim=interim)

  json_filename = kcor_cme_alert_filename(time_for_height, issue_time)
  kcor_cme_alert_text2file, summary_json, json_filename
  kcor_db_alert_summary_ingest, summary_json, interim=interim

  if (n_elements(ftp_url) gt 0L) then begin
    ftp_from_email = run->config('cme/from_email')
    if (n_elements(ftp_from_email) eq 0L) then ftp_from_email = ''

    kcor_cme_ftp_transfer, ftp_url, json_filename, ftp_from_email, $
                           status=ftp_status, $
                           error_msg=ftp_error_msg, $
                           cmd=ftp_cmd
    if (ftp_status ne 0L) then begin
      mg_log, 'FTP transferred with error %d', ftp_status, name='kcor/cme', /error
      mg_log, 'FTP command: %s', ftp_cmd, name='kcor/cme', /error
      for e = 0L, n_elements(ftp_error_msg) - 1L do begin
        mg_log, ftp_error_msg[e], name='kcor/cme', /error
      endfor
    endif else begin
      mg_log, '%s alert successfully sent', $
              keyword_set(interim) ? 'interim' : 'summary', $
              name='kcor/cme', /info
    endelse
  endif

  if (n_elements(alerts_dir) gt 0L) then file_copy, json_filename, alerts_dir
  file_delete, json_filename, /allow_nonexistent

  ; TODO: should I also delete angle_history and leadingedge?
  ;delvarx, speed_history

  done:
end
