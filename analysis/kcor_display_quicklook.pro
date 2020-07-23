; docformat = 'rst'

pro kcor_display_quicklook, l0_filename, $
                            minimum=display_minimum, $
                            maximum=display_maximum, $
                            exponent=display_exponent, $
                            gamma=display_gamma
  compile_opt strictarr
  on_error, 2

  ; set defaults
  _display_minimum = n_elements(display_minimum) eq 0L ? -10.0 : display_minimum
  _display_exponent = n_elements(display_exponent) eq 0L ? 0.7 : display_exponent
  _display_gamma = n_elements(display_gamma) eq 0L ? 0.6 : display_gamma

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

  ; create "raw" pB image
  q = reform(im[*, *, 0, *] - im[*, *, 3, *])
  u = reform(im[*, *, 1, *] - im[*, *, 2, *])
  pb = sqrt(q * q + u * u)

  case n_elements(display_maximum) of
    0: _display_maximum = max(max(pb, dimension=1), dimension=1)
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
    tv, bytscl(pb[*, *, c] ^ _display_exponent, $
               min=_display_minimum, $
               max=_display_maximum[c])
  endfor

  ; cleanup
  done:
  if (obj_valid(run)) then obj_destroy, run
end
