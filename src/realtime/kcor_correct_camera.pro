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
;-
pro kcor_correct_camera, im, header, run=run
  compile_opt strictarr

  dims = size(im, /dimensions)
  n_polstates = dims[2]
  n_cameras = dims[3]

  exposure = sxpar(header, 'EXPTIME')
  tcamid = sxpar(header, 'TCAMID')
  rcamid = sxpar(header, 'RCAMID')

  fp = fltarr(1024, 1024, 5, n_cameras)

  bitpix = sxpar(header, 'BITPIX')
  numsum = sxpar(header, 'NUMSUM')

  im = float(im) / (2^(bitpix - 9) * numsum - 1L)

  rcam_cor_filename = filepath(string(rcamid, exposure, run->epoch('camera_lut_date'), $
                                      format='(%"camera_calibration_%s_%07.4f_lut%s.ncdf")'), $
                               root=run.camera_correction_dir)
  if (~file_test(rcam_cor_filename)) then begin
    mg_log, '%s not found', rcam_cor_filename, name='kcor/rt', /error
    return
  endif
  fp[*, *, *, 0] = kcor_read_camera_correction(rcam_cor_filename)

  tcam_cor_filename = filepath(string(tcamid, exposure, run->epoch('camera_lut_date'), $
                                      format='(%"camera_calibration_%s_%07.4f_lut%s.ncdf")'), $
                               root=run.camera_correction_dir)
  if (~file_test(tcam_cor_filename)) then begin
    mg_log, '%s not found', tcam_cor_filename, name='kcor/rt', /error
    return
  endif
  fp[*, *, *, 1] = kcor_read_camera_correction(tcam_cor_filename)

  for p = 0L, n_polstates - 1L do begin
    for c = 0L, n_cameras - 1L do begin
      x = im[*, *, p, c]
      im[*, *, p, c] = fp[*, *, 0, c] + fp[*, *, 1, c] * x + fp[*, *, 2, c] * x^2 $
                         + fp[*, *, 3, c] * x^3 + fp[*, *, 4, c] * x^4
    endfor
  endfor
end
