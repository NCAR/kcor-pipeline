; docformat = 'rst'

;+
; Corrects nonlinear camera.
;
; :Params:
;   im : in, out, required, type="uint(1024, 1024)"
;     image to correct
;   header : in, required, type=strarr
;     FITS header for `im`
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;   logger_name : in, optional, type=string
;     name of the logger to log to
;-
pro kcor_correct_camera, im, header, run=run, logger_name=logger_name
  compile_opt strictarr

  im = float(im)

  if (~run->epoch('correct_camera')) then begin
    mg_log, 'not performing camera correction', name=logger_name, /debug
    return
  endif

  mg_log, 'performing camera correction', name=logger_name, /debug

  n_dims = size(im, /n_dimensions)
  if (n_dims ne 4) then begin
    mg_log, 'wrong number of dimensions for image: %d', n_dims, $
            name=logger_name, /warn
    return
  endif

  dims = size(im, /dimensions)
  n_polstates = dims[2]
  n_cameras = dims[3]

  ; read the fit paramaters
  fp = fltarr(1024, 1024, 5, n_cameras)

  exposure = sxpar(header, 'EXPTIME')
  tcamid = sxpar(header, 'TCAMID')
  rcamid = sxpar(header, 'RCAMID')

  ; camera calibration filename format
  fmt = '(%"camera_calibration_%s%s_%07.4f_lut%s.ncdf")'
  prefix = run->epoch('use_camera_prefix') ? run->epoch('camera_prefix') : ''

  rcam_cor_filename = filepath(string(prefix, rcamid, exposure, $
                                      run->epoch('camera_lut_date'), $
                                      format=fmt), $
                               root=run.camera_correction_dir)
  if (~file_test(rcam_cor_filename)) then begin
    mg_log, '%s not found', rcam_cor_filename, name=logger_name, /error
    return
  endif
  fp[*, *, *, 0] = kcor_read_camera_correction(rcam_cor_filename)

  tcam_cor_filename = filepath(string(prefix, tcamid, exposure, $
                                      run->epoch('camera_lut_date'), $
                                      format=fmt), $
                               root=run.camera_correction_dir)
  if (~file_test(tcam_cor_filename)) then begin
    mg_log, '%s not found', tcam_cor_filename, name=logger_name, /error
    return
  endif
  fp[*, *, *, 1] = kcor_read_camera_correction(tcam_cor_filename)

  ; scale the data to 0..1
  bitpix = sxpar(header, 'BITPIX')
  numsum = sxpar(header, 'NUMSUM')
  scale = 2L^(bitpix - 9L) * numsum - 1L
  im /= scale

  for p = 0L, n_polstates - 1L do begin
    for c = 0L, n_cameras - 1L do begin
      x = im[*, *, p, c]
      im[*, *, p, c] = fp[*, *, 0, c] + fp[*, *, 1, c] * x + fp[*, *, 2, c] * x^2 $
                         + fp[*, *, 3, c] * x^3 + fp[*, *, 4, c] * x^4
    endfor
  endfor

  ; return to original scale
  im *= scale
end


; main-level example program

date = '20170607'

run = kcor_run(date, config_filename='../../config/kcor.mgalloy.mahi.reprocess-new.cfg')

f = '20170607_192612_kcor.fts'

im = readfits(filepath(f, subdir=[date], root=run.raw_basedir), header, /silent)
original_im = im
kcor_correct_camera, im, header, run=run

mg_image, im[*, *, 0, 0], /new, title='Corrected'
mg_image, original_im[*, *, 0, 0], /new, title='Original'

obj_destroy, run

end
