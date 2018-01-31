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
        date = string(julday(), format='(C(CYI4, CMOI02, CDI02))')
        kcor_cme_det_date, date

        if (file_exist(datedir)) then begin
          cstop = 0
          widget_control, wstart, sensitive=0
          widget_control, wstop, sensitive=1
          widget_control, wexit, sensitive=0
          widget_control, wfile, set_value=''
          mg_log, 'started', name='kcor/cme', /info
          widget_control, wtopbase, timer=0.1
        endif else begin
          mg_log, 'directory %s does not exist', datedir, name='kcor/cme', /warn
        endelse
      end

    'STOP': begin
stop_point:
        cstop = 1
        widget_control, wstart, sensitive=1
        widget_control, wstop, sensitive=0
        widget_control, wexit, sensitive=1
        widget_control, wtopbase, timer=0.1

        if (cme_occurring) then begin
          ref_time = tai2utc(tairef, /time, /truncate, /ccsds)
          kcor_cme_det_report, ref_time, /widget
          cme_occurring = 0B
          mg_log, 'CME ended at %s', ref_time, name='kcor/cme', /info
        endif

        mg_log, 'stopped', name='kcor/cme', /info
      end

    ; Operator-generated alert.
    'ALERT': begin
        itime = n_elements(leadingedge) - 1
        kcor_cme_det_alert, itime, /operator
      end

    'TIMER': begin
        kcor_cme_det_check, stopped=stopped, /widget
        if (stopped) then goto, stop_point
      end

    'EXIT': begin
destroy:
        widget_control, event.top, /destroy
        return
      end
  endcase
end
