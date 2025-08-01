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
pro kcor_correct_camera, im, header, $
                         xoffset=xoffset, $
                         rcam_cor_filename=rcam_cor_filename, $
                         tcam_cor_filename=tcam_cor_filename, $
                         logger_name=logger_name, $
                         run=run
  compile_opt strictarr

  rcam_cor_filename = ''
  tcam_cor_filename = ''

  ; note: if we decide to change whether we interpolate around some bad pixels,
  ; we will have to clear the camera correction cache directory
  interpolate = run->config('calibration/interpolate_camera_correction')

  im = float(im)

  if (~run->epoch('correct_camera') $
        || ~run->config('calibration/correct_camera')) then begin
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
  if (~run->epoch('use_exptime')) then exposure = run->epoch('exptime')

  ; camera calibration filename format
  fmt = '(%"camera_calibration_%s%s_%07.4f_lut%s.%s")'
  prefix = run->epoch('use_camera_prefix') ? run->epoch('camera_prefix') : ''

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
    rcam_cor_filename = filepath(string(prefix, rcamid, exposure, $
                                        rcam_lut, 'ncdf', $
                                        format=fmt), $
                                 root=run->config('calibration/camera_correction_dir'))
    if (file_test(rcam_cor_filename)) then begin
      mg_log, 'RCAM correction: %s', rcam_cor_filename, name=logger_name, /debug
    endif else begin
      mg_log, '%s not found', rcam_cor_filename, name=logger_name, /error
      rcam_cor_filename = ''
      return
    endelse

    rcam_cor_cache_filename = filepath(string(prefix, rcamid, exposure, $
                                              rcam_lut, 'sav', $
                                              format=fmt), $
                                       subdir='.cache', $
                                       root=run->config('calibration/camera_correction_dir'))

    fp[*, *, *, 0] = kcor_read_camera_correction(rcam_cor_filename, $
                                                 rcam_cor_cache_filename, $
                                                 bad_columns=rbad_columns, $
                                                 n_bad_columns=n_rbad_columns, $
                                                 bad_values=rbad_values, $
                                                 n_bad_values=n_rbad_values, $
                                                 interpolate=interpolate)
    mg_log, 'RCAM fit: %d bad cols, %d bad values', n_rbad_columns, n_rbad_values, $
            name=logger_name, /debug
  endif

  ; correct TCAM

  if (correct_tcam) then begin
    tcam_cor_filename = filepath(string(prefix, tcamid, exposure, $
                                        tcam_lut, 'ncdf', $
                                        format=fmt), $
                                 root=run->config('calibration/camera_correction_dir'))
    if (file_test(tcam_cor_filename)) then begin
      mg_log, 'TCAM correction: %s', tcam_cor_filename, name=logger_name, /debug
    endif else begin
      mg_log, '%s not found', tcam_cor_filename, name=logger_name, /error
      tcam_cor_filename = ''
      return
    endelse

    tcam_cor_cache_filename = filepath(string(prefix, tcamid, exposure, $
                                              tcam_lut, 'sav', $
                                              format=fmt), $
                                       subdir='.cache', $
                                       root=run->config('calibration/camera_correction_dir'))

    fp[*, *, *, 1] = kcor_read_camera_correction(tcam_cor_filename, $
                                                 tcam_cor_cache_filename, $
                                                 bad_columns=tbad_columns, $
                                                 n_bad_columns=n_tbad_columns, $
                                                 bad_values=tbad_values, $
                                                 n_bad_values=n_tbad_values, $
                                                 interpolate=interpolate)
    mg_log, 'TCAM fit: %d bad cols, %d bad values', n_tbad_columns, n_tbad_values, $
            name=logger_name, /debug
  endif


  if (n_elements(xoffset) gt 0L) then fp = shift(fp, xoffset, 0, 0, 0)

  ; scale the data to 0..1
  bitpix = sxpar(header, 'BITPIX')
  numsum = sxpar(header, 'NUMSUM')
  scale = 2L^(bitpix - 9L) * numsum - 1L
  im /= scale

  xshift = run->epoch('xshift_camera_correction')
  camera_indices = where([correct_rcam, correct_tcam], n_cameras_to_correct)
  for p = 0L, n_polstates - 1L do begin
    for c = 0L, n_cameras_to_correct - 1L do begin
      camera = camera_indices[c]
      x = shift(im[*, *, p, camera], xshift[camera], 0)
      ;x = im[*, *, p, camera]
      im[*, *, p, camera] = fp[*, *, 0, camera] $
                              + fp[*, *, 1, camera] * x $
                              + fp[*, *, 2, camera] * x^2 $
                              + fp[*, *, 3, camera] * x^3 $
                              + fp[*, *, 4, camera] * x^4
      im[*, *, p, camera] = shift(im[*, *, p, camera], - xshift[camera], 0)
    endfor
  endfor

  ; return to original scale
  im *= scale
end


; main-level example program

date = '20250324'
config_filename = filepath('kcor.latest.cfg', $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

date_dir   = filepath(date, root=run->config('processing/raw_basedir'))
l0_filename = filepath('20250324_180336_kcor.fts.gz', subdir='level0', root=date_dir)

dt = strmid(file_basename(l0_filename), 0, 15)
run.time = string(strmid(dt, 0, 4), $
                  strmid(dt, 4, 2), $
                  strmid(dt, 6, 2), $
                  strmid(dt, 9, 2), $
                  strmid(dt, 11, 2), $
                  strmid(dt, 13, 2), $
                  format='(%"%s-%s-%sT%s:%s:%s")')

kcor_read_rawdata, l0_filename, image=img, header=header, $
                   repair_routine=run->epoch('repair_routine'), $
                   xshift=run->epoch('xshift_camera'), $
                   start_state=run->epoch('start_state'), $
                   raw_data_prefix=run->epoch('raw_data_prefix'), $
                   datatype=run->epoch('raw_datatype'), $
                   double=0B

kcor_correct_camera, img, header, run=run

obj_destroy, run


;date = '20170409'
;;date = '20170521'
;;date = '20170523'

;run = kcor_run(date, config_filename='../../config/kcor.mgalloy.twilight.caltest.cfg')
;;run_nocamcor = kcor_run(date, config_filename='../../config/kcor.mgalloy.twilight.caltest-nocamcor.cfg')

;;= For 20170409
;;f = '20170410_004543_kcor.fts.gz'   ; dev
;;ok_file = '20170409_171825_kcor.fts.gz'   ; ok
;;dark_file = '20170409_190638_kcor.fts.gz'   ; dark
;;f = '20170409_190941_kcor.fts.gz'   ; cal pol 0.0
;;flat_file = '20170409_190810_kcor.fts.gz'   ; flat


;;= For 20170521
;;ok_file = '20170521_165619_kcor.fts.gz'   ; ok
;;ok_file = '20170521_170208_kcor.fts.gz'   ; ok
;;dark_file = '20170521_183511_kcor.fts.gz'   ; dark
;;flat_file = '20170521_183657_kcor.fts.gz'   ; flat

;ok_files = file_search(filepath('*.fts.gz', subdir=[date, 'level0'], $
;                                root=run->config('processing/raw_basedir')), $
;                       count=n_ok_files)

;camcor_dir = filepath('', subdir=[date, 'camcor'], $
;                      root=run->config('processing/raw_basedir'))
;if (~file_test(camcor_dir, /directory)) then file_mkdir, camcor_dir
;;nocamcor_dir = filepath('', subdir=[date, 'nocamcor'], root=run_nocamcor.raw_basedir)
;;if (~file_test(nocamcor_dir, /directory)) then file_mkdir, nocamcor_dir

;for i = 0L, n_ok_files - 1L do begin
;  ok_file = ok_files[i]

;  print, i + 1, n_ok_files, file_basename(ok_file), format='(%"%d/%d: %s")'

;  im = readfits(ok_file, header, /silent)
;  original_im = float(im)
;  kcor_correct_camera, im, header, run=run, xoffset=0

;  cal_file = filepath(run->epoch('cal_file'), root=run->config('calibration/out_dir'))
;;  cal_file_nocamcor = filepath(run->epoch('cal_file'), root=run_nocamcor.cal_out_dir)

;  ;print, cal_file
;  ;print, cal_file_nocamcor

;  cals = kcor_read_calibration(cal_file)
;;  cals_nocamcor = kcor_read_calibration(cal_file_nocamcor)

;  flat = cals.gain[*, *, *]
;  dark = cals.dark[*, *, *]

;;  flat_nocamcor = cals_nocamcor.gain[*, *, *]
;;  dark_nocamcor = cals_nocamcor.dark[*, *, *]

;  ;flat = readfits(filepath(flat_file, subdir=[date, 'level0'], root=run->config('processing/raw_basedir')), header, /silent)
;  original_flat = float(flat)
;  ;kcor_correct_camera, flat, header, run=run, xoffset=0

;  ;dark = readfits(filepath(dark_file, subdir=[date, 'level0'], root=run->config('processing/raw_basedir')), header, /silent)
;  original_dark = float(dark)
;  ;kcor_correct_camera, dark, header, run=run, xoffset=0

;  ;print, mg_range(im)
;  ;print, mg_range(original_im)

;  camera = 1

;  corona = (im - rebin(reform(dark, 1024, 1024, 1, 2), 1024, 1024, 4, 2) / rebin(reform(flat, 1024, 1024, 1, 2), 1024, 1024, 4, 2))
;;  corona_nocamcor = (original_im - rebin(reform(dark_nocamcor, 1024, 1024, 1, 2), 1024, 1024, 4, 2) / rebin(reform(flat_nocamcor, 1024, 1024, 1, 2), 1024, 1024, 4, 2))

;  pB = sqrt((corona[*, *, 1, camera] - corona[*, *, 2, camera])^2 + (corona[*, *, 0, camera] - corona[*, *, 3, camera])^2)
;;  pB_nocamcor = sqrt((corona_nocamcor[*, *, 1, camera] - corona_nocamcor[*, *, 2, camera])^2 + (corona_nocamcor[*, *, 0, camera] - corona_nocamcor[*, *, 3, camera])^2)

;  y = 512
;  ;device, decomposed=1
;  ;window, xsize=1000, ysize=400, /free, title='I corona'
;  ;plot, corona[*, y, 0, camera], xstyle=9, ystyle=9, yrange=[-1000.0, 20000.0], /nodata

;  ;oplot, corona_nocamcor[*, y, 0, 0], color='aaaaaa'x
;  ;oplot, corona[*, y, 0, camera], color='0000ff'x

;  ;window, xsize=1000, ysize=400, /free, title='Raw'
;  ;plot, original_l1[*, y, 0, 0], xstyle=9, ystyle=9, yrange=[-1000.0, 20000.0], /nodata

;  ;oplot, original_im[*, y, 0, 0], color='aaaaaa'x
;  ;oplot, im[*, y, 0, 0], color='0000ff'x

;  writefits, filepath(file_basename(ok_file, '.fts.gz') + '-camcor.fts', $
;                      root=camcor_dir), $
;             pB, header
;;  writefits, filepath(file_basename(ok_file, '.fts.gz') + '-nocamcor.fts', $
;;                      root=nocamcor_dir), $
;;             pB_nocamcor, header

;  ;window, xsize=1024, ysize=1024, title='pB (with camera correction)', /free
;  ;tv, bytscl(pB, 0.0, 100.0)

;  ;window, xsize=1024, ysize=1024, title='pB (without camera correction)', /free
;  ;tv, bytscl(pB_nocamcor, 0.0, 100.0)
;endfor

;obj_destroy, run

;;obj_destroy, [run, run_nocamcor]

end
