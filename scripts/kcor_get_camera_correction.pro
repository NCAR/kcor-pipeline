; docformat = 'rst'

;+
; Record the camera correction files for the day.
;
; Note: need to start on 201301001 since no camera ID/LUT until
; 20190930.084301 HST.
;
; :Params:
;   date : in, required, type=string
;     date in the form YYYYMMDD
;
; :Keywords:
;   config_filename : in, required, type=string
;     config filename
;-
pro kcor_get_camera_correction, date, config_filename=config_filename
  compile_opt strictarr

  mode = 'camcor_filenames'
  run = kcor_run(date, config_filename=config_filename, mode=mode)
  logger_name = 'kcor/' + mode

  ; camera calibration filename format
  fmt = '(%"camera_calibration_%s%s_%07.4f_lut%s.%s")'
  prefix = run->epoch('use_camera_prefix') ? run->epoch('camera_prefix') : ''

  ; get exposure
  raw_files = file_search(filepath('*.fts*', $
                                   subdir=[date, 'level0'], $
                                   root=run->config('processing/raw_basedir')), $
                          count=n_raw_files)
  if (n_raw_files eq 0L) then return

  fits_open, raw_files[0], fcb
  fits_read, fcb, data, header, /header_only
  fits_close, fcb
  exposure = sxpar(header, 'EXPTIME')

  if (run->epoch('use_camera_info')) then begin
    tcamid = sxpar(header, 'TCAMID')
    rcamid = sxpar(header, 'RCAMID')

    rcam_lut = sxpar(header, 'RCAMLUT')
    tokens = strsplit(rcam_lut, '_-', /extract, count=n_tokens)
    if (n_tokens lt 2L) then begin
      mg_log, 'invalid format for RCAMLUT: %s', rcam_lut, name=logger_name, /warn
      correct_rcam = 0B
    endif else begin
      correct_rcam = 1B
      rcam_lut = string(tokens[0], tokens[1], format='(%"%s-%s")')
    endelse

    tcam_lut = sxpar(header, 'TCAMLUT')
    tokens = strsplit(tcam_lut, '_-', /extract, count=n_tokens)
    if (n_tokens lt 2L) then begin
      mg_log, 'invalid format for TCAMLUT: %s', tcam_lut, name=logger_name, /warn
      correct_tcam = 0B
    endif else begin
      correct_tcam = 1B
      tcam_lut = string(tokens[0], tokens[1], format='(%"%s-%s")')
    endelse
  endif else begin
    correct_rcam = 1B
    correct_tcam = 1B
    rcamid = run->epoch('rcamid')
    tcamid = run->epoch('tcamid')
    rcam_lut = run->epoch('rcamlut')
    tcam_lut = run->epoch('tcamlut')
  endelse

  ; correct RCAM
  if (correct_rcam) then begin
    rcam_cor_filename = string(prefix, rcamid, exposure, $
                               rcam_lut, 'ncdf', $
                               format=fmt)
  endif

  ; correct TCAM
  if (correct_tcam) then begin
    tcam_cor_filename = string(prefix, tcamid, exposure, $
                               tcam_lut, 'ncdf', $
                               format=fmt)
  endif

  output_filename = filepath('camera_correction_filenames.txt', $
                             root=run->config('logging/dir'))
  print, output_filename
  openu, lun, output_filename, /get_lun, /append
  printf, lun, $
          strjoin([date, rcam_cor_filename, tcam_cor_filename], ', ')
  free_lun, lun

  obj_destroy, run
end
