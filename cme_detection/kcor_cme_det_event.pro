;+
; Project     :	MLSO - KCOR
;
; Name        :	KCOR_CME_DET_EVENT
;
; Purpose     :	Event handler for KCOR_CME_DETECTION
;
; Category    :	KCOR, CME, Detection
;
; Explanation :	Event handler for KCOR_CME_DETECTION.  Except for the initial
;               setup, all the work is managed from this routine.  TIMER events
;               are used to control the progression from one image to the next.
;
; Syntax      :	KCOR_CME_DET_EVENT, EVENT
;
; Examples    :	See KCOR_CME_DETECTION
;
; Inputs      :	EVENT   = Event structure
;
; Opt. Inputs :	None
;
; Outputs     :	None
;
; Opt. Outputs:	None
;
; Keywords    :	None
;
; Calls       :	FILE_SEARCH, CONCAT_DIR, ANYTIM2UTC, BREAK_FILE, READFITS,
;               FXPAR, UTC2TAI, KCOR_CME_DET_REMAP, KCOR_CME_DET_RDIFF, EXPTV,
;               BOOST_ARRAY, KCOR_CME_DET_THRESH, TVPLT, KCOR_CME_DET_FIND,
;               KCOR_CME_DET_TRACK, PB0R, UTPLOT, KCOR_CME_DET_MEASURE, OUTPLOT
;
; Common      :	KCOR_CME_DETECTION defined in kcor_cme_detection.pro
;
; Restrictions:	None
;
; Side effects:	None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 04-Jan-2017, William Thompson, GSFC
;               Version 2, 22-Mar-2017, WTT, include FILENAME in DATE_ORIG
;                          Test for existence of data directory.
;                          Add operator-generated alert event.
;
; Contact     :	WTHOMPSON
;-
;
pro kcor_cme_det_event, event
  compile_opt strictarr
  common kcor_cme_detection

  ; if the window close box has been selected, then kill the widget
  if (tag_names(event, /structure_name) eq 'WIDGET_KILL_REQUEST') then begin
    goto, destroy
  endif

  ; get the UVALUE, and act accordingly
  widget_control, event.id, get_uvalue=uvalue
  case uvalue of
    'START': begin
        if file_exist(datedir) then begin
          cstop = 0
          widget_control, wstart, sensitive=0
          widget_control, wstop, sensitive=1
          widget_control, wexit, sensitive=0
          widget_control, wfile, set_value=''
          mg_log, 'started', name='kcor-cme', /info
          widget_control, wtopbase, timer=0.1
        endif else begin
          mg_log, 'directory %s does not exist', datedir, name='kcor-cme', /warn
        endelse
      end

    'STOP': begin
stop_point:
        cstop = 1
        widget_control, wstart, sensitive=1
        widget_control, wstop, sensitive=0
        widget_control, wexit, sensitive=1
        widget_control, wtopbase, timer=0.1
        mg_log, 'stopped', name='kcor-cme', /info
      end

    ; Operator-generated alert.
    'ALERT': begin
        itime = n_elements(leadingedge) - 1
        kcor_cme_det_alert, itime, /operator
      end

    'TIMER': if (~cstop) then begin
        files = file_search(concat_dir(datedir, '*kcor_l1.fts'), count=count)
        if (count eq 0) then begin
          files = file_search(concat_dir(datedir,'*kcor_l1.fts.gz'), count=count)
          if (count eq 0) then begin
            message = 'No FITS files found in directory ' + datedir
            mg_log, message, name='kcor-cme', /info
            goto, stop_point
          endif
        endif

        ; Optionally limit the time range for testing purposes.
        if (n_elements(timerange) eq 2) then begin
          t0 = anytim2utc(timerange[0],/ccsds)
          t1 = anytim2utc(timerange[1],/ccsds)
          break_file, files, disk, dir, name
          tt = anytim2utc(strmid(name,0,15),/ccsds)
          w = where((tt ge t0) and (tt le t1), count)
          if (count eq 0) then begin
            message = 'No FITS files found in time range'
            mg_log, message, name='kcor-cme', /info
            goto, stop_point
          endif
          files = files[w]
        endif

        ; If the next file doesn't exist, then check the age of the last file.
        ; If at least 20 minutes old, then stop. Otherwise, wait 5 seconds.
        if (ifile ge count) then begin
          mtime = (file_info(files)).mtime
          age = systime(1) - max(mtime)
          if (age ge 1200) then begin   ; 600 sec originally
            mg_log, 'no more files', name='kcor-cme', /info
            goto, stop_point
          endif
          widget_control, wtopbase, timer=5
        endif else begin
          ; Otherwise, read in the file. Keep track of the begin and end times.
          break_file, files[ifile], disk, dir, name, ext
          widget_control, wfile, set_value=name + ext
          image = readfits(files[ifile], header, /silent)
          datatype = fxpar(header, 'datatype', count=ndatatype)
          if (ndatatype eq 0) then test = 1 else begin
            datatype = strtrim(fxpar(header,'datatype'),2)
            test = datatype eq 'science' or datatype eq 'engineering'
          endelse
          if (test) then begin
            date_obs = anytim2utc(fxpar(header, 'date-obs'), /ccsds)
            date_end = anytim2utc(fxpar(header, 'date-end'), /ccsds)
            tai_obs = utc2tai(date_obs)
            tai_end = utc2tai(date_end)
            temp = {date_obs: date_obs, tai_obs: tai_obs, $
                    date_end: date_end, tai_end: tai_end, $
                    filename: files[ifile]}
            if n_elements(date_orig) eq 0 then begin
              date_orig = temp
            endif else begin
              date_orig = [date_orig, temp]
            endelse

            ; remap the image into helioprojective radial coordinates
            break_file, files[ifile], disk, dir, name, ext
            name = name + '_hpr'
            hpr_out_file = concat_dir(hpr_out_dir, name + ext)
            kcor_cme_det_remap, header, image, hpr_out_file, hmap, map
            boost_array, maps, map

            ; form the running difference maps
            name = name + '_rd'
            diff_out_file = concat_dir(diff_out_dir, name + ext)
            kcor_cme_det_rdiff, hmap, maps, date_orig, diff_out_file, $
                                hdiff, mdiff, store=store

            ; keep track of the begin, end, and average times of the running
            ; difference maps
            if (n_elements(mdiff) gt 1) then begin
              wset, mapwin
              exptv, sigrange(mdiff), /nosquare, /nobox
              widget_control, wdate, set_value=fxpar(hdiff, 'date-avg')

              date_obs = fxpar(hdiff, 'date-obs')
              date_end = fxpar(hdiff, 'date-end')
              date_avg = fxpar(hdiff, 'date-avg')
              tai_obs = utc2tai(date_obs)
              tai_end = utc2tai(date_end)
              tai_avg = utc2tai(date_avg)
              temp = {date_obs: date_obs, tai_obs: tai_obs, $
                      date_end: date_end, tai_end: tai_end, $
                      date_avg: date_avg, tai_avg: tai_avg}
              if n_elements(date_diff) eq 0 then date_diff = temp else $
                  date_diff = [date_diff, temp]

              boost_array, mdiffs, mdiff

              ; determine candidate limits for any CME in the difference image
              kcor_cme_det_thresh, mdiff, itheta0
              if (itheta0[0] ge 0) then begin
                tvplt, replicate(itheta0[0],     2), [0, nrad]
                tvplt, replicate(itheta0[1] + 1, 2), [0, nrad]
                empty
              endif
              boost_array, itheta, itheta0

              ; look for CME detections based on the data that's been collected
              ; so far
              boost_array, detected, 0
              kcor_cme_det_find, tai_avg, date_diff, itheta0, itheta, $
                                 nlon, detected

              ; if any detections were made, then look for the leading edge
              idet = n_elements(detected) - 1
              nlead = n_elements(leadingedge)
              if (detected[idet]) then begin
                kcor_cme_det_track, mdiffs, itheta, detected, leadingedge
              endif

              ; if the LEADINGEDGE array grew in size, then update the plots
              if (n_elements(leadingedge) gt nlead) then begin
                ilead = n_elements(leadingedge) - 1
                lead0 = leadingedge[ilead]
                date0 = date_diff[ilead].date_avg
                if (lead0 ge 0) then begin
                  wset, mapwin
                  tvplt, [0, nlon], replicate(lead0, 2)
                  w = where(leadingedge ge 0, count)
                  if (count gt 1) then begin
                    wset, plotwin
                    rsun = (pb0r(date0))[2]
                    rad = 60 * (lat[leadingedge[w]] + 90) / rsun
                    utplot, date_diff[w].date_avg, rad, $
                            psym=2, xstyle=3, /ynozero, $
                            ytitle='Solar radii'

                    ; attempt to measure the CME parameters
                    kcor_cme_det_measure, rsun
                    if (n_elements(param) gt 0) then begin
                      widget_control, wangle, set_value=string(angle, format='(%"%d")')
                      widget_control, wspeed, set_value=string(speed, format='(%"%0.2f")')
                      x = date_diff.tai_avg - tairef
                      rfit = poly(x, param)
                      outplot, date_diff.date_avg, rfit
                    endif
                  endif
                endif else begin    ; valid LEAD0 
                  if (cme_occurring) then begin
                    kcor_cme_det_report
                    cme_occurring = 0B
                    mg_log, 'CME ended', name='kcor-cme', /info
                  endif
                endelse
              endif else begin      ; LEADINGEDGE grew
                if (cme_occurring) then begin
                  kcor_cme_det_report
                  cme_occurring = 0B
                  mg_log, 'CME ended', name='kcor-cme', /info
                endif
              endelse
            endif else begin        ; MDIFF formed
              if (cme_occurring) then begin
                kcor_cme_det_report
                cme_occurring = 0B
                mg_log, 'CME ended', name='kcor-cme', /info
              endif
            endelse
          endif           ; science image

          ; step to the next file
          ifile = ifile + 1
          widget_control, wtopbase, timer=0.1
        endelse
    end                         ;Not stopped

    'EXIT': begin
destroy:
        widget_control, event.top, /destroy
        return
      end
  endcase
end
