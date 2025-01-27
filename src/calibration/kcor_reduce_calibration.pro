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
;   catalog_dir : in, optional, type=string
;     if present, subdir of date directory that contains files from `FILELIST`
;   filelist : in, optional, type=strarr
;     list of L0 FITS files to use for the calibration if present, otherwise
;     reads the `calibration_files.txt` file in the process directory
;   config_filename : in, optional, type=string
;     filename of configuration file; `config_filename` or `run` is required
;   cal_filename : out, optional, type=string
;     set to a named variable to retrieve the filename of the cal file produced
;   status : out, optional, type=long
;     set to a named variable to retrieve the status of the calibration
;     calculation: 0 for success, 1 for incomplete data, 2 for error, 3 bad
;     start_state
;   start_state : out, optional, type=lonarr(2)
;     set to a named variable to retrieve the recommended start_state, should
;     be [0, 0] for good data
;   run : in, optional, type=object
;     `kcor_run` object; `config_filename` or `run` is required
;-
pro kcor_reduce_calibration, date, $
                             catalog_dir=catalog_dir, $
                             filelist=filelist, $
                             config_filename=config_filename, $
                             cal_filename=outfile, $
                             status=status, $
                             start_state=start_state, $
                             run=run
  common kcor_random, seed

  status = 0

  run_created = ~obj_valid(run)
  if (run_created) then begin
    run = kcor_run(date, config_filename=config_filename)
  endif

  _catalog_dir = n_elements(catalog_dir) eq 0L $
                   ? filepath('level0', subdir=date, $
                              root=run->config('processing/raw_basedir')) $
                   : catalog_dir

  if (n_elements(filelist) gt 0L) then begin
    mg_log, 'constructing list of calibration files...', name='kcor/cal', /debug
    n_files = n_elements(filelist)
    file_list = filelist
    exposures = strarr(n_files)

    cd, current=current_dir
    cd, filepath('level0', subdir=date, root=run->config('processing/raw_basedir'))

    ; extract exposures from files
    for f = 0L, n_files - 1L do begin
      kcor_read_rawdata, filelist[f], header=hdu, $
                         repair_routine=run->epoch('repair_routine'), $
                         errmsg=errmsg, $
                         xshift=run->epoch('xshift_camera'), $
                         start_state=run->epoch('start_state'), $
                         raw_data_prefix=run->epoch('raw_data_prefix'), $
                         datatype=run->epoch('raw_datatype')
      if (errmsg ne '') then begin
        mg_log, 'error reading %s', filelist[f], name='kcor/cal', /error
        mg_log, errmsg, name='kcor/cal', /error
        status = 2
        goto, done
      endif

      exposure = sxpar(header, 'EXPTIME', count=nrecords)
      if (nrecords eq 0) then exposure = sxpar(header, 'EXPOSURE')
      if (~run->epoch('use_exptime')) then exposure = run->epoch('exptime')

      exposures[f] = string(exposure, format='(f10.4)')
    endfor

    cd, current_dir
  endif else begin
    mg_log, 'reading calibration files list...', name='kcor/cal', /debug
    file_list = kcor_read_calibration_text(date, $
                                           run->config('processing/process_basedir'), $
                                           exposures=exposures, $
                                           n_files=n_files, run=run)
  endelse

  if (n_files lt 1L) then begin
    mg_log, 'no OK calibration files', name='kcor/cal', /warn
    status = 1
    goto, done
  endif

  ; check to make sure exposures are all the same
  unique_exposure_indices = uniq(exposures, sort(exposures))
  if (n_elements(unique_exposure_indices) gt 1L) then begin
    mg_log, 'more than one exposure time in calibration_files.txt', $
            name='kcor/cal', /error
    status = 2
    goto, done
  endif

  ; read the data
  mg_log, 'reading data (%d files)...', n_elements(file_list), name='kcor/cal', /info
  kcor_reduce_calibration_read, file_list, _catalog_dir, $
                                data=data, metadata=metadata, $
                                time_length=time_length, $
                                run=run

  if (n_elements(data) eq 0L) then begin
    mg_log, 'incomplete cal data, exiting', name='kcor/cal', /error
    status = 1
    goto, done
  endif

  ; produce error if time between first and last cal file is greater than
  ; threshold
  cal_maxtime = run->epoch('cal_maxtime')   ; seconds
  if (time_length gt cal_maxtime) then begin
    mg_log, 'cal sequence too long (%0.1f minutes)', time_length / 60.0, $
            name='kcor/cal', /error
    status = 2
    goto, done
  endif else begin
    mg_log, 'cal sequence: %0.1f min', time_length / 60.0, name='kcor/cal', /info
  endelse

  ; check polarization state sequence on 0 deg (180 deg is equivalent to 0 deg)
  ; calibration image
  zero_indices = where(abs(metadata.angles mod 180.0) lt 0.1, n_zero_degree)
  if (n_zero_degree gt 0L) then begin
    for i = 0L, n_zero_degree - 1L do begin
      test_image = data.calibration[*, *, *, *, zero_indices[i]]
      valid = kcor_check_calibration(test_image, start_state=start_state)
      if (~valid) then begin
        mg_log, 'bad polarization start state', name='kcor/cal', /error
        mg_log, 'recommended start_state: [%d, %d]', $
                start_state[0], start_state[1], name='kcor/cal', /error
        status = 3
        goto, done
      endif else begin
        mg_log, 'valid start state for %d/%d', i + 1, n_zero_degree, $
                name='kcor/cal', /debug
      endelse
    endfor
  endif else begin
    mg_log, 'no 0 degree calibration data, exiting', name='kcor/cal', /error
    status = 1
    goto, done
  endelse

  ; check for a complete set of angles, need 4 angles differing by 45 degrees:
  ; 0 (or 180), 45, 90, and 135, and optionally 22.5, 67.5, 112.5, and 157.5
  required_angles = [0.0, 45.0, 90.0, 135.0]
  if (~kcor_check_angles(required_angles, $
                         required_angles + 22.5, $
                         metadata.angles, $
                         mask=angle_mask, $
                         logger_name='kcor/cal')) then begin
    mg_log, 'required angles for full calibration data set not present', $
            name='kcor/cal', /error
    status = 1
    goto, done
  endif

  ; filter observations by those cal observations with valid angles
  valid_angle_indices = where(angle_mask, /null)

  ; also make sure the correct files are listed as used in the netCDF
  ; calibration file
  cal_indices = where(metadata.file_types eq 'calibration', $
                      complement=non_cal_indices, $
                      /null)
  valid_angle_cal_indices = cal_indices[valid_angle_indices]
  valid_indices = mg_setunion(non_cal_indices, valid_angle_cal_indices)

  ; recreate variables with filtered subset
  data = {dark :         data.dark, $
          gain :         data.gain, $
          calibration : (data.calibration)[*, *, *, *, valid_angle_indices]}
  metadata = {angles :        (metadata.angles)[valid_angle_indices], $
              idiff :         metadata.idiff, $
              flat_date_obs : metadata.flat_date_obs, $
              vdimref :       metadata.vdimref, $
              vdimref_sigma : metadata.vdimref_sigma, $
              occulter_id :   metadata.occulter_id, $
              date :          metadata.date, $
              file_list :     (metadata.file_list)[valid_indices], $
              file_types :    (metadata.file_types)[valid_indices], $
              numsum :        metadata.numsum, $
              exptime :       metadata.exptime, $
              lyotstop :      metadata.lyotstop}

  sz = size(data.gain, /dimensions)
  mg_log, 'done reading data', name='kcor/cal', /info

  ; modulation matrix
  mmat = fltarr(sz[0], sz[1], 2, 3, 4)
  dmat = fltarr(sz[0], sz[1], 2, 4, 3)

  ; number of points in the field
  npick = run->config('calibration/npick')
  mg_log, 'sampling %d points', npick, name='kcor/cal', /info

  ; fit the calibration data
  for beam = 0, 1 do begin
    mg_log, 'processing beam %d', beam, name='kcor/cal', /info

    ; pick pixels with good signal
    w = where(data.gain[*, *, beam] ge median(data.gain[*, *, beam]) / sqrt(2), nw)
    if (nw lt npick) then begin
      mg_log, 'didn''t find enough pixels with signal: %d', nw, $
              name='kcor/cal', /error
      status = 2
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
                         functargs=functargs, status=fit_status, errmsg=errmsg, $
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
  first_date = tokens[0]
  first_time = tokens[1]
  outfile_basename = string(first_date, $
                            first_time, $
                            run->epoch('cal_epoch_version'), $
                            kcor_find_code_version(), $
                            float(exposures[0]), $
                            format='(%"%s_%s_kcor_cal_v%s_%s_%0.3fms.ncdf")')
  outfile = filepath(outfile_basename, root=run->config('calibration/out_dir'))

  if (~file_test(run->config('calibration/out_dir'), /directory)) then begin
    file_mkdir, run->config('calibration/out_dir')
  endif

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

callist_filename = filepath('callist', subdir=date, $
                            root=run->config('processing/raw_basedir'))

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
