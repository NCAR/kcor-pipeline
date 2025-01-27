; docformat = 'rst'

;+
; Read a calibration FITS file.
;
; :Params:
;   file_list : in, required, type=strarr
;     array of file basenames
;   basedir : in, required, type=string
;     base directory which all files in `file_list` are in
;
; :Keywords:
;   data : out, optional, type=structure
;     structure with dark, gain, and calibration fields
;   metadata : out, optional, type=structure
;     structure with angles, idiff, vdimref, date, file_list, and file_types
;     fields
;   run : in, optional, type=object
;     `kcor_run` object; `config_filename` or `run` is required
;-
pro kcor_reduce_calibration_read, file_list, basedir, $
                                  data=data, metadata=metadata, $
                                  time_length=time_length, $
                                  run=run
  compile_opt strictarr

  filenames = filepath(file_list, root=basedir)

  ; this procedure reads in the data for the calibration data reduction

  ; read header of the first file to determine image size etc.
  if (~file_test(filenames[0], /regular)) then filenames[0] += '.gz'

  mg_log, 'testing %s...', filenames[0], name='kcor/cal', /debug

  kcor_read_rawdata, filenames[0], header=header, $
                     repair_routine=run->epoch('repair_routine'), $
                     xshift=run->epoch('xshift_camera'), $
                     start_state=run->epoch('start_state'), $
                     raw_data_prefix=run->epoch('raw_data_prefix'), $
                     datatype=run->epoch('raw_datatype')
  header = fitshead2struct(header)

  ; set epoch values to the beginning of the calibration
  run.time = header.date_obs

  date = (strsplit(header.date_obs, 'T', /extract))[0]
  dark = fltarr(header.naxis1, header.naxis2, 2)
  clear = fltarr(header.naxis1, header.naxis2, 2)
  calibration = fltarr(header.naxis1, header.naxis2, 4, 2, n_elements(file_list))
  angles = fltarr(n_elements(file_list))

  numsum = header.numsum
  exptime = header.exptime
  if (~run->epoch('use_exptime')) then exptime = run->epoch('exptime')

  idiff = run->epoch(header.diffsrid)

  ; read files and populate data structure
  gotdark  = 0
  gotclear = 0
  gotcal   = 0

  vdimref         = 0.0
  vdimref_sigma   = 0.0
  vdimref_squared = 0.0

  file_types = replicate('unused', n_elements(file_list))
  for f = 0, n_elements(file_list) - 1 do begin
    ; check for zipped file if the FTS file is not present
    if (~file_test(filenames[f], /regular)) then filenames[f] += '.gz'

    dt = strmid(file_basename(filenames[f]), 0, 15)
    run.time = string(strmid(dt, 0, 4), $
                      strmid(dt, 4, 2), $
                      strmid(dt, 6, 2), $
                      strmid(dt, 9, 2), $
                      strmid(dt, 11, 2), $
                      strmid(dt, 13, 2), $
                      format='(%"%s-%s-%sT%s-%s-%s")')
    if (~run->epoch('process') || ~run->epoch('produce_calibration')) then continue
    kcor_read_rawdata, filenames[f], image=thisdata, header=header, $
                       repair_routine=run->epoch('repair_routine'), $
                       xshift=run->epoch('xshift_camera'), $
                       start_state=run->epoch('start_state'), $
                       raw_data_prefix=run->epoch('raw_data_prefix'), $
                       datatype=run->epoch('raw_datatype')

    ; must set time before querying run object
    date_obs = sxpar(header, 'DATE-OBS', count=qdate_obs)
    run.time = date_obs

    ; save info from beginning of calibration sequence
    if (f eq 0) then begin
      original_date_obs = date_obs
      lyotstop = kcor_lyotstop(header, run=run)
    endif

    if (run->epoch('remove_horizontal_artifact')) then begin
      difference_threshold = run->epoch('badlines_diff_threshold')
      kcor_find_badlines, thisdata, $
                          cam0_badlines=cam0_badlines, $
                          cam1_badlines=cam1_badlines, $
                          difference_threshold=difference_threshold
    endif

    kcor_correct_camera, thisdata, header, run=run, logger_name='kcor/cal'

    if (run->epoch('remove_horizontal_artifact')) then begin
      if (n_elements(cam0_badlines) gt 0L) then begin
        mg_log, 'correcting cam 0 bad lines: %s', $
                strjoin(strtrim(cam0_badlines, 2), ', '), $
                name='kcor/cal', /debug
      endif
      if (n_elements(cam1_badlines) gt 0L) then begin
        mg_log, 'correcting cam 1 bad lines: %s', $
                strjoin(strtrim(cam1_badlines, 2), ', '), $
                name='kcor/cal', /debug
      endif

      kcor_correct_horizontal_artifact, thisdata, $
                                        cam0_badlines, $
                                        cam1_badlines
    endif

    occulter_id = strtrim(sxpar(header, 'OCCLTRID', count=n_occulter_id))

    darkshut = strtrim(sxpar(header, 'DARKSHUT', count=n_darkshut))
    diffuser = strtrim(sxpar(header, 'DIFFUSER', count=n_diffuser))
    calpol = strtrim(sxpar(header, 'CALPOL', count=n_calpol))
    calpang = sxpar(header, 'CALPANG', count=n_calpang)
    if (run->epoch('use_sgs')) then begin
      sgsdimv = float(sxpar(header, 'SGSDIMV', count=n_sgsdimv))
    endif else begin
      sgsdimv = kcor_simulate_sgsdimv(date_obs, run=run)
    endelse

    ; NUMSUM for all files must be the same to produce a calibration
    file_numsum = sxpar(header, 'NUMSUM', count=n_numsum)
    if (file_numsum ne numsum) then begin
      mg_log, 'NUMSUM for %s (%d) does not match NUMSUM for %s (%d)', $
              file_list[f], file_numsum, file_list[0], numsum, $
              name='kcor/cal', /error
      return
    endif

    ; EXPTIME for all files must be the same to produce a calibration
    file_exptime = sxpar(header, 'EXPTIME', count=n_exptime)
    if (~run->epoch('use_exptime')) then file_exptime = run->epoch('exptime')

    if (file_exptime ne exptime) then begin
      mg_log, 'EXPTIME for %s (%f) does not match EXPTIME for %s (%f)', $
              file_list[f], file_exptime, file_list[0], exptime, $
              name='kcor/cal', /error
      return
    endif

    ; LYOTSTOP for all files must be the same to produce a calibration
    file_lyotstop = sxpar(header, 'LYOTSTOP', count=n_lyotstop)
    if (n_lyotstop gt 0L) then begin
      if (file_lyotstop ne lyotstop) then begin
        mg_log, 'LYOTSTOP for %s (%s) does not match LYOTSTOP for %s (%s)', $
                file_list[f], file_lyotstop, file_list[0], lyotstop, $
                name='kcor/cal', /error
        return
      endif
    endif

    ; get diffuser intensity from somewhere in 1E-6 B_sun
    
    if strmatch(darkshut, '*in*', /fold_case) then begin
      dark += mean(thisdata, dimension=3)
      gotdark++
      file_types[f] = 'dark'
      mg_log, 'dark: %s', file_list[f], name='kcor/cal', /debug
    endif else if strmatch(diffuser, '*in*', /fold_case) then begin
      if strmatch(calpol, '*out*', /fold_case) then begin
        if (n_elements(flat_date_obs) eq 0L) then flat_date_obs = date_obs
        clear += mean(thisdata, dimension=3)
        vdimref += sgsdimv
        vdimref_squared += sgsdimv * sgsdimv
        gotclear++
        file_types[f] = 'clear'
        mg_log, 'clear: %s', file_list[f], name='kcor/cal', /debug
      endif else begin
        calibration[*, *, *, *, gotcal] = thisdata
        angles[gotcal] = calpang
        gotcal++
        file_types[f] = 'calibration'
        mg_log, 'cal@%5.1f: %s', $
                calpang, file_list[f], name='kcor/cal', /debug
      endelse
    endif
  endfor

  ; check that we have all required data products

  if (gotdark ne 0) then begin
    dark /= float(gotdark)
  endif else begin
    mg_log, 'no dark data found', name='kcor/cal', /error
    return
  endelse

  if (gotclear ne 0) then begin
    ; determine the gain
    gain = (clear / float(gotclear) - dark) / idiff

    ; determine the DIM reference voltage
    vdimref /= float(gotclear)
    vdimref_squared /= float(gotclear)
    vdimref_sigma = sqrt(vdimref_squared - vdimref^2)
  endif else begin
    mg_log, 'no clear data found', name='kcor/cal', /error
    return
  endelse

  if (gotcal ge 4) then begin
    ; resize to the actual number of polarizer positions
    calibration = calibration[*, *, *, *, 0:gotcal - 1]
    angles = angles[0:gotcal - 1]
  endif else begin
    mg_log, 'insufficient calibration positions', name='kcor/cal', /error
    return
  endelse

  last_date_obs = run.time

  ; set time for epochs for the rest of the calibration sequence to be the start
  ; of the calibration sequence
  run.time = original_date_obs

  ; convert HST to UT
  length_jd = last_date_obs->to_julian() + 10.0 / 24.0 - kcor_dateobs2julian(original_date_obs)
  time_length = length_jd * 24.0 * 60.0 * 60.0

  data = {dark:dark, gain:gain, calibration:calibration}
  metadata = {angles: angles, $
              idiff: idiff, $
              flat_date_obs: flat_date_obs, $
              vdimref: vdimref, $
              vdimref_sigma: vdimref_sigma, $
              occulter_id: occulter_id, $
              date: date, $
              file_list: file_list, $
              file_types: file_types, $
              numsum: numsum, $
              exptime: exptime, $
              lyotstop: lyotstop}
end
