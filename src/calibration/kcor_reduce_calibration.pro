; docformat = 'rst'

;+
; Main calibration routine.
;
; :Uses:
;   kcor_read_calibration_text, kcor_reduce_calibration_read,
;   kcor_reduce_calibration_setup_lm, kcor_reduce_calibration_model,
;   kcor_reduce_calibration_write
;
; :Params:
;   date : in, required, type=date
;     date in the form 'YYYYMMDD' to produce calibration for
;
; :Keywords:
;   filelist : in, optional, type=strarr
;     list of L0 FITS files to use for the calibration if present, otherwise
;     reads the `calibration_files.txt` file in the process directory
;   config_filename : in, optional, type=string
;     filename of configuration file; `config_filename` or `run` is required
;   run : in, optional, type=object
;     `kcor_run` object; `config_filename` or `run` is required
;-
pro kcor_reduce_calibration, date, filelist=filelist, config_filename=config_filename, run=run
  common kcor_random, seed

  run_created = ~obj_valid(run)
  if (run_created) then begin
    run = kcor_run(date, config_filename=config_filename)
  endif

  if (n_elements(filelist) gt 0L) then begin
    n_files = n_elements(filelist)
    file_list = filelist
    exposures = strarr(n_files)

    cd, current=current_dir
    cd, filepath('level0', subdir=date, root=run.raw_basedir)

    ; extract exposures from files
    for f = 0L, n_files - 1L do begin
      header = headfits(filelist[f])

      exposure = sxpar(header, 'EXPTIME', count=nrecords)
      if (nrecords eq 0) then exposure = sxpar(header, 'EXPOSURE')

      exposures[f] = string(exposure, format='(f10.4)')
    endfor

    cd, current_dir
  endif else begin
    file_list = kcor_read_calibration_text(date, run.process_basedir, $
                                           exposures=exposures, $
                                           n_files=n_files)
  endelse

  if (n_files lt 1L) then begin
    mg_log, 'missing or empty calibration_files.txt', name='kcor/cal', /warn
    goto, done
  endif

  ; check to make sure exposures are all the same
  unique_exposure_indices = uniq(exposures, sort(exposures))
  if (n_elements(unique_exposure_indices) gt 1L) then begin
    mg_log, 'more than one exposure time in calibration_files.txt', $
            name='kcor/cal', /error
    goto, done
  endif

  ; read the data
  mg_log, 'reading data...', name='kcor/cal', /info
  kcor_reduce_calibration_read, file_list, $
                                filepath('level0', $
                                         subdir=date, $
                                         root=run.raw_basedir), $
                                data=data, metadata=metadata, $
                                run=run

  if (n_elements(data) eq 0L) then begin
    mg_log, 'incomplete cal data, exiting', name='kcor/cal', /info
    goto, done
  endif

  sz = size(data.gain, /dimensions)
  mg_log, 'done reading data', name='kcor/cal', /info

  ; modulation matrix
  mmat = fltarr(sz[0], sz[1], 2, 3, 4)
  dmat = fltarr(sz[0], sz[1], 2, 4, 3)

  ; number of points in the field
  npick = run.npick

  ; fit the calibration data
  for beam = 0, 1 do begin
    mg_log, 'processing beam %d', beam, name='kcor/cal', /info

    ; pick pixels with good signal
    w = where(data.gain[*, *, beam] ge median(data.gain[*, *, beam]) / sqrt(2), nw)
    if (nw lt npick) then begin
      mg_log, 'didn''t find enough pixels with signal: %d', nw, $
              name='kcor/cal', /error
      return
    endif
    pick = sort(randomu(seed, nw))
    pixels = array_indices(data.gain[*, *, beam], w[pick[0:npick - 1]])

    mg_log, 'fitting model to data...', name='kcor/cal', /info
    fits = dblarr(17, npick)
    fiterrors = dblarr(17, npick)
    for i = 0, npick - 1 do begin
      ; setup the LM
      pixel = {x:pixels[0, i], y:pixels[1, i]}
      kcor_reduce_calibration_setup_lm, data, metadata, pixel, beam, parinfo, functargs

      ; run the minimization
      fits[*, i] = mpfit('kcor_reduce_calibration_model', parinfo=parinfo, $
                         functargs=functargs, status=status, errmsg=errmsg, $
                         niter=niter, npegged=npegged, perror=fiterror, /quiet)
      fiterrors[*, i] = fiterror
    endfor

    ; Parameters 8-12 may have gone to equivalent solutions due to periodicity
    ; of the parameter space. We have to remove the ambiguity.
    for i = 9, 12 do begin
      ; guarantee the values are between -2*pi and +2*pi first
      fits[i, *] = fits[i, *] mod (2 * !pi)
      ; find approximately the most likely value
      h = histogram(fits[i, *], locations=l, binsize=0.1 * !pi)
      mlv = l[(where(h eq max(h)))[0]]
      ; center the interval around the mlv
      fits[i, *] += (fix(fits[i, *] lt (mlv - !pi)) $
                       - fix(fits[i, *] gt (mlv + !pi))) * 2 * !pi
    endfor
    mg_log, 'done fitting model', name='kcor/cal', /info

    ; 4th order polynomial fits for all parameters
    ; set up some things
    ; center the pixel values in the image for better numerical stability
    mg_log, 'fitting 4th order polynomials...', name='kcor/cal', /info

    cpixels = pixels - rebin([sz[0], sz[1]] / 2., 2, npick)
    x = (findgen(sz[0]) - sz[0] / 2.) # replicate(1., sz[1])  ; X values at each point
    y = replicate(1., sz[1]) # (findgen(sz[1]) - sz[1] / 2.)  ; Y values at each point
    ; pre-compute the x^i y^j matrices
    degree = 4
    n2 = (degree + 1) * (degree + 2) / 2
    m = sz[0] * sz[1]
    ut = dblarr(n2, m, /nozero)
    j0 = 0L
    for i = 0, degree do begin
      for j = 0, degree - i do $
          ut[j0 + j, 0] = reform(x^i * y^j, 1, m)
      j0 += degree - i + 1
    endfor
    ; create the fit images
    fitimgs = fltarr(sz[0], sz[1], 12)
    for i = 1, 12 do begin
      tmp = sfit([cpixels, fits[i, *]], degree, kx=kx, /irregular, /max_degree)
      fitimgs[*, *, i - 1] = reform(reform(kx, n2) # ut, sz[0], sz[1])
    endfor
    mg_log, 'done fitting 4th order polynomials', name='kcor/cal', /info

    ; populate the modulation matrix
    mg_log,  'calculating mod/demod matrices... ', $
             name='kcor/cal', /info
    mmat[*, *, beam, 0, *] = fitimgs[*, *, 0:3]
    mmat[*, *, beam, 1, *] = fitimgs[*, *, 0:3] $
                               * fitimgs[*, *, 4:7] $
                               * cos(fitimgs[*, *, 8:11])
    mmat[*, *, beam, 2, *] = fitimgs[*, *, 0:3] $
                               * fitimgs[*, *, 4:7] $
                               * sin(fitimgs[*, *, 8:11])
    ; populate the demodulation matrix
    for x = 0, sz[0] - 1 do for y = 0, sz[1] - 1 do begin
      xymmat = reform(mmat[x, y, beam, *, *])
      txymmat = transpose(xymmat)
      dmat[x, y, beam, *, *] = la_invert(txymmat ## xymmat) ## txymmat
    endfor
    mg_log, 'done calculating mod/demod matrices', $
            name='kcor/cal', /info

    ; save pixels, fits, fiterrors
    if (beam eq 0) then begin
      pixels0 = pixels
      fits0 = fits
      fiterrors0 = fiterrors
    endif else if (beam eq 1) then begin
      pixels1 = pixels
      fits1 = fits
      fiterrors1 = fiterrors
    endif
  endfor

  ; write the calibration data
  tokens = strsplit(file_list[0], '_', /extract)
  first_time = tokens[1]
  outfile_basename = string(date, $
                            first_time, $
                            run->epoch('cal_epoch_version'), $
                            kcor_find_code_version(), $
                            float(exposures[0]), $
                            format='(%"%s_%s_kcor_cal_v%s_%s_%0.1fms.ncdf")')
  outfile = filepath(outfile_basename, root=run.cal_out_dir)

  if (~file_test(run.cal_out_dir, /directory)) then file_mkdir, run.cal_out_dir

  kcor_reduce_calibration_write, data, metadata, $
                                 mmat, dmat, outfile, $
                                 pixels0, fits0, fiterrors0, $
                                 pixels1, fits1, fiterrors1, run=run
  mg_log, 'wrote %s', file_basename(outfile), name='kcor/cal', /info

  mg_log, 'done', name='kcor/cal', /info

  done:
  if (run_created) then obj_destroy, run
end


; main-level example program


; set date via command line and .run kcor_reduce_calibration
if (n_elements(date) eq 0L) then date = '20131204'

config_filename = filepath('kcor.iguana.mahi.calibration.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

callist_filename = filepath('callist', subdir=date, root=run.raw_basedir)

if (file_test(callist_filename)) then begin
  n_files = file_lines(callist_filename)
  filelist = strarr(n_files)
  calfile = ''
  openr, lun, callist_filename, /get_lun
  for f = 0L, n_files - 1L do begin
    readf, lun, calfile
    filelist[f] = calfile
  endfor
  free_lun, lun

  kcor_reduce_calibration, date, run=run, filelist=filelist
  obj_destroy, run
endif else begin
  mg_log, 'can''t find callist: %s', callist_filename, /error
endelse

end
