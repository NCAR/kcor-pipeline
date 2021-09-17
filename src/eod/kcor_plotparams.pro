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
pro kcor_plotparams, date, list=list, run=run
  compile_opt strictarr

  mg_log, 'plotting parameters for %s', date, name='kcor/eod', /info

  ; establish directory paths
  l0_base   = run->config('processing/raw_basedir')
  l0_dir    = filepath('level0', subdir=date, root=l0_base)
  plots_dir = filepath('p', subdir=date, root=l0_base)

  ; create sub-directory for plots
  file_mkdir, plots_dir

  ; move to L0 kcor directory
  cd, current=start_dir   ; save current directory.
  cd, l0_dir              ; move to raw (l0) kcor directory.

  ; establish list of files to process

  ; determine the number of files to process
  nimg = n_elements(list)
  mg_log, '%d L0 images to plot', nimg, name='kcor/eod', /debug

  ; declare storage for plot arrays
  mod_temp   = fltarr(nimg)

  sgs_dimv   = fltarr(nimg)
  sgs_dims   = fltarr(nimg)
  sgs_scint  = fltarr(nimg)

  sgs_sumv   = fltarr(nimg)
  sgs_sums   = fltarr(nimg)

  sgs_rav    = fltarr(nimg)
  sgs_ras    = fltarr(nimg)
  sgs_razr   = fltarr(nimg)

  sgs_decv   = fltarr(nimg)
  sgs_decs   = fltarr(nimg)
  sgs_deczr  = fltarr(nimg)

  hours      = fltarr(nimg)

  tcam_focus = fltarr(nimg)
  rcam_focus = fltarr(nimg)
  o1_focus   = fltarr(nimg)

  ; used for log messages
  indent = strjoin(strarr(4 + 2 + ceil(alog10(n_elements(list) + 1))) + ' ')

  ; image file loop
  for i = 0L, n_elements(list) - 1L do begin
    l0_file = list[i]

    kcor_read_rawdata, l0_file, header=hdu, $
                       repair_routine=run->epoch('repair_routine'), $
                       xshift=run->epoch('xshift_camera'), $
                       start_state=run->epoch('start_state'), $
                       raw_data_prefix=run->epoch('raw_data_prefix'), $
                       datatype=run->epoch('raw_datatype')

    ; get FITS header size
    hdusize = size(hdu)

    ; extract keyword parameters from FITS header
    naxis    = sxpar(hdu, 'NAXIS',    count=qnaxis)
    naxis1   = sxpar(hdu, 'NAXIS1',   count=qnaxis1)
    naxis2   = sxpar(hdu, 'NAXIS2',   count=qnaxis2)
    naxis3   = sxpar(hdu, 'NAXIS3',   count=qnaxis3)
    naxis4   = sxpar(hdu, 'NAXIS4',   count=qnaxis4)
    np       = naxis1 * naxis2 * naxis3 * naxis4 

    date_obs = sxpar(hdu, 'DATE-OBS', count=qdate_obs)
    run.time = date_obs
    level    = sxpar(hdu, 'LEVEL',    count=qlevel)

    bzero    = sxpar(hdu, 'BZERO',    count=qbzero)
    bbscale  = sxpar(hdu, 'BSCALE',   count=qbbscale)

    datatype = sxpar(hdu, 'DATATYPE', count=qdatatype)

    diffuser = strtrim(sxpar(hdu, 'DIFFUSER', count=qdiffuser))
    calpol   = strtrim(sxpar(hdu, 'CALPOL',   count=qcalpol))
    darkshut = strtrim(sxpar(hdu, 'DARKSHUT', count=qdarkshut))
    cover    = strtrim(sxpar(hdu, 'COVER',    count=qcover))

    if (run->epoch('use_occulter_id')) then begin
      occltrid = sxpar(hdu, 'OCCLTRID', count=qoccltrid)
    endif else begin
      occltrid = run->epoch('occulter_id')
    endelse

    tcamfocs = sxpar(hdu, 'TCAMFOCS', count=qtcamfocs)
    rcamfocs = sxpar(hdu, 'RCAMFOCS', count=qrcamfocs)
    o1focs   = sxpar(hdu, 'O1FOCS',   count=qo1focs)

    modltrt  = sxpar(hdu, 'MODLTRT',  count=qmodltrt)

    mod_temp[i] = modltrt

    if (run->epoch('use_sgs')) then begin
      sgs_dimv[i]  = kcor_getsgs(hdu, 'SGSDIMV', /float)
      sgs_dims[i]  = kcor_getsgs(hdu, 'SGSDIMS', /float)
      sgs_scint[i] = kcor_getsgs(hdu, 'SGSSCINT', /float)

      sgs_sumv[i]  = kcor_getsgs(hdu, 'SGSSUMV', /float)
      sgs_sums[i]  = kcor_getsgs(hdu, 'SGSSUMS', /float)

      sgs_rav[i]   = kcor_getsgs(hdu, 'SGSRAV', /float)
      sgs_ras[i]   = kcor_getsgs(hdu, 'SGSRAS', /float)
      sgs_razr[i]  = kcor_getsgs(hdu, 'SGSRAZR', /float)

      sgs_decv[i]  = kcor_getsgs(hdu, 'SGSDECV', /float)
      sgs_decs[i]  = kcor_getsgs(hdu, 'SGSDECS', /float)
      sgs_deczr[i] = kcor_getsgs(hdu, 'SGSDECZR', /float)
    endif else begin
      sgs_dimv[i]  = !values.f_nan
      sgs_dims[i]  = !values.f_nan
      sgs_scint[i] = !values.f_nan

      sgs_sumv[i]  = !values.f_nan
      sgs_sums[i]  = !values.f_nan

      sgs_rav[i]   = !values.f_nan
      sgs_ras[i]   = !values.f_nan
      sgs_razr[i]  = !values.f_nan

      sgs_decv[i]  = !values.f_nan
      sgs_decs[i]  = !values.f_nan
      sgs_deczr[i] = !values.f_nan
    endelse

    tcam_focus[i] = tcamfocs
    rcam_focus[i] = rcamfocs
    o1_focus[i]   = o1focs

    occulter = kcor_get_occulter_size(occltrid, run=run) ; occulter size [arcsec]
    radius_guess = occulter / run->epoch('plate_scale')  ; occulter size [pixels]

    mg_log, '%4d/%d: %s %s', $
            i + 1, n_elements(list), file_basename(l0_file), $
            strmid(datatype, 0, 3), $
            name='kcor/eod', /debug
    mg_log, '%s%8.3f %8.3f %8.3f', $
            indent, modltrt, sgs_dimv[i], sgs_scint[i], $
            name='kcor/eod', /debug
    mg_log, '%s%8.3f %8.3f %10.3f', $
            indent, tcamfocs, rcamfocs, o1focs, $
            name='kcor/eod', /debug

    ; define array dimensions
    xdim = naxis1
    ydim = naxis2

    ; extract date items from FITS header parameter (DATE-OBS)
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

    ; verify that image is Level 0
    if (level ne 'L0')  then begin
      mg_log, 'not level 0 data', name='kcor/eod', /warn
      continue
    endif
  endfor

  time_range = [16.0, 28.0]

  ; set up graphics window & color table for sgs.eng.gif
  set_plot, 'Z'
  device, set_resolution=[772, 1000], $
          decomposed=0, $
          set_colors=256, $
          z_buffering=0

  !p.multi = [0, 1, 3]

  mg_range_plot, hours, sgs_dimv, $
                 title=pdate + ' KCor SGS DIM (Sky transmission)', $
                 xtitle='Hours [UT]', ytitle='Relative sky transmission - DIM [volts]', $
                 xrange=time_range, $
                 /ynozero, ystyle=1, yrange=run->epoch('sgsdimv_range'), $
                 background=255, color=0, charsize=1.0, $
                 clip_thick=2.0, psym=1

  mg_range_plot, hours, sgs_dims, $
                 title=pdate + ' KCor SGS DIMS (Sky transmission std dev)', $
                 xtitle='Hours [UT]', ytitle='Relative sky transmission - DIM [volts]', $
                 xrange=time_range, $
                 /ynozero, ystyle=1, yrange=run->epoch('sgsdims_range'), $
                 background=255, color=0, charsize=1.0, $
                 clip_thick=2.0, psym=1

  mg_range_plot, hours, sgs_scint, $
                 title=pdate + ' KCor SGS Scintillation', $
                 xtitle='Hours [UT]', ytitle='Scintillation [arcsec]', $
                 xrange=time_range, $
                 ystyle=1, yrange=run->epoch('sgsscint_range'), $
                 background=255, color=0, charsize=1.0, $
                 clip_thick=2.0

  sgs_seeing_gif_filename  = filepath(date + '.kcor.sgs.seeing.gif', root=plots_dir)
  mg_log, 'SGS seeing GIF: %s', file_basename(sgs_seeing_gif_filename), name='kcor/eod', /debug
  write_gif, sgs_seeing_gif_filename, tvrd()

  !p.multi = [0, 1, 2]

  mg_range_plot, hours, sgs_sumv, $
                 title=pdate + ' KCor SGS SUMV', $
                 xtitle='Hours [UT]', ytitle='?', $
                 xrange=time_range, $
                 /ynozero, ystyle=1, yrange=run->epoch('sgssumv_range'), $
                 background=255, color=0, charsize=1.0, $
                 clip_thick=2.0, psym=1

  mg_range_plot, hours, sgs_sums, $
                 title=pdate + ' KCor SGS SUMS', $
                 xtitle='Hours [UT]', ytitle='?', $
                 xrange=time_range, $
                 /ynozero, ystyle=1, yrange=run->epoch('sgssums_range'), $
                 background=255, color=0, charsize=1.0, $
                 clip_thick=2.0, psym=1

  sgs_signal_gif_filename  = filepath(date + '.kcor.sgs.signal.gif', root=plots_dir)
  mg_log, 'SGS signal GIF: %s', file_basename(sgs_signal_gif_filename), name='kcor/eod', /debug
  write_gif, sgs_signal_gif_filename, tvrd()

  !p.multi = [0, 1, 3]

  mg_range_plot, hours, sgs_rav, $
                 title=pdate + ' KCor RAV', $
                 xtitle='Hours [UT]', ytitle='RA [degrees]', $
                 xrange=time_range, $
                 /ynozero, ystyle=1, yrange=run->epoch('sgsrav_range'), $
                 background=255, color=0, charsize=1.0, $
                 clip_thick=2.0, psym=1

  mg_range_plot, hours, sgs_ras, $
                 title=pdate + ' KCor RAS', $
                 xtitle='Hours [UT]', ytitle='RA [degrees]', $
                 xrange=time_range, $
                 /ynozero, ystyle=1, yrange=run->epoch('sgsras_range'), $
                 background=255, color=0, charsize=1.0, $
                 clip_thick=2.0, psym=1
  
  mg_range_plot, hours, sgs_razr, $
                 title=pdate + ' KCor RAZR', $
                 xtitle='Hours [UT]', ytitle='RA [degrees]', $
                 xrange=time_range, $
                 ystyle=1, yrange=run->epoch('sgsrazr_range'), $
                 background=255, color=0, charsize=1.0, $
                 clip_thick=2.0

  sgs_ra_gif_filename  = filepath(date + '.kcor.sgs.ra.gif', root=plots_dir)
  mg_log, 'SGS RA GIF: %s', file_basename(sgs_ra_gif_filename), name='kcor/eod', /debug
  write_gif, sgs_ra_gif_filename, tvrd()

  !p.multi = [0, 1, 3]

  mg_range_plot, hours, sgs_decv, $
                 title=pdate + ' KCor DECV', $
                 xtitle='Hours [UT]', ytitle='DEC [degrees]', $
                 xrange=time_range, $
                 /ynozero, ystyle=1, yrange=run->epoch('sgsdecv_range'), $
                 background=255, color=0, charsize=1.0, $
                 clip_thick=2.0, psym=1

  mg_range_plot, hours, sgs_decs, $
                 title=pdate + ' KCor DECS', $
                 xtitle='Hours [UT]', ytitle='DEC [degrees]', $
                 xrange=time_range, $
                 /ynozero, ystyle=1, yrange=run->epoch('sgsdecs_range'), $
                 background=255, color=0, charsize=1.0, $
                 clip_thick=2.0, psym=1
  
  mg_range_plot, hours, sgs_deczr, $
                 title=pdate + ' KCor DECZR', $
                 xtitle='Hours [UT]', ytitle='DEC [degrees]', $
                 xrange=time_range, $
                 ystyle=1, yrange=run->epoch('sgsdeczr_range'), $
                 background=255, color=0, charsize=1.0, $
                 clip_thick=2.0

  sgs_dec_gif_filename  = filepath(date + '.kcor.sgs.dec.gif', root=plots_dir)
  mg_log, 'SGS DEC GIF: %s', file_basename(sgs_dec_gif_filename), name='kcor/eod', /debug
  write_gif, sgs_dec_gif_filename, tvrd()

  rav_min = min(sgs_rav - sgs_ras, /nan)
  rav_max = max(sgs_rav + sgs_ras, /nan)
  mg_log, 'SGSRAV min=%f, max=%f', rav_min, rav_max, name='kcor/eod', /debug

  decv_min = min(sgs_decv - sgs_decs, /nan)
  decv_max = max(sgs_decv + sgs_decs, /nan)
  mg_log, 'SGSDECV min=%f, max=%f', decv_min, decv_max, name='kcor/eod', /debug

  razr_min = min(sgs_razr, max=razr_max, /nan)
  if (~finite(razr_min)) then begin
    razr_min = -20.0
    razr_max =  20.0
  endif
  mg_log, 'SGSRAZR min=%f, max=%f', razr_min, razr_max, name='kcor/eod', /debug

  deczr_min = min(sgs_deczr, max=deczr_max, /nan)
  if (~finite(deczr_min)) then begin
    deczr_min =  40.0
    deczr_max = 100.0
  endif
  mg_log, 'SGSDECZR min=%f, max=%f', deczr_min, deczr_max, name='kcor/eod', /debug

  done:
  cd, start_dir
  !p.multi = 0
  set_plot, 'X'

  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

date = '20130930'
run = kcor_run(date, $
               config_filename=filepath('kcor.mgalloy.mahi.latest.cfg', $
                                        subdir=['..', '..', 'config'], $
                                        root=mg_src_root()))
list = file_search(filepath('*.fts.gz', $
                            subdir=[date, 'level0'], $
                            root=run->config('processing/raw_basedir')))
kcor_plotparams, date, list=list, run=run

end
