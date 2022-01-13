; docformat = 'rst'

;+
; Identify type of given KCor data file.
;
; :Params:
;   filename : in, required, type=string
;     input KCor level 0 file
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;
; :Author:
;   Sitongia
;-
pro kcor_catalog_file, filename, run=run
  compile_opt strictarr

  process_dir = filepath(run.date, root=run->config('processing/process_basedir'))

  ; read FITS header and read selected keyword parameters
  kcor_read_rawdata, filename, header=header, $
                     repair_routine=run->epoch('repair_routine'), $
                     xshift=run->epoch('xshift_camera'), $
                     start_state=run->epoch('start_state'), $
                     raw_data_prefix=run->epoch('raw_data_prefix'), $
                     datatype=run->epoch('raw_datatype')

  datatype = sxpar(header, 'DATATYPE')
  diffuser = strtrim(sxpar(header, 'DIFFUSER'))
  calpol   = strtrim(sxpar(header, 'CALPOL'))
  calpang  = sxpar(header, 'CALPANG')
  darkshut = strtrim(sxpar(header, 'DARKSHUT'))

  exposure = sxpar(header, 'EXPTIME', count=nrecords)
  if (nrecords eq 0) then exposure = sxpar(header, 'EXPOSURE')
  if (~run->epoch('use_exptime')) then exposure = run->epoch('exptime')

  ; datatype = science
  if (datatype eq 'science') then begin
    openw, science_lun, filepath('science_files.txt', root=process_dir), $
           /append, /get_lun
    printf, science_lun, $
            file_basename(filename), exposure, datatype, darkshut, diffuser, $
            calpol, calpang, $
            format='(a, 3x, f10.4, 2x, "ms", 2x, "Data: ", a, 3x, "Dark: ", a, 3x, "Diff: ", a, 3x, "Cal: ", a, 3x, "Ang: ", f6.1)'

    ; print a measure of every image in the cube
    kcor_read_rawdata, filename, image=image, $
                       repair_routine=run->epoch('repair_routine'), $
                       xshift=run->epoch('xshift_camera'), $
                       start_state=run->epoch('start_state'), $
                       raw_data_prefix=run->epoch('raw_data_prefix'), $
                       datatype=run->epoch('raw_datatype')
    for camera = 0, 1 do begin
      for sequence = 0, 3 do begin
         printf, science_lun, mean(image[*, *, sequence, camera]), $
                 format='(e12.5, "   ", $)'
      endfor
    endfor

    printf, science_lun
    free_lun, science_lun
  endif

  ; datatype = calibration
  if (datatype eq 'calibration') then begin
    start_state = run->epoch('start_state')
    openw, calibration_lun, filepath('calibration_files.txt', root=process_dir), $
           /append, /get_lun
    printf, calibration_lun, $
            file_basename(filename), exposure, start_state, datatype, darkshut, diffuser, $
            calpol, calpang, $
            format='(a, 3x, f10.4, 2x, "ms", 2x, "start state: ", I0.0, x, I0.0, 2x, "Data: ", a, 3x, "Dark: ", a, 3x, "Diff: ", a, 3x, "Cal: ", a, 3x, "Ang: ", f6.1, "  means: ", $)'

    ; print a measure of every image in the cube
    kcor_read_rawdata, filename, image=image, $
                       repair_routine=run->epoch('repair_routine'), $
                       xshift=run->epoch('xshift_camera'), $
                       start_state=start_state, $
                       raw_data_prefix=run->epoch('raw_data_prefix'), $
                       datatype=run->epoch('raw_datatype')
    for camera = 0, 1 do begin
      for sequence = 0, 3 do begin
        printf, calibration_lun, format='(e12.5, "   ", $)', mean(image[*, *, sequence, camera])
      endfor
    endfor

    printf, calibration_lun
    free_lun, calibration_lun
  endif

  ; datatype = engineering
  if (datatype eq "engineering") then begin
    openw, engineering_lun, filepath('engineering_files.txt', root=process_dir), $
           /append, /get_lun
    printf, engineering_lun, $
            file_basename(filename), exposure, datatype, darkshut, diffuser, $
            calpol, calpang, $
            format='(a, 3x, f10.4, 2x, "ms", 2x, "Data: ", a, 3x, "Dark: ", a, 3x, "Diff: ", a, 3x, "Cal: ", a, 3x, "Ang: ", f6.1)'
    free_lun, engineering_lun
  endif

  ; datatype = unknown
  if ((datatype ne 'science') $
        && (datatype ne 'calibration') $
        && (datatype ne 'engineering')) then begin
     openw, unknown_lun, filepath('misc_files.txt', root=process_dir), $
            /append, /get_lun
     printf, unknown_lun, $
             filename, exposure, datatype, darkshut, diffuser, calpol, calpang, $
             format='(a, 3x, f10.4, 2x, "ms", 2x, "Data: ", a, 3x, "Dark: ", a, 3x, "Diff: ", a, 3x, "Cal: ", a, 3x, "Ang: ", f6.1)'
     free_lun, unknown_lun
  endif
end
