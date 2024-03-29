; docformat = 'rst'

;+
; Main CME detection processing loop.
;
; :Keywords:
;   stopped : out, optional, type=boolean
;     set to a named variable to retrieve whether to stop processing
;   widget : in, optional, type=boolean
;     set to run in the widget GUI
;-
pro kcor_cme_det_check, stopped=stopped, widget=widget, realtime=realtime
  compile_opt strictarr
  @kcor_cme_det_common

  updated = 0B
  stopped = 0B

  if (~cstop) then begin
    files = file_search(concat_dir(datedir, '*kcor_l2.fts'), count=count)
    if (count eq 0) then begin
      files = file_search(concat_dir(datedir,'*kcor_l2.fts.gz'), count=count)
      if (~keyword_set(realtime) && (count eq 0)) then begin
        mg_log, 'no FITS files found in archive dir', name='kcor/cme', /info
        goto, stop_point
      endif
    endif

    ; wait for the last file to finish writing -- the last file found in the
    ; FILE_SEARCH might still be being written, so wait a few seconds to make
    ; sure it finishes
    wait, 5.0

    ; optionally limit the time range for testing purposes
    if (n_elements(timerange) eq 2) then begin
      t0 = anytim2utc(timerange[0], /ccsds)
      t1 = anytim2utc(timerange[1], /ccsds)
      break_file, files, disk, dir, name
      tt = anytim2utc(strmid(name, 0, 15), /ccsds)
      w = where((tt ge t0) and (tt le t1), count)
      if (count eq 0) then begin
        mg_log, 'no FITS files found in time range', name='kcor/cme', /info
        goto, stop_point
      endif
      files = files[w]
    endif

    ; If the next file doesn't exist, then check the age of the last file.
    ; If at least 20 minutes old, then stop. Otherwise, wait 5 seconds.
    if (ifile ge count) then begin
      mtime = (file_info(files)).mtime
      age = systime(1) - max(mtime)
      ; TODO: is this check even needed any more? why stop if there hasn't been
      ; a file in the last 20 minutes?
      if (~keyword_set(realtime) && (age ge 1200)) then begin   ; 20 min
        mg_log, 'no more files in last %0.1f minutes', age / 60.0, name='kcor/cme', /info
        goto, stop_point
      endif
      if (keyword_set(widget)) then begin
        widget_control, wtopbase, timer=5
      endif
    endif else begin
      ; Otherwise, read in the file. Keep track of the begin and end times.
      break_file, files[ifile], disk, dir, name, ext
      if (keyword_set(widget)) then begin
        widget_control, wfile, set_value=name + ext
      endif
      mg_log, 'reading %s', file_basename(files[ifile]), $
              name='kcor/cme', /info
      image = readfits(files[ifile], header, /silent)
      datatype = fxpar(header, 'datatype', count=ndatatype)
      last_data_time = fxpar(header, 'DATE-OBS') + 'Z'
      if (ndatatype eq 0) then test = 1 else begin
        datatype = strtrim(fxpar(header, 'datatype'), 2)
        test = datatype eq 'science' or datatype eq 'engineering'
      endelse

      if (test) then begin
        last_sci_data_time = last_data_time
        parameters = kcor_cme_det_parameters_init()

        date_obs = anytim2utc(fxpar(header, 'date-obs'), /ccsds)
        date_end = anytim2utc(fxpar(header, 'date-end'), /ccsds)
        tai_obs = utc2tai(date_obs)
        tai_end = utc2tai(date_end)
        temp = {date_obs: date_obs, tai_obs: tai_obs, $
                date_end: date_end, tai_end: tai_end, $
                filename: files[ifile]}
        if (n_elements(date_orig) eq 0) then begin
          date_orig = temp
        endif else begin
          date_orig = [date_orig, temp]
        endelse

        ; remap the image into helioprojective radial coordinates
        break_file, files[ifile], disk, dir, name, ext
        name = name + '_hpr'
        hpr_out_file = concat_dir(hpr_out_dir, name + '.fts')
        kcor_cme_det_remap, header, image, hpr_out_file, hmap, map
        boost_array, maps, map

        ; form the running difference maps
        name = name + '_rd'
        diff_out_file = concat_dir(diff_out_dir, name + '.fts')
        kcor_cme_det_rdiff, hmap, double(maps), date_orig, diff_out_file, $
                            hdiff, mdiff, store=store

        ; keep track of the begin, end, and average times of the running
        ; difference maps
        if (n_elements(mdiff) gt 1) then begin
          if (keyword_set(widget)) then begin
            wset, mapwin
            exptv, sigrange(mdiff), /nosquare, /nobox
            widget_control, wdate, set_value=fxpar(hdiff, 'date-avg')
          endif

          date_obs = fxpar(hdiff, 'date-obs')
          date_end = fxpar(hdiff, 'date-end')
          date_avg = fxpar(hdiff, 'date-avg')
          tai_obs = utc2tai(date_obs)
          tai_end = utc2tai(date_end)
          tai_avg = utc2tai(date_avg)
          temp = {date_obs: date_obs, tai_obs: tai_obs, $
                  date_end: date_end, tai_end: tai_end, $
                  date_avg: date_avg, tai_avg: tai_avg}
          parameters.tai = tai_avg

          if (n_elements(date_diff) eq 0) then begin
            date_diff = temp
          endif else begin
            date_diff = [date_diff, temp]
          endelse

          boost_array, tracked_pt, 0B
          boost_array, speed_history, -1.0
          boost_array, angle_history, -1.0
          boost_array, mdiffs, mdiff

          ; determine candidate limits for any CME in the difference image
          kcor_cme_det_thresh, mdiff, itheta0
          if (itheta0[0] ge 0 && keyword_set(widget)) then begin
            wset, mapwin
            tvplt, replicate(itheta0[0],     2), [0, nrad]
            tvplt, replicate(itheta0[1] + 1, 2), [0, nrad]
            empty
          endif
          boost_array, itheta, itheta0
          if (array_equal(itheta0, fltarr(2) - 1.0)) then begin
            parameters.angle_range = fltarr(2) + !values.f_nan
          endif else begin
            parameters.angle_range = itheta0
          endelse

          ; look for CME detections based on the data that's been collected
          ; so far
          boost_array, detected, 0
          kcor_cme_det_find, tai_avg, date_diff, itheta0, itheta, $
                             nlon, detected
          parameters.detected = detected[-1]

          ; if any detections were made, then look for the leading edge
          idet = n_elements(detected) - 1
          nlead = n_elements(leadingedge)
          if (detected[idet]) then begin
            kcor_cme_det_track, mdiffs, itheta, detected, leadingedge
            parameters.leading_edge = leadingedge[-1]
          endif

          ; if the LEADINGEDGE array grew in size, then update the plots
          if (n_elements(leadingedge) gt nlead) then begin
            tracked_pt[-1] = 1B

            ilead = n_elements(leadingedge) - 1
            lead0 = leadingedge[ilead]
            date0 = date_diff[ilead].date_avg
            if (lead0 ge 0) then begin
              if (keyword_set(widget)) then begin
                wset, mapwin
                tvplt, [0, nlon], replicate(lead0, 2)
              endif
              w = where(leadingedge ge 0, count)
              if (count gt 1) then begin
                rsun = (pb0r(date0))[2]
                rad = 60 * (lat[leadingedge[w]] + 90) / rsun

                if (keyword_set(widget)) then begin
                  wset, plotwin
                  utplot, date_diff[w].date_avg, rad, $
                          psym=2, xstyle=3, /ynozero, $
                          ytitle='Solar radii'
                endif

                ; attempt to measure the CME parameters
                kcor_cme_det_measure, rsun, updated=updated, alert=alert, ysig=ysig, $
                                      parameters=parameters
                if (keyword_set(updated)) then begin
                  angle_history[-1] = angle
                  speed_history[-1] = speed
                endif
;                if (alert) then begin
;                  kcor_cme_det_threshplot, mdiff, itheta0
;                endif

                if (n_elements(param) gt 0) then begin
                  if (keyword_set(widget)) then begin
                    widget_control, wangle, set_value=string(angle, format='(%"%d")')
                    widget_control, wspeed, set_value=string(speed, format='(%"%0.2f")')
                  endif else begin
                    mg_log, '%d degrees at %0.1f km/s', angle, speed, $
                            name='kcor/cme', /info
                  endelse
                  x = date_diff.tai_avg - tairef
                  rfit = poly(x, param)
                  if (keyword_set(widget)) then begin
                    wset, plotwin
                    outplot, date_diff.date_avg, rfit
                  endif else begin
                    if (0) then begin
                      mg_psbegin, filename='20170327.alertfit.ps', $
                                  xsize=6, ysize=3, /inches, bits_per_pixel=8, /color

                      device, get_decomposed=odec
                      device, decomposed=1

                      utplot, date_diff[w].date_avg, rad, $
                              psym=mg_usersym(/circle, /fill), symsize=0.5, $
                              xstyle=3, /ynozero, $
                              ytitle='Solar radii', $
                              title='Fit of leading edge', $
                              color='000000'x, background='ffffff'x, font=1
                      outplot, date_diff.date_avg, rfit, $
                               color='a0a0a0'x, $
                               linestyle=2, thick=2.0

                      xyouts, 0.75, 0.45, string(ysig, sunsymbol(font=1), $
                                                 format='(%"Std dev: %0.3f R%s")'), $
                              font=1, /normal
                      xyouts, 0.75, 0.4, string(speed, format='(%"Speed: %0.2f km/s")'), $
                              font=1, /normal

                      device, decomposed=odec
                      mg_psend
                      stop
                    endif
                  endelse
                endif
              endif
            endif    ; valid LEAD0 
          endif      ; LEADINGEDGE grew

          parameters.cme_occurring = cme_occurring

          ; log CME parameters
          if (finite(parameters.tai) gt 0L and total(finite(parameters.angle_range)) gt 0L) then begin
            t = tai2utc(parameters.tai, /time, /truncate, /ccsds)
            parameters.time = string(strmid(t, [0, 3, 6], 2), format='%s%s%s')
            openu, lun, cme_detection_params_filename, /get_lun, /append
            printf, lun, parameters, $
                    format='%0.1f   %6s   %5.1f  %5.1f  %1d  %5.0f  %3d  %3d  %8.1f  %7.2f  %7.2f  %7.3f  %d'
            free_lun, lun
          endif
        endif        ; MDIFF formed
      endif          ; science image

      if (n_elements(date_diff) gt 0L) then begin
        itime = n_elements(leadingedge) - 1
        tai0 = date_diff[itime].tai_avg

        mg_log, 'CME occurring: %s', cme_occurring ? 'YES' : 'NO', name='kcor/cme', /info

        if (cme_occurring) then begin
          mg_log, 'tai0 - tairef: %0.1f', tai0 - tairef, name='kcor/cme', /debug
          mg_log, 'tai0 - current_cme_tai: %0.1f', tai0 - current_cme_tai, name='kcor/cme', /debug
          mg_log, 'tairef: %s', tai2utc(tairef, /time, /truncate, /ccsds), name='kcor/cme', /debug
          mg_log, 'tai0: %s', tai2utc(tai0, /time, /truncate, /ccsds), name='kcor/cme', /debug
          mg_log, 'current CME: %s', tai2utc(current_cme_tai, /time, /truncate, /ccsds), name='kcor/cme', /debug

          summary_report_interval = run->config('cme/summary_report_interval')
          send_summary_report = (tai0 - current_cme_tai) gt summary_report_interval

          if (send_summary_report) then begin
            ref_time = tai2utc(tairef, /time, /truncate, /ccsds)
            mg_log, 'ready to send report', name='kcor/cme', /debug
            kcor_cme_det_report, ref_time
            cme_occurring = 0B
            mg_log, 'CME ended', name='kcor/cme', /info
          endif
        endif
      endif

      ; step to the next file
      ifile = ifile + 1
      if (keyword_set(widget)) then begin
        widget_control, wtopbase, timer=0.1
      endif
    endelse
  endif                         ; Not stopped

  return

  stop_point:
  stopped = 1B
end
