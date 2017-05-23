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
                                  data=data, metadata=metadata, run=run
  compile_opt strictarr

  filenames = filepath(file_list, root=basedir)

  ; this procedure reads in the data for the calibration data reduction

  ; read header of the first file to determine image size etc.
  if (~file_test(filenames[0], /regular)) then filenames[0] += '.gz'
  header = fitshead2struct(headfits(filenames[0]))
  date = (strsplit(header.date_obs, 'T', /extract))[0]
  dark = fltarr(header.naxis1, header.naxis2, 2)
  clear = fltarr(header.naxis1, header.naxis2, 2)
  calibration = fltarr(header.naxis1, header.naxis2, 4, 2, n_elements(file_list))
  angles = fltarr(n_elements(file_list))

  idiff = run->epoch(header.diffsrid)

  ; read files and populate data structure
  gotdark = 0
  gotclear = 0
  gotcal = 0
  vdimref = 0.
  file_types = replicate('unused', n_elements(file_list))
  for f = 0, n_elements(file_list) - 1 do begin
    ; check for zipped file if the FTS file is not present
    if (~file_test(filenames[f], /regular)) then filenames[f] += '.gz'

    thisdata = readfits(filenames[f], header, /silent)

    ; must set time before querying run object
    date_obs = sxpar(header, 'DATE-OBS', count=qdate_obs)
    run.time = date_obs

    kcor_correct_camera, thisdata, header, run=run

    if (run->epoch('remove_horizontal_artifact')) then begin
      mg_log, 'correcting horizontal artifacts at lines: %s', $
              strjoin(strtrim(run->epoch('horizontal_artifact_lines'), 2), ', '), $
              name='kcor/cal', /debug
      kcor_correct_horizontal_artifact, thisdata, run->epoch('horizontal_artifact_lines')
    endif

    darkshut = sxpar(header, 'DARKSHUT', count=n_darkshut)
    diffuser = sxpar(header, 'DIFFUSER', count=n_diffuser)
    calpol = sxpar(header, 'CALPOL', count=n_calpol)
    calpang = sxpar(header, 'CALPANG', count=n_calpang)
    sgsdimv = sxpar(header, 'SGSDIMV', count=n_sgsdimv)

    ; get diffuser intensity from somewhere in 1E-6 B_sun
    
    if strmatch(darkshut, '*in*', /fold_case) then begin
      dark += mean(thisdata, dimension=3)
      gotdark++
      file_types[f] = 'dark'
      mg_log, 'dark: %s', file_list[f], name='kcor/cal', /debug
    endif else if strmatch(diffuser, '*in*', /fold_case) then begin
      if strmatch(calpol, '*out*', /fold_case) then begin
        clear += mean(thisdata, dimension=3)
        vdimref += sgsdimv
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

  data = {dark:dark, gain:gain, calibration:calibration}
  metadata = {angles:angles, $
              idiff:idiff, $
              vdimref:vdimref, $
              date:date, $
              file_list:file_list, $
              file_types:file_types}
end
