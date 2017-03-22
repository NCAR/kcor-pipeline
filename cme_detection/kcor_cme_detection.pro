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
;               DATE = '2016-01-01'                     ;TIMERANGE example
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
;                         $KCOR_HPR_DIR and $KCOR_HPR_DIFF_DIR directories.
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
; Env. Vars.  : KCOR_DIR = Top of the directory tree containing the FITS files.
;                          Contains directories for the years, months, and
;                          individual days, e.g. $KCOR_DIR/2016/01/01.  If not
;                          defined, then defaults to the subdirectory "acos" in
;                          the current directory.
;
;               KCOR_MOVIE_DIR = Directory to write movies to.  If not defined,
;                                then the movies are written to the current
;                                directory.
;
;               KCOR_MAILING_LIST = Text file containing a list of email
;                                   addresses, one per line.
;
;               KCOR_HPR_DIR = Top of directory tree containing intermediate
;                              FITS files in helioprojective-radial (HPR)
;                              polar coordinates.  If not defined, then
;                              defaults to "kcor_hpr" in current directory.
;                              Ignored unless used with /STORE.
;
;               KCOR_HPR_DIFF_DIR = Top of directory tree containing running
;                                   difference maps.  If not defined, then
;                                   defaults to "kcor_hpr_diff".  Ignored
;                                   unless used with /STORE.
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
                        group_leader=group_leader
;
;  Check to see if the program is already running.
;
if xregistered('kcor_cme_detection') then begin
    message, 'KCOR_CME_DETECTION already running', /continue
    return
endif
;
;  Define the common block.
;
common kcor_cme_detection, nlon, navg, nrad, lon, lat, store, timerange, $
  kcor_dir, kcor_hpr_dir, kcor_hpr_diff_dir, datedir, hpr_out_dir, $
  diff_out_dir, wtopbase, wdate, wstart, wstop, wexit, cstop, wmessage, $
  wfile, wangle, wspeed, mapwin, plotwin, ifile, date_orig, maps, date_diff, $
  mdiffs, itheta, detected, leadingedge, param, tairef, angle, speed
;
;  Store relevant keywords in the common block.
;
if n_elements(k_store) eq 1 then store = k_store else store = 0
if n_elements(k_timerange) eq 2 then timerange=k_timerange else $
  delvarx, timerange
;
;  Define the parameters describing the resulting maps.  Note that the product
;  of NLON*NAVG should be at least as large as the circumference in pixels of
;  the outer edge of the coronagraph field of view.
;
nlon = 120                      ;Number of longitude points
navg = 40                       ;Number of points to average in longitude
nrad = 310                      ;Number of radial points.
;
;  The top of the directory tree containing the kcor data is given by the
;  environment variable KCOR_DIR.
;
kcor_dir = getenv('KCOR_DIR')
if kcor_dir eq '' then begin
    cd, current=current
    kcor_dir = concat_dir(current, 'acos')
endif
;
;  The environment variable KCOR_HPR_DIR points to the top of the directory
;  tree used for storing images converted into helioprojective-radial (HPR)
;  coordinates.
;
kcor_hpr_dir = getenv('KCOR_HPR_DIR')
if kcor_hpr_dir eq '' then begin
    cd, current=current
    kcor_hpr_dir = concat_dir(current,'kcor_hpr')
endif
;
;  The environment variable KCOR_HPR_DIFF_DIR points to the top of the
;  directory tree used for storing running difference maps in
;  helioprojective-radial (HPR) coordinates.
;
kcor_hpr_diff_dir = getenv('KCOR_HPR_DIFF_DIR')
if kcor_hpr_diff_dir eq '' then begin
    cd, current=current
    kcor_hpr_diff_dir = concat_dir(current,'kcor_hpr_diff')
endif
;
;  Determine the date directory from the date.  If no date was passed, then use
;  today's date.
;
if n_elements(date) eq 0 then get_utc, date
sdate = anytim2utc(date, /ecs, /date_only)
datedir = concat_dir(kcor_dir, sdate)
;
;  Make sure that the output directories exist.
;
hpr_out_dir = concat_dir(kcor_hpr_dir, sdate)
if keyword_set(store) and (not file_exist(hpr_out_dir)) then $
  file_mkdir, hpr_out_dir
diff_out_dir = concat_dir(kcor_hpr_diff_dir, sdate)
if keyword_set(store) and (not file_exist(diff_out_dir)) then $
  file_mkdir, diff_out_dir
;
;  Define the top widget base.
;
wtopbase = widget_base(title='K-cor CME Detection', group_leader=group_leader, $
                       /row, tlb_frame_attr=1, uvalue='TIMER', $
                      /tlb_kill_request_events)
;
;  Define a base for the maps.
;
wpolbase = widget_base(wtopbase, /column, /frame)
wfile = cw_field(wpolbase, title='Processing file', /noedit, xsize=40)
wmap = widget_draw(wpolbase, xsize=nlon*4, ysize=nrad)
title = string(replicate(32b,15)) + 'Image date/time'
wdate = cw_field(wpolbase, title=title, /noedit, xsize=25)
;
;  Include the output parameters.
;
winfo = widget_base(wpolbase, /row)
wangle = cw_field(winfo, title='Position angle', /noedit)
wspeed = cw_field(winfo, title='Speed (km/s)', /noedit)
;
;  Define the start, stop, and exit buttons.
;
wbbase = widget_base(wpolbase, /row)
wstart = widget_button(wbbase, value='Start', uvalue='START')
wstop  = widget_button(wbbase, value='Stop', uvalue='STOP', sensitive=0)
wexit  = widget_button(wbbase, value='Exit', uvalue='EXIT')
dummy  = widget_label(wbbase, value='                    ')
walert = widget_button(wbbase, value='Send alert', uvalue='ALERT')
cstop = 0
;
;  Define a base for the output
;
woutbase = widget_base(wtopbase, /column)
wmessage = widget_text(woutbase, xsize=80, ysize=5, /scroll)
wplot = widget_draw(woutbase, xsize=640, ysize=360)
;
;  Realize the widget hierarchy, and register the widget with XMANAGER.
;
ifile = 0
delvarx, date_orig, maps, date_diff, mdiffs, itheta, detected, leadingedge
delvarx, param, tairef, angle, speed
;
widget_control, wtopbase, /realize
widget_control, wmap, get_value=mapwin
widget_control, wplot, get_value=plotwin
xmanager, 'kcor_cme_detection', wtopbase, /no_block, $
          event_handler='kcor_cme_det_event'
;
end
