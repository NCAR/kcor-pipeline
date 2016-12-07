; docformat = 'rst'

;+
; Plot chosen K-coronagraph parameters.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   list : in, required, type=strarr
;     list of files to process
;   run : in, required, type=object
;     `kcor_run` object
;
; :Author:
;   Andrew L. Stanger   HAO/NCAR   26 November 2014
;
; :History:
;   10 Feb 2015 Revised plot date format.
;               Changed hours X-range [16-28],
;               Changed DIMV  Y-range [5.5-7.5].
;               Changed modular temp Y-range [28-36].
;   22 Feb 2015 L0 files are now in level0 sub-directory.
;   31 May 2015 Modify yrange for O1 focus from [130, 140] to [130, 150].  
;    8 Jun 2015 Modify yrange for O1 focus from [130, 150] to [125, 150].
;   10 Jun 2015 Modify yrange for O1 focus from [125, 150] to [110, 150].
;               Also print focus values in log file.
;-

pro kcorp, date, list=list, run=run
  compile_opt strictarr

  if (n_params() eq 0) then begin
    mg_log, 'missing date parameter', name='kcor/eod', /error
    return
  endif

  ;----------------------------------------------------------------------------
  ; Establish directory paths.
  ;----------------------------------------------------------------------------
  l0_base = run.raw_basedir
  l0_dir  = filepath('level0', subdir=date, root=l0_base)
  p_dir   = filepath('p', subdir=date, root=l0_base)

  ;----------------------------------------------------------------------------
  ; Create sub-directory for plots.
  ;----------------------------------------------------------------------------
  file_mkdir, p_dir

  ;----------------------------------------------------------------------------
  ; Move to L0 kcor directory.
  ;----------------------------------------------------------------------------
  cd, current=start_dir   ; save current directory.
  cd, l0_dir              ; move to raw (l0) kcor directory.

  doview = 0

  ; establish list of files to process

  mg_log, 'start_dir: %s', start_dir, name='kcor/eod', /debug
  mg_log, 'l0_dir:    %s', l0_dir, name='kcor/eod', /debug
  mg_log, 'p_dir:     %s', p_dir, name='kcor/eod', /debug

  ;----------------------------------------------------------------------------
  ; Set up graphics window & color table.
  ;----------------------------------------------------------------------------
  set_plot, 'Z'
  device, set_resolution=[772, 1000], decomposed=0, set_colors=256, $
          z_buffering=0
  !p.multi = [0, 1, 3]

  ;----------------------------------------------------------------------------
  ; Determine the number of files to process.
  ;----------------------------------------------------------------------------
  nimg = n_elements(list)
  mg_log, 'nimg: %d', nimg, name='kcor/eod', /debug

  ;----------------------------------------------------------------------------
  ; Declare storage for plot arrays.
  ;----------------------------------------------------------------------------

  mod_temp = fltarr(nimg)
  sgs_dimv = fltarr(nimg)
  sgs_scin = fltarr(nimg)
  hours    = fltarr(nimg)

  tcam_focus = fltarr(nimg)
  rcam_focus = fltarr(nimg)
  o1_focus   = fltarr(nimg)

  ;----------------------------------------------------------------------------
  ; Image file loop.
  ;----------------------------------------------------------------------------
  for i = 0L, n_elements(list) - 1L do begin
    l0_file = list[i]

    hdu = headfits(l0_file, /silent)   ; read FITS header

    ; get FITS header size
    hdusize = size(hdu)

    ; extract keyword parameters from FITS header
    diffuser = ''
    calpol   = ''
    darkshut = ''
    cover    = ''
    occltrid = ''

    naxis    = sxpar(hdu, 'NAXIS',    count=qnaxis)
    naxis1   = sxpar(hdu, 'NAXIS1',   count=qnaxis1)
    naxis2   = sxpar(hdu, 'NAXIS2',   count=qnaxis2)
    naxis3   = sxpar(hdu, 'NAXIS3',   count=qnaxis3)
    naxis4   = sxpar(hdu, 'NAXIS4',   count=qnaxis4)
    np       = naxis1 * naxis2 * naxis3 * naxis4 

    date_obs = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    level    = sxpar(hdu, 'LEVEL',    count=qlevel)

    bzero    = sxpar(hdu, 'BZERO',    count=qbzero)
    bbscale  = sxpar(hdu, 'BSCALE',   count=qbbscale)

    datatype = sxpar(hdu, 'DATATYPE', count=qdatatype)

    diffuser = sxpar(hdu, 'DIFFUSER', count=qdiffuser)
    calpol   = sxpar(hdu, 'CALPOL',   count=qcalpol)
    darkshut = sxpar(hdu, 'DARKSHUT', count=qdarkshut)
    cover    = sxpar(hdu, 'COVER',    count=qcover)

    occltrid = sxpar(hdu, 'OCCLTRID', count=qoccltrid)

    tcamfocs = sxpar(hdu, 'TCAMFOCS', count=qtcamfocs)
    rcamfocs = sxpar(hdu, 'RCAMFOCS', count=qrcamfocs)
    o1focs   = sxpar(hdu, 'O1FOCS',   count=qo1focs)

    modltrt  = sxpar(hdu, 'MODLTRT',  count=qmodltrt)
    sgsdimv  = sxpar(hdu, 'SGSDIMV',  count=qsgsdimv)
    sgsscint = sxpar(hdu, 'SGSSCINT', count=qsgsscint)

    mod_temp[i] = modltrt
    sgs_dimv[i] = sgsdimv
    sgs_scin[i] = sgsscint

    tcam_focus[i] = tcamfocs
    rcam_focus[i] = rcamfocs
    o1_focus[i]   = o1focs

    ; determine occulter size in pixels
    occulter = strmid (occltrid, 3, 5)   ; extract 5 characters from occltrid
    if (occulter eq '991.6') then occulter =  991.6
    if (occulter eq '1018.') then occulter = 1018.9
    if (occulter eq '1006.') then occulter = 1006.9

    platescale = run.plate_scale   ; arsec/pixel.
    radius_guess = occulter / platescale   ; occulter size [pixels]

    mg_log, '%27s %4d %11s %7.3f %7.3f %9.3f', $
            l0_file, i + 1, datatype, modltrt, sgsdimv, sgsscint, $
            name='kcor/eod', /debug
    mg_log, '%7.3f %7.3f %9.3f', $
            tcamfocs, rcamfocs, o1focs, $
            name='kcor/eod', /debug

    ;-------------------------------------------------------------------------
    ; Define array dimensions.
    ;-------------------------------------------------------------------------
    xdim = naxis1
    ydim = naxis2

    ;-------------------------------------------------------------------------
    ; Extract date items from FITS header parameter (DATE-OBS).
    ;-------------------------------------------------------------------------
    year   = strmid(date_obs, 0, 4)
    month  = strmid(date_obs, 5, 2)
    day    = strmid(date_obs, 8, 2)
    hour   = strmid(date_obs, 11, 2)
    minute = strmid(date_obs, 14, 2)
    second = strmid(date_obs, 17, 2)

    ; pdate is for the plot title
    if (i eq 0) then begin
      pyear   = strmid(date, 0, 4)
      pmonth  = strmid(date, 4, 2)
      pday    = strmid(date, 6, 2)
      pdate   = string(pyear, pmonth, pday, format='(%"%s-%s-%s")')
    endif

    datetime = string(year, month, day, hour, minute, second, $
                      format='(%"%s-%s-%sT%s:%s:%s")')

    ; obs_hour is referenced to the observing day, so add 24 hours to the hours
    ; past midnight UT
    obs_hour = hour
    if (hour lt 16) then obs_hour += 24

    hours[i] = obs_hour + minute / 60.0 + second / 3600.0

    ;-------------------------------------------------------------------------
    ; Verify that image is Level 0.
    ;-------------------------------------------------------------------------
    if (level ne 'l0')  then begin
      mg_log, 'not level 0 data', name='kcor/eod', /warn
      continue
    endif
  endfor

  ; TODO: these files aren't produced?
  modgif  = filepath(date + '_list_mtmp.gif', root=p_dir)
  dimvgif = filepath(date + '_list_dimv.gif', root=p_dir)
  scingif = filepath(date + '_list_scin.gif', root=p_dir)

  enggif  = filepath(date + '_list_eng.gif', root=p_dir)
  focgif  = filepath(date + '_list_foc.gif', root=p_dir)

  mg_log, 'enggif: %s', enggif, name='kcor/eod', /debug
  mg_log, 'focgif: %s', focgif, name='kcor/eod', /debug

  plot, hours, mod_temp, title=pdate + '  Kcor Modulator Temperature', $
        xtitle='Hours [UT]', ytitle='Temperature [deg C]', $
        background=255, color=0, charsize=2.0, $
        xrange=[16.0, 28.0], yrange=[28.0, 36.0]

  plot, hours, sgs_dimv, title=pdate + '  Kcor SGS DIM', $
        xtitle='Hours [UT]', ytitle='DIM [volts]', /ynozero, $
        xrange=[16.0, 28.0], yrange=[5.5, 7.5], $
        background=255, color=0, charsize=2.0

  ; use fixed y-axis scaling, unless values wander outside the range: 0 to 10.
  smin = min(sgs_scin)
  smax = max(sgs_scin)
  plot, hours, sgs_scin, title=pdate + '  Kcor SGS Scintillation', $
        xtitle='Hours [UT]', ytitle='Scintillation [arcsec]', $
        xrange=[16.0, 28.0], yrange=[0.0, 10.0], $
        background=255, color=0, charsize=2.0 

  save = tvrd ()
  write_gif, enggif, save

  erase

  plot, hours, tcam_focus, title=pdate + '  KCOR T Camera Focus position', $
        xtitle='Hours [UT]', ytitle='T Camera Focus [mm]', $
        background=255, color=0, charsize=2.0, $
        xrange=[16.0, 28.0], yrange=[-1.0, 1.0]

  plot, hours, rcam_focus, title=pdate + '  KCOR R Camera Focus position', $
        xtitle='Hours [UT]', ytitle='R Camera Focus [mm]', $
        background=255, color=0, charsize=2.0, $
        xrange=[16.0, 28.0], yrange=[-1.0, 1.0]

  plot, hours, o1_focus, title=pdate + '  KCOR O1 Focus position', $
        xtitle='Hours [UT]', ytitle='O1 Camera Focus [mm]', $
        background=255, color=0, charsize=2.0, $
        xrange=[16.0, 28.0], yrange=[110.0, 150.0]
  save = tvrd() 
  write_gif, focgif, save

  mg_log, 'done', name='kcor/eod', /info

  cd, start_dir
  set_plot, 'X'
end
