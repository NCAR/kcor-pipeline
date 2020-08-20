; docformat = 'rst'

;+
; Display quicklook images for both cameras of a raw file.
;
; :Params:
;   pb : in, required, type=fltarr
;     pB array
;   quality : in, required, type=string
;     quality name
;   output_filename : in, required, type=string
;     filename of output quicklook file
;
; :Keywords:
;   minimum : in, optional, type=float, default=-10.0
;     minimum to use for display
;   maximum : in, optional, type=float
;     maximum to use for display, default is maximum of annulus values by camera
;   exponent : in, optional, type=float, default=0.7
;     exponent to use for display
;   gamma : in, optional, type=float, default=0.6
;     gamma to use for display
;   colortable : in, optional, type=integer, default=0
;     colortable number 0-74 as passed to `LOADCT`, default is 0 (black/white)
;   dimensions : in, optional, type=lonarr(2)
;     size of output image, default is the size of the input `pb` image
;-
pro kcor_display_quicklook, pb, quality, output_filename, $
                            minimum=display_minimum, $
                            maximum=display_maximum, $
                            exponent=display_exponent, $
                            gamma=display_gamma, $
                            colortable=colortable, $
                            dimensions=dimensions
  compile_opt strictarr
  on_error, 2

  xsize = 1024L
  ysize = 1024L

  ; read data
  kcor_read_rawdata, l0_filename, image=im, header=header
  im = float(im)

  ; create kcor_run object
  date_obs = sxpar(header, 'DATE-OBS')
  ut_date = kcor_parse_dateobs(date_obs, hst_date=hst_date)
  date = string(hst_date.year, hst_date.month, hst_date.day, $
                format='(%"%04d%02d%02d")')
  config_filename = filepath('kcor.production.cfg', $
                             subdir=['..', 'config'], $
                             root=mg_src_root())
  run = kcor_run(date, config_filename=config_filename)
  run.time = date_obs

  ; set defaults
  _display_minimum = n_elements(display_minimum) eq 0L ? -10.0 : display_minimum
  _display_exponent = n_elements(display_exponent) eq 0L $
                        ? run->epoch('quicklook_gamma') $
                        : display_exponent
  _display_gamma = n_elements(display_gamma) eq 0L $
                     ? run->epoch('quicklook_gamma') $
                     : display_gamma
  _colortable = n_elements(colortable) eq 0L ? 0 : colortable

  ; setup graphics
  device, get_decomposed=original_decomposed
  device, decomposed=0
  loadct, _colortable, ncolors=250, /silent
  gamma_ct, _display_gamma, /current

  ; create "raw" pB image
  q = reform(im[*, *, 0, *] - im[*, *, 3, *])
  u = reform(im[*, *, 1, *] - im[*, *, 2, *])
  pb = sqrt(q * q + u * u)

  maskfile = filepath('kcor_mask.img', $
                      subdir=['..', 'src', 'realtime'], $
                      root=mg_src_root())
  mask = fltarr(xsize, ysize)
  openr, umask, maskfile, /get_lun
  readu, umask, mask
  free_lun, umask

  occltrid = sxpar(header, 'OCCLTRID', count=qoccltrid)
  occulter = kcor_get_occulter_size(occltrid, run=run)
  radius_guess = occulter / run->epoch('plate_scale')   ; occulter size [pixels]

  shifted_mask = bytarr(xsize, ysize, 2)
  xcen = fltarr(2)
  ycen = fltarr(2)
  rdisc_pix = fltarr(2)
  for c = 0, 1 do begin
    center_info = kcor_find_image(im[*, *, 0, c], $
                                  radius_guess, $
                                  /center_guess, $
                                  max_center_difference=run->epoch('max_center_difference'))
    xcen[c] = center_info[0]          ; x offset
    ycen[c] = center_info[1]          ; y offset
    rdisc_pix[c] = center_info[2]     ; radius of occulter [pixels]

    x = rebin(reform(findgen(xsize), xsize, 1), xsize, ysize) - xcen[c]
    y = rebin(reform(findgen(ysize), 1, ysize), xsize, ysize) - ycen[c]
    d = sqrt(x * x + y * y)
    shifted_mask[*, *, c] = d ge (rdisc_pix[c] + 3.0) and d lt 504
  endfor
  pb_masked = pb * shifted_mask

  pb_power = pb_masked ^ _display_exponent

  case n_elements(display_maximum) of
    0: _display_maximum = max(max(pb_power, dimension=1), dimension=1)
    1: _display_maximum = fltarr(2) + display_maximum[0]
    2: _display_maximum = display_maximum
    else: message, 'invalid MAXIMUM'
  endcase

  indent = '  '
  for c = 0, 1 do begin
    window, xsize=xsize, ysize=ysize, /free, title=string(c, format='(%"Camera %d")')
    print, c, format='(%"camera %d:")'
    print, indent, _display_minimum, format='(%"%smin: %0.2f")'
    print, indent, _display_maximum[c], format='(%"%smax: %0.2f")'
    print, indent, _display_exponent, format='(%"%sexp: %0.2f")'
    print, indent, _display_gamma, format='(%"%sgamma: %0.2f")'
    tv, bytscl(pb_power[*, *, c], $
               min=_display_minimum, max=_display_maximum[c], $
               top=249)
  endfor

  ; cleanup
  done:
  if (obj_valid(run)) then obj_destroy, run
  device, decomposed=original_decomposed
end
