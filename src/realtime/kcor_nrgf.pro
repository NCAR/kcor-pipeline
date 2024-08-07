; docformat = 'rst'

;+
; Output to annotations to the current direct graphics device.
;-
pro kcor_nrgf_annotations, year, name_month, day, hour, minute, second, doy, $
                           cmin=cmin, cmax=cmax, $
                           top=top, right=right, $
                           charsize=charsize, big_charsize=big_charsize, $
                           annotation_color=annotation_color, $
                           cropped=cropped, $
                           averaged=averaged, daily=daily, to_time=to_time, $
                           is_enhanced=is_enhanced, $
                           enhanced_radius=enhanced_radius, $
                           enhanced_amount=enhanced_amount
  compile_opt strictarr

  big_line_height = keyword_set(cropped) ? 18 : 20
  line_height = keyword_set(cropped) ? 15 : 20

  xyouts, 4, top - 34 + keyword_set(cropped) * 12, 'HAO/MLSO/KCor', $
          color=annotation_color, charsize=big_charsize, /device
  xyouts, 4, top - 34 - big_line_height + keyword_set(cropped) * 12, 'K-Coronagraph', $
          color=annotation_color, charsize=big_charsize, /device
  if (is_enhanced) then begin
    xyouts, 4, top - 34 - 2 * big_line_height + keyword_set(cropped) * 12, $
            'Enhanced Intensity', $
            color=annotation_color, charsize=big_charsize, /device
  endif

  line = 0
  xyouts, right - 6, top - 29 + line++ * line_height + keyword_set(cropped) * 12, $
          string(day, name_month, year, format='(a2, " ", a3, " ", a4)'), $
          /device, alignment=1.0, charsize=charsize, color=annotation_color
  if (~keyword_set(cropped)) then begin
    xyouts, right - 14, top - 29 - line++ * line_height + keyword_set(cropped) * 12, $
            string (format='("DOY ", i3)', doy), $
            /device, alignment=1.0, charsize=charsize, color=annotation_color
  endif
  xyouts, right - 6, top - 29 - line++ * line_height + keyword_set(cropped) * 12, $
          string(hour, minute, second, $
                 (keyword_set(averaged) && ~keyword_set(cropped)) ? ' to' : '', $
                 format='(%"%02d:%02d:%02d UT%s")'), $
          /device, alignment=1.0, charsize=charsize, color=annotation_color

  ; put avg text label below time in standard size, above "circle = photosphere"
  ; in cropped versions
  if (keyword_set(averaged)) then begin
    if (keyword_set(cropped)) then begin
      y = 6 + line_height
    endif else begin
      y = top - 29 - line++ * line_height
    endelse

    if (keyword_set(daily)) then begin
      if (keyword_set(cropped)) then begin
        text = 'Level 2 ~10 min avg'
      endif else begin
        text = string(to_time, format='(%"%s UT")')
      endelse
    endif else begin
      if (keyword_set(cropped)) then begin
        text = 'Level 2 2 min avg'
      endif else begin
        text = string(to_time, format='(%"%s UT")')
      endelse
    endelse

    xyouts, right - 6, y, text, $
            /device, alignment=1.0, charsize=charsize, color=annotation_color
  endif

  annotation_y = 6 + 2 * line_height
  if (is_enhanced) then annotation_y += line_height
  if (~keyword_set(cropped)) then begin
    xyouts, 4, annotation_y, 'Level 2 data', $
            color=annotation_color, charsize=charsize, /device
  endif
  annotation_y -= line_height
  xyouts, 4, annotation_y, string(cmin, cmax, format='(%"min/max: %4.1f, %4.1f")'), $
          color=annotation_color, charsize=charsize, /device
  annotation_y -= line_height
  xyouts, 4, annotation_y, 'Intensity: normalized, radially-graded', $
          color=annotation_color, charsize=charsize, /device
  if (is_enhanced) then begin
    annotation_y -= line_height
      xyouts, 4, annotation_y, $
              string(enhanced_radius, enhanced_amount, $
                     format='Enhanced radius: %0.1f, amount: %0.1f'), $
              color=annotation_color, charsize=charsize, /device
  endif

  xyouts, right - 6, 6, 'circle = photosphere', $
          color=annotation_color, charsize=charsize, /device, alignment=1.0
end


;+
; Apply NRG (normalized, radially-graded) filter to a KCor image. Creates FITS
; and GIF files.
;
; :Params:
;   fits_file : in, required, type=string
;     KCor L1 FITS file
;
; :Keywords:
;   cropped : in, optional, type=boolean
;     set to create a cropped NRGF
;   run : in, required, type=object
;     `kcor_run` object
;   averaged : in, optional, type=boolean
;     set to indicate `fits_file` is an averaged file
;
; :Author:
;   Andrew L. Stanger   HAO/NCAR
;
; :History:
;   14 Apr 2015
;   29 May 2015 Mask image with black in occulter & with R > 504 pixels.
;   15 Jul 2015 Add /NOSCALE keyword to readfits.
;   04 Mar 2016 Generate a 16 bit fits nrgf image in addition to a gif.
;-
pro kcor_nrgf, fits_file, $
               mean_r=mean_r, $
               sdev_r=sdev_r, $
               cropped=cropped, $
               averaged=averaged, $
               daily=daily, $
               run=run, $
               log_name=log_name, $
               fits_filename=fits_filename, $
               enhanced=enhanced
  compile_opt strictarr

  mg_log, '%s', file_basename(fits_file), name=log_name, /debug
  mg_log, 'averaged: %s', keyword_set(averaged) ? 'YES' : 'NO', name=log_name, /debug
  mg_log, 'daily: %s', keyword_set(daily) ? 'YES' : 'NO', name=log_name, /debug
  mg_log, 'cropped: %s', keyword_set(cropped) ? 'YES' : 'NO', name=log_name, /debug
  mg_log, 'enhanced: %s', keyword_set(enhanced) ? 'YES' : 'NO', name=log_name, /debug

  enhanced_radius = run->epoch('enhanced_radius')
  enhanced_amount = run->epoch('enhanced_amount')

  ; read L1 FITS image
  img = readfits(fits_file, hdu, /noscale, /silent)

  if (keyword_set(enhanced)) then begin
    img = kcor_enhanced(img, radius=enhanced_radius, amount=enhanced_amount)
  endif

  if (keyword_set(cropped)) then begin
    xdim     = 768
    ydim     = 768
    out_xdim = 512
    out_ydim = 512
    scale = float(xdim) / 1024.0
    img = congrid(img, xdim, ydim)
  endif else begin
    xdim     = sxpar(hdu, 'NAXIS1')
    ydim     = sxpar(hdu, 'NAXIS2')
    out_xdim = xdim
    out_ydim = ydim
  endelse

  xcen       = xdim / 2.0 - 0.5
  ycen       = ydim / 2.0 - 0.5
  date_obs   = sxpar(hdu, 'DATE-OBS')   ; yyyy-mm-ddThh:mm:ss
  platescale = sxpar(hdu, 'CDELT1')     ; arcsec/pixel
  rsun       = sxpar(hdu, 'RSUN_OBS')   ; radius of photosphere [arcsec]

  ; extract date and time from FITS header
  year   = strmid(date_obs, 0, 4)
  month  = strmid(date_obs, 5, 2)
  day    = strmid(date_obs, 8, 2)
  hour   = strmid(date_obs, 11, 2)
  minute = strmid(date_obs, 14, 2)
  second = strmid(date_obs, 17, 2)

  odate   = strmid(date_obs, 0, 10)   ; yyyy-mm-dd
  otime   = strmid(date_obs, 11, 8)   ; hh:mm:ss

  ; convert month from integer to name of month
  name_month = (['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'])[fix(month) - 1]

  ; determine DOY
  mday      = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
  mday_leap = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]   ; leap year

  if ((fix(year) mod 4) eq 0) then begin
    doy = mday_leap[fix(month) - 1] + fix(day)
  endif else begin
    doy = mday[fix(month) - 1] + fix(day)
  endelse

  ; find size of occulter

  if (run->epoch('use_occulter_id')) then begin
    occulter_id = sxpar(hdu, 'OCCLTRID', count=qoccltrid)
  endif else begin
    occulter_id = run->epoch('occulter_id')
  endelse
  occulter = kcor_get_occulter_size(occulter_id, run=run)  ; arcsec

  radius_guess = 178
  if (keyword_set(cropped)) then radius_guess *= scale

  rocc    = occulter / platescale   ; occulter radius [pixels]
  r_photo = rsun / platescale       ; photosphere radius [pixels]
  r0      = rocc + 2                ; add 2 pixels for inner FOV
  ;r0   = (rsun * 1.05) / platescale

  if (keyword_set(cropped)) then begin
    rocc *= scale
    r_photo *= scale
    r0 *= scale
  endif

  mg_log, 'starting NRGF %s', keyword_set(cropped) ? '(cropped)' : '', $
          name=log_name, /debug

  mg_log, '%s', file_basename(fits_file), name=log_name, /debug

  mg_log, 'rsun     [arcsec]: %0.4f', rsun, name=log_name, /debug
  mg_log, 'occulter [arcsec]: %0.4f', occulter, name=log_name, /debug
  mg_log, 'r_photo  [pixels]: %0.2f', r_photo, name=log_name, /debug
  mg_log, 'rocc     [pixels]: %0.2f', rocc, name=log_name, /debug
  mg_log, 'r0       [pixels]: %0.2f', r0, name=log_name, /debug

  ; compute normalized, radially-graded filter
  filtered_image = mlso_nrgf(img, xcen, ycen, r0, $
                             radius=nrgf_r, mean_r=nrgf_mean_r, sdev_r=nrgf_sdev_r)
  if (run->config('realtime/nrgf_profiles') $
        && keyword_set(averaged) $
        && ~keyword_set(cropped)) then begin
    kcor_nrgf_profile, fits_file, nrgf_r, nrgf_mean_r, nrgf_sdev_r, run=run
  endif

  ; NOTE: FOR_NRGF changes xcen/ycen, so must set them back to the correct
  ; values
  xcen       = xdim / 2.0 - 0.5
  ycen       = ydim / 2.0 - 0.5

  imin = min(filtered_image)
  imax = max(filtered_image)
  ;cmin = imin / 2.0 
  ;cmax = imax / 2.0
  cmin = imin
  cmax = imax

  if (imin lt 0.0) then begin
    amin = abs(imin)
    amax = abs(imax)
    max = amax gt amin ? amax : amin
  endif

  mg_log, 'cmin: %0.3f, cmax: %0.3f', cmin, cmax, name=log_name, /debug

  ; use mask to build gif image

  ; create masking arrays
  xx1  = findgen(xdim, ydim) mod xdim - xcen
  yy1  = transpose(findgen(ydim, xdim) mod ydim) - ycen
  xx1  = double(xx1)
  yy1  = double(yy1)
  rad1 = sqrt(xx1 ^ 2.0 + yy1 ^ 2.0)

  ; set masking limits
  r_in  = fix(rocc) + run->epoch('r_in_offset')
  r_out = run->epoch('r_out')
  if (keyword_set(cropped)) then r_out *= scale

  mg_log, 'masking limits r_in: %0.2f, r_out: %0.2f', $
          r_in, r_out, name=log_name, /debug

  dark = where(rad1 lt r_in or rad1 ge r_out)
  filtered_image[dark] = -10.0   ; set pixels outside annulus to -10

  if (keyword_set(cropped)) then begin
    xcen = out_xdim / 2.0 - 0.5
    ycen = out_ydim / 2.0 - 0.5
    ;filtered_image = filtered_image[128:639, 128:639]
    filtered_image = filtered_image[(xdim - out_xdim) / 2:(xdim + out_xdim) / 2 - 1, $
                                    (xdim - out_xdim) / 2:(xdim + out_xdim) / 2 - 1]
  endif

  ; graphics device
  set_plot, 'Z'
  device, set_resolution=[out_xdim, out_ydim], $
          decomposed=0, $
          set_colors=256, $
          z_buffering=0, $
          set_pixel_depth=8
  erase

  ; load color table: quallab is blue->white for 0..249, and then various colors
  ;lct, filepath('quallab.lut', root=run.resources_dir)
  loadct, 0, /silent
  tvlct, red, green, blue, /get
  annotation_color = 255

  ; display image and annotate
  tv, bytscl(filtered_image, cmin, cmax)

  top = keyword_set(cropped) ? out_ydim : 1024
  right = keyword_set(cropped) ? out_xdim : 1024

  big_charsize = keyword_set(cropped) ? 1.25 : 1.5
  charsize = keyword_set(cropped) ? 1.0 : 1.2

  kcor_add_directions, [xcen, ycen], r_photo, $
                       cropped=cropped, $
                       dimensions=[out_xdim, out_ydim], $
                       charsize=big_charsize, color=254
  ;cneg = fix(ycen - r_photo) - keyword_set(cropped) * 4
  ;cpos = fix(ycen + r_photo) + keyword_set(cropped) * 6

  ;xyouts, out_xdim / 2, cpos - 24, 'N', $
  ;        alignment=0.5, color=254, charsize=big_charsize, /device
  ;xyouts, cneg + 12, out_ydim / 2 - 7, 'E', $
  ;        color=254, charsize=big_charsize, /device
  ;xyouts, out_xdim / 2, cneg + 12, 'S', $
  ;        alignment=0.5, color=254, charsize=big_charsize, /device
  ;xyouts, cpos - 24, out_ydim / 2 - 7, 'W', $
  ;        color=254, charsize=big_charsize, /device

  ; image has been shifted to center of array
  ; draw circle at photosphere
  kcor_suncir, out_xdim, out_ydim, xcen, ycen, 0, 0, r_photo, 0.0, log_name=log_name

  if (keyword_set(cropped)) then begin
    save = tvrd()
    alpha = 0.50

    ; lower text boxes
    top_y = keyword_set(enhanced) gt 0L ? 52 : 37
    save[0:259, 0:top_y] = alpha * save[0:259, 0:top_y]
    save[out_xdim - 165:*, 0:37] = alpha * save[out_xdim - 165:*, 0:37]

    ; upper text boxes
    height = keyword_set(enhanced) ? 67 : 49
    width = keyword_set(enhanced) ? 174 : 144
    save[0:width, out_ydim - height:out_ydim - 1] = alpha * save[0:width, out_ydim - height:out_ydim - 1]
    save[out_xdim - 99:*, out_ydim - 38:out_ydim - 1] = alpha * save[out_xdim - 99:*, out_ydim - 38:out_ydim - 1]

    tv, save
  endif

  date_end = sxpar(hdu, 'DATE-END')
  mg_log, '%s', date_end, name=log_name, /debug
  tokens = strsplit(date_end, 'T', /extract, count=n_tokens)
  to_time = n_tokens gt 1 ? tokens[1] : tokens[0]

  kcor_nrgf_annotations, year, name_month, day, $
                         long(hour), long(minute), long(second), doy, $
                         cmin=cmin, cmax=cmax, $
                         top=top, right=right, $
                         charsize=charsize, big_charsize=big_charsize, $
                         annotation_color=annotation_color, $
                         cropped=cropped, averaged=averaged, daily=daily, $
                         to_time=to_time, $
                         is_enhanced=keyword_set(enhanced), $
                         enhanced_radius=enhanced_radius, $
                         enhanced_amount=enhanced_amount

  ; create NRGF GIF file
  save = tvrd()

  if (keyword_set(averaged)) then begin
    if (keyword_set(daily)) then begin
      remove_loc = strpos(fits_file, '_pb_extavg.fts')
    endif else begin
      remove_loc = strpos(fits_file, '_pb_avg.fts')
    endelse
  endif else begin
    remove_loc = strpos(fits_file, '_pb.fts')
  endelse

  averaging = keyword_set(daily) ? '_extavg' : (keyword_set(averaged) ? '_avg' : '')
  image_size = keyword_set(cropped) ? '_cropped' : ''
  filter = keyword_set(enhanced) ? '_enhanced' : ''
  gif_filename = string(strmid(fits_file, 0, remove_loc), $
                        averaging, image_size, filter, $
                        format='(%"%s_nrgf%s%s%s.gif")')

  write_gif, gif_filename, save, red, green, blue
  mg_log, 'wrote GIF file %s', file_basename(gif_filename), name=log_name, /debug

  if (~keyword_set(cropped)) then begin
    ; create short integer image
    bscale = 0.001
    simg = fix(filtered_image * 1000.0)   ; convert RG image to short integer
    datamin = min(simg) * bscale
    datamax = max(simg) * bscale
    dispmin = cmin
    dispmax = cmax

    ; modify the FITS header for an NRG FITS image
    rhdu = hdu
    fxaddpar, rhdu, 'LEVEL', 'L2', $
              ' Level 2'
    if (keyword_set(averaged)) then begin
      if (keyword_set(daily)) then begin
        if (keyword_set(enhanced)) then begin
          fxaddpar, rhdu, 'PRODUCT', 'enh ext avg NRGF', $
                    ' enhanced, i.e., unsharp mask, ext avg NRGF pB'
        endif else begin
          fxaddpar, rhdu, 'PRODUCT', 'ext avg NRGF', $
                    ' extended averaged NRGF pB'
        endelse
      endif else begin
        if (keyword_set(enhanced)) then begin
          fxaddpar, rhdu, 'PRODUCT', 'enh avg NRGF', $
                    ' enhanced, i.e., unsharp mask, averaged NRGF pB'
        endif else begin
          fxaddpar, rhdu, 'PRODUCT', 'avg NRGF', $
                    ' averaged Normalized Radially Graded Filtered pB'
        endelse
      endelse
    endif else begin
      fxaddpar, rhdu, 'PRODUCT', 'NRGF', $
                ' Normalized Radially-Graded Intensity'
    endelse
    fxaddpar, rhdu, 'BUNIT', 'Normalized Mean Solar Brightness', $
              ' [B/Bsun] units of entire solar disk brightness'
    fxaddpar, rhdu, 'BSCALE', bscale, $
              ' Normalized Radially-Graded H.Morgan+S.Fineschi', $
              format='(f10.3)'
    if (keyword_set(enhanced)) then begin
      fxaddpar, rhdu, 'ENH_RAD', enhanced_radius, $
                ' [px] radius of unsharp mask Gaussian filter', $
                format='(f0.1)', after='BSCALE'
      fxaddpar, rhdu, 'ENH_AMT', enhanced_amount, $
                ' unsharp mask filtering strength', $
                format='(f0.1)', after='ENH_RAD'
    endif

    fxaddpar, rhdu, 'DATAMIN', datamin, ' minimum value of data', $
              format='(f10.3)'
    fxaddpar, rhdu, 'DATAMAX', datamax, ' maximum value of data', $
              format='(f10.3)'
    fxaddpar, rhdu, 'DISPMIN', dispmin, ' minimum value for display', $
              format='(f10.3)'
    fxaddpar, rhdu, 'DISPMAX', dispmax, ' maximum value for display', $
              format='(f10.3)'
    fxaddpar, rhdu, 'DISPEXP', 1, ' exponent value for display (d=b^dispexp)', $
              format='(f10.3)'

    ; write NRGF FITS file
    fits_filename = string(strmid(fits_file, 0, remove_loc), $
                           keyword_set(daily) ? '_extavg' : (keyword_set(averaged) ? '_avg' : ''), $
                           keyword_set(enhanced) ? '_enhanced' : '', $
                           format='%s_nrgf%s%s.fts')

    writefits, fits_filename, simg, rhdu
    mg_log, 'wrote FITS file %s', file_basename(fits_filename), name=log_name, $
            info=keyword_set(averaged) eq 0B, debug=keyword_set(averaged)
  endif
end


; main-level example program

date = '20180423'
run = kcor_run(date, $
               config_filename=filepath('kcor.mgalloy.mahi.latest.cfg', $
                                       subdir=['..', '..', 'config'], $
                                       root=mg_src_root()))

f = filepath('20180423_175443_kcor_l2_extavg.fts.gz', $
             subdir=[date, 'level1'], $
             root=run->config('processing/raw_basedir'))

kcor_nrgf, f, /average, /daily, run=run
kcor_nrgf, f, /average, /daily, /cropped, run=run

f = filepath('20180423_175443_kcor_l2_avg.fts.gz', $
             subdir=[date, 'level1'], $
             root=run->config('processing/raw_basedir'))

kcor_nrgf, f, /average, run=run
kcor_nrgf, f, /average, /cropped, run=run

f = filepath('20180423_175443_kcor_l2.fts.gz', $
             subdir=[date, 'level1'], $
             root=run->config('processing/raw_basedir'))

kcor_nrgf, f, run=run
kcor_nrgf, f, /cropped, run=run

obj_destroy, run

end
