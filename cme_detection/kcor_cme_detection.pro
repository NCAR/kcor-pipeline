;+
; Project     :	MLSO - KCOR
;
; Name        :	KCOR_CME_DETECTION
;
; Purpose     :	Detect CMEs in real-time K-cor data
;
; Category    :	KCOR, CME, Detection
;
; Explanation : This routine takes real-time K-cor data, and attempts to detect
;               whether any CMEs are in progress.  Upon entering the program, a
;               widget is brought up to show the progession of the processing.
;               On the left is shown the five-minute running difference images
;               in polar coordinates, with position angle running from
;               right-to-left (backwards 360 to 0 degrees), and radial distance
;               from bottom to top.  Vertical lines show the longitude range of
;               possible CMEs, and horizontal lines show the estimated position
;               of the leading edge.  The plotting window on the right shows
;               the leading edge estimates as a function of time.  When a
;               detection event occurs, a solid line shows the fitted
;               time-height relationship.
;
; Syntax      :	KCOR_CME_DETECTION
;
; Examples    :	KCOR_CME_DETECTION                      ;Process real-time data
;               KCOR_CME_DETECTION, '2016-01-01'        ;Test with old data
;
;               DATE = '20160101'                       ;TIMERANGE example
;               KCOR_CME_DETECTION, DATE, TIMERANGE=DATE+' '+['21:30','23:50']
;
; Inputs      :	None required
;
; Opt. Inputs :	DATE    = Optional date for testing purposes
;
; Outputs     :	Not yet defined
;
; Opt. Outputs:	None
;
; Keywords    :	STORE   = If set, then intermediate files are written to the
;                         run.hpr_dir and run.hpr_diff_dir directories.
;                         This speeds up processing if the software is rerun
;                         over the same date.
;
;               TIMERANGE = Two element array used in conjunction with DATE to
;                           limit the timerange to be processed.  Note that
;                           the date/time values must be fully qualified, as in
;                           the above example.
;
;               GROUP_LEADER = Widget ID of group leader, when called from
;                              another widget program.
;
; Calls       :	DELVARX, CONCAT_DIR, GET_UTC, ANYTIM2UTC, FILE_EXIST,
;               KCOR_CME_DET_EVENT
;
; Common      :	KCOR_CME_DETECTION
;
; Restrictions:	Only one copy of the program can be run at a time.
;
; Side effects:	None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 04-Jan-2017, William Thompson, GSFC
;               Version 2, 22-Mar-2017, William Thompson, GSFC
;                       Move directory check to event handler.
;                       Add "Send alert" button.
;
; Contact     :	WTHOMPSON
;-
;
pro kcor_cme_detection, date, store=k_store, timerange=k_timerange, $
                        group_leader=group_leader, $
                        config_filename=config_filename
  compile_opt strictarr

  ; check to see if the program is already running
  if xregistered('kcor_cme_detection') then begin
    message, 'KCOR_CME_DETECTION already running', /continue
    return
  endif

  ; define the common block
  @kcor_cme_det_common

  ; store relevant keywords in the common block
  if n_elements(k_store) eq 1 then store = k_store else store = 0
  if n_elements(k_timerange) eq 2 then timerange=k_timerange else $
      delvarx, timerange

  ; Define the parameters describing the resulting maps.  Note that the product
  ; of NLON*NAVG should be at least as large as the circumference in pixels of
  ; the outer edge of the coronagraph field of view.
  nlon = 120       ; Number of longitude points
  navg = 40        ; Number of points to average in longitude
  nrad = 310       ; Number of radial points.

  ; Determine the date directory from the date. If no date was passed, then use
  ; today's date.
  if (n_elements(date) eq 0) then begin
    date = string(julday(), format='(C(CYI4, CMOI02, CDI02))')
  endif

  ymd = kcor_decompose_date(date)
  run = kcor_run(date, config_filename=config_filename)

  ; the top of the directory tree containing the KCor data is given by
  ; archive_basedir
  kcor_dir = run.archive_basedir
  datedir = filepath('', subdir=ymd, root=kcor_dir)

  ; hpr_dir points to the top of the directory tree used for storing images
  ; converted into helioprojective-radial (HPR) coordinates
  kcor_hpr_dir = run.hpr_dir
  if (~file_test(kcor_hpr_dir, /directory)) then file_mkdir, kcor_hpr_dir

  ; hpr_diff_dir points to the top of the directory tree used for storing
  ; running difference maps in helioprojective-radial (HPR) coordinates
  kcor_hpr_diff_dir = run.hpr_diff_dir
  if (~file_test(kcor_hpr_diff_dir, /directory)) then begin
    file_mkdir, kcor_hpr_diff_dir
  endif

  ; make sure that the output directories exist
  hpr_out_dir = filepath('', subdir=ymd, root=kcor_hpr_dir)
  if (keyword_set(store) and not file_test(hpr_out_dir, /directory)) then begin
    file_mkdir, hpr_out_dir
  endif

  diff_out_dir = filepath('', subdir=ymd, root=kcor_hpr_diff_dir)
  if (keyword_set(store) and not file_test(diff_out_dir, /directory)) then begin
    file_mkdir, diff_out_dir
  endif

  ; define the top widget base
  wtopbase = widget_base(title='K-Cor CME Detection', $
                         group_leader=group_leader, $
                         /row, tlb_frame_attr=1, uvalue='TIMER', $
                         /tlb_kill_request_events)

  ; define a base for the maps
  wpolbase = widget_base(wtopbase, /column, /frame)
  wfile = cw_field(wpolbase, title='Processing file', /noedit, xsize=40)
  wmap = widget_draw(wpolbase, xsize=nlon*4, ysize=nrad, retain=2)
  title = string(replicate(32b,15)) + 'Image date/time'
  wdate = cw_field(wpolbase, title=title, /noedit, xsize=25)

  ; include the output parameters
  winfo = widget_base(wpolbase, /row)
  wangle = cw_field(winfo, title='Position angle (deg)', /noedit, xsize=12)
  wspeed = cw_field(winfo, title='Speed (km/s)', /noedit, xsize=12)

  ; define the start, stop, and exit buttons
  wbbase = widget_base(wpolbase, /row)
  wstart = widget_button(wbbase, value='Start', uvalue='START')
  wstop  = widget_button(wbbase, value='Stop', uvalue='STOP', sensitive=0)
  wexit  = widget_button(wbbase, value='Exit', uvalue='EXIT')
  dummy  = widget_label(wbbase, value='                    ')
  walert = widget_button(wbbase, value='Send alert', uvalue='ALERT')
  cstop = 0

  ; define a base for the output
  woutbase = widget_base(wtopbase, /column)
  wmessage = widget_text(woutbase, xsize=100, ysize=5, /scroll)
  wplot = widget_draw(woutbase, xsize=800, ysize=360, retain=2)

  mg_log, logger=widget_logger, name='kcor/cme'
  log_format = '%(time)s %(levelshortname)s: %(message)s'
  widget_logger->setProperty, widget_identifier=wmessage, format=log_format

  ; reset common block variables
  kcor_cme_det_reset

  ; realize the widget hierarchy, and register the widget with XMANAGER

  ; start up SolarSoft display routines
  defsysv, '!image', exists=sys_image_defined
  if (~sys_image_defined) then imagelib
  defsysv, '!aspect', exists=sys_aspect_defined
  if (~sys_aspect_defined) then devicelib

  widget_control, wtopbase, /realize
  widget_control, wmap, get_value=mapwin
  widget_control, wplot, get_value=plotwin
  xmanager, 'kcor_cme_detection', wtopbase, /no_block, $
            event_handler='kcor_cme_det_event'
end
