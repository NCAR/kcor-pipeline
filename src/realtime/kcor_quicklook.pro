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
pro kcor_quicklook, pb, mask, $
                    quality, output_filename, $
                    l0_basename=l0_basename, $
                    camera=camera, $
                    xcenter=xcenter, ycenter=ycenter, radius=radius, $
                    solar_radius=solar_radius, $
                    axcenter=axcenter, aycenter=aycenter, $
                    occulter_radius=occulter_radius, $
                    pangle=pangle, $
                    minimum=display_minimum, $
                    maximum=display_maximum, $
                    exponent=display_exponent, $
                    gamma=display_gamma, $
                    colortable=colortable, $
                    dimensions=display_dimensions
  compile_opt strictarr
  on_error, 2

  original_device = !d.name
  set_plot, 'Z'

  mg_log, 'display_dimensions: [%s]', strjoin(strtrim(display_dimensions, 2), ', '), $
          name='kcor/rt', /debug

  device, get_decomposed=original_decomposed
  device, set_resolution=display_dimensions
  device, decomposed=0, $
          set_colors=256, $
          z_buffering=0

  tvlct, original_rgb, /get
  loadct, colortable, ncolors=250, /silent
  gamma_ct, display_gamma, /current

  ; define color levels for annotation
  yellow = 250
  tvlct, 255, 255, 0, yellow

  grey   = 251
  tvlct, 127, 127, 127, grey

  blue   = 252
  tvlct, 0, 0, 255, blue

  green  = 253
  tvlct, 0, 255, 0, green

  red    = 254
  tvlct, 255, 0, 0, red

  white  = 255
  tvlct, 255, 255, 255, white

  tvlct, rlut, glut, blut, /get

  mg_log, 'camera %d', camera, name='kcor/rt', /debug
  help, pb, output=help_output
  mg_log, 'pb: %s', help_output, name='kcor/rt', /debug
  mg_log, 'radius: %0.1f', radius, name='kcor/rt', /debug
  mg_log, 'solar_radius: %0.1f', solar_radius, name='kcor/rt', /debug
  mg_log, 'occulter_radius: %0.1f', occulter_radius, name='kcor/rt', /debug

  ; resize if needed
  pb_dimensions = size(pb, /dimensions)
  if (~array_equal(pb_dimensions, display_dimensions)) then begin
    ; TODO: use FREBIN?
    resized_pb = congrid(pb, display_dimensions[0], display_dimensions[1])
    resized_mask = byte(round(congrid(mask, display_dimensions[0], display_dimensions[1])))
    help, resized_pb, output=resized_pb_output
    mg_log, 'resized_pb: %s', resized_pb_output, name='kcor/rt', /debug
    scale_factors = float(display_dimensions) / float(pb_dimensions)
  endif else begin
    resized_pb = pb
    resized_mask = mask
    scale_factors = fltarr(2) + 1.0
  endelse

  scaled_xcenter = scale_factors[0] * xcenter
  scaled_ycenter = scale_factors[1] * ycenter
  scaled_radius = mean(scale_factors) * radius
  scaled_solar_radius = mean(scale_factors) * solar_radius
  scaled_occulter_radius = mean(scale_factors) * occulter_radius
  scaled_axcenter = scale_factors[0] * axcenter
  scaled_aycenter = scale_factors[1] * aycenter

  mg_log, 'scaled_radius: %0.1f', scaled_radius, name='kcor/rt', /debug
  mg_log, 'scaled_solar_radius: %0.1f', scaled_solar_radius, name='kcor/rt', /debug
  mg_log, 'scaled_occulter_radius: %0.1f', scaled_occulter_radius, name='kcor/rt', /debug

  power_pb = resized_pb ^ display_exponent
  _display_maximum = n_elements(display_maximum) eq 0L $
                       ? max(pb ^ display_exponent) $
                       : display_maximum
  display_pb = bytscl(power_pb, $
                      min=display_minimum, $
                      max=_display_maximum, $
                      top=249)
  display_pb *= resized_mask

  tv, display_pb

  if (quality ne 'calibration' and quality ne 'device obscuration' and quality ne 'saturated') then begin
    mg_log, 'not calibration, device, or saturated', name='kcor/rt', /debug
    mg_log, 'scaled_xcenter: %0.1f, scaled_ycenter: %0.1f', scaled_xcenter, scaled_ycenter, $
            name='kcor/rt', /debug
    mg_log, 'scaled_radius: %0.1f', scaled_radius, $
            name='kcor/rt', /debug
    mg_log, 'yellow: %d', yellow, name='kcor/rt', /debug
    ; occulter disc
    tvcircle, scaled_occulter_radius, $
              scaled_xcenter, $
              scaled_ycenter, $
              grey, /device, /fill   
    ; 1.0 Rsun circle
    tvcircle, scaled_solar_radius, $
              scaled_xcenter, $
              scaled_ycenter, $
              yellow, /device
    ; 3.0 Rsun circle
    tvcircle, 3.0 * scaled_solar_radius, $
              scaled_xcenter, $
              scaled_ycenter, $
              grey, /device

    ; draw "+" at sun center
    plots, scaled_axcenter + [- 5, 5], $
           scaled_aycenter + fltarr(2), $
           color=green, /device
    plots, scaled_axcenter + fltarr(2), $
           scaled_aycenter + [- 5, 5], $
           color=green, /device

    north_r = mean(scale_factors) * 498.5
    north_angle = 90.0 + pangle

    ; camera 1 is flipped vertically
    if (camera eq 1) then north_angle *= -1

    north_x = north_r * cos(north_angle * !dtor) + scaled_xcenter
    north_y = north_r * sin(north_angle * !dtor) + scaled_ycenter

    north_orientation = north_angle - 90.0
    north_angle mod= 360.0
    if ((north_angle lt 0.0 && north_angle gt -180.0) $
        || (north_angle gt 180.0)) then begin
      north_orientation += 180.0
    endif
    xyouts, north_x, north_y, string(pangle - 180.0, $
                                     format='(%"NORTH (p-angle: %0.1f)")'), $
            color=green, charsize=1.0, /device, $
            alignment=0.5, orientation=north_orientation
  endif

  ; extra annotation for other quality types
  case quality of
    'saturated': tvcircle, scaled_radius, scaled_xcenter, scaled_ycenter, blue, /device
    'bright': tvcircle, scaled_radius, scaled_xcenter, scaled_ycenter, red, /device
    'dim': tvcircle, scaled_radius, scaled_xcenter, scaled_ycenter, green, /device
    'cloudy': tvcircle, scaled_radius, scaled_xcenter, scaled_ycenter, green,  /device
    'noisy': tvcircle, scaled_radius, scaled_xcenter, scaled_ycenter, yellow, /device
    else:
  endcase

  ; common annotations
  xyouts, 6, display_dimensions[1] - 20, file_basename(output_filename), $
          color=white, charsize=1.0, /device
  xyouts, 6, 30, string(display_minimum, _display_maximum, format='(%"min/max: %0.1f, %0.1f")'), $
          color=white, charsize=1.0, /device
  xyouts, 6, 13, string(display_exponent, display_gamma, $
                        format='(%"scaling: pb ^ %0.1f, gamma=%0.1f")'), $
          color=white, charsize=1.0, /device
  xyouts, display_dimensions[0] - 6, display_dimensions[1] - 20, quality, $
          color=white, charsize=1.0, /device, alignment=1.0

  save = tvrd()
  help, save, output=save_output
  mg_log, 'save: %s', strjoin(save_output, ' '), name='kcor/rt', /debug
  write_gif, output_filename, save, rlut, glut, blut

  ; cleanup
  done:
  tvlct, original_rgb
  device, decomposed=original_decomposed
  set_plot, original_device
end
