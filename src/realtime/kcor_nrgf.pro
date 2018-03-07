; docformat = 'rst'

;+
; Output to annotations to the current direct graphics device.
;-
pro kcor_nrgf_annotations, year, name_month, day, hour, minute, second, doy, $
                           cmin=cmin, cmax=cmax, $
                           top=top, right=right, $
                           charsize=charsize, big_charsize=big_charsize, $
                           annotation_color=annotation_color, $
                           cropped=cropped, averaged=averaged
  compile_opt strictarr

  big_line_height = keyword_set(cropped) ? 18 : 20
  line_height = keyword_set(cropped) ? 15 : 20

  xyouts, 4, top - 34 + keyword_set(cropped) * 12, 'HAO/MLSO/KCor', $
          color=annotation_color, charsize=big_charsize, /device
  xyouts, 4, top - 34 - big_line_height + keyword_set(cropped) * 12, 'K-Coronagraph', $
          color=annotation_color, charsize=big_charsize, /device

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
          string(hour, minute, second, format='(a2, ":", a2, ":", a2, " UT")'), $
          /device, alignment=1.0, charsize=charsize, color=annotation_color

  ; put avg text label below time in standard size, above "circle = photosphere"
  ; in cropped versions
  if (keyword_set(averaged)) then begin
    if (keyword_set(cropped)) then begin
      y = 6 + line_height
      text = '2 min avg'
    endif else begin
      y = top - 29 - line++ * line_height + keyword_set(cropped) * 12
      text = '2 to 3 min avg'
    endelse
    xyouts, right - 6, y, text, $
            /device, alignment=1.0, charsize=charsize, color=annotation_color
  endif

  xyouts, 4, 6 + 2 * line_height, 'Level 1 data', $
          color=annotation_color, charsize=charsize, /device
  xyouts, 4, 6 + line_height, string(cmin, cmax, format='(%"min/max: %4.1f, %4.1f")'), $
          color=annotation_color, charsize=charsize, /device
  xyouts, 4, 6, 'Intensity: normalized, radially-graded', $
          color=annotation_color, charsize=charsize, /device
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
pro kcor_nrgf, fits_file, cropped=cropped, averaged=averaged, daily=daily, $
               run=run, log_name=log_name
  compile_opt strictarr

  ; read L1 FITS image
  img = readfits(fits_file, hdu, /noscale, /silent)

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
  rsun       = sxpar(hdu, 'RSUN')       ; radius of photosphere [arcsec]

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
  occulter_id = sxpar(hdu, 'OCCLTRID')
  occulter = kcor_get_occulter_size(occulter_id, run=run)  ; arcsec

  radius_guess = 178
  if (keyword_set(cropped)) then radius_guess *= scale

  img_info = kcor_find_image(img, radius_guess, log_name=log_name)
  xc   = img_info[0]
  yc   = img_info[1]
  r    = img_info[2]

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
  mg_log, 'rsun     [arcsec]: %0.4f', rsun, name=log_name, /debug
  mg_log, 'occulter [arcsec]: %0.4f', occulter, name=log_name, /debug
  mg_log, 'r_photo  [pixels]: %0.2f', r_photo, name=log_name, /debug
  mg_log, 'rocc     [pixels]: %0.2f', rocc, name=log_name, /debug
  mg_log, 'r0       [pixels]: %0.2f', r0, name=log_name, /debug

  ; compute normalized, radially-graded filter
  for_nrgf, img, xcen, ycen, r0, filtered_image

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
  r_in  = fix(rocc) + 5.0
  r_out = 504.0
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
  device, set_resolution=[out_xdim, out_ydim], decomposed=0, set_colors=256, z_buffering=0
  erase

  ; load color table
  lct, filepath('quallab.lut', root=run.resources_dir)
  tvlct, red, green, blue, /get
  annotation_color = 255

  ; display image and annotate
  tv, bytscl(filtered_image, cmin, cmax, top=249)

  top = keyword_set(cropped) ? out_ydim : 1024
  right = keyword_set(cropped) ? out_xdim : 1024

  big_charsize = keyword_set(cropped) ? 1.25 : 1.5
  charsize = keyword_set(cropped) ? 1.0 : 1.2

  cneg = fix(ycen - r_photo) - keyword_set(cropped) * 4
  cpos = fix(ycen + r_photo) + keyword_set(cropped) * 6

  xyouts, out_xdim / 2, cpos - 24, 'N', $
          alignment=0.5, color=254, charsize=big_charsize, /device
  xyouts, cneg + 12, out_ydim / 2 - 7, 'E', $
          color=254, charsize=big_charsize, /device
  xyouts, out_xdim / 2, cneg + 12, 'S', $
          alignment=0.5, color=254, charsize=big_charsize, /device
  xyouts, cpos - 24, out_ydim / 2 - 7, 'W', $
          color=254, charsize=big_charsize, /device

  ; image has been shifted to center of array
  ; draw circle at photosphere
  kcor_suncir, out_xdim, out_ydim, xcen, ycen, 0, 0, r_photo, 0.0

  if (keyword_set(cropped)) then begin
    save = tvrd()
    alpha = 0.50

    ; lower text boxes
    save[0:259, 0:49] = alpha * save[0:259, 0:49]
    save[out_xdim - 139:*, 0:19] = alpha * save[out_xdim - 139:*, 0:19]

    ; upper text boxes
    save[0:144, out_ydim - 49:out_ydim - 1] = alpha * save[0:144, out_ydim - 49:out_ydim - 1]
    save[out_xdim - 99:*, out_ydim - 54:out_ydim - 1] = alpha * save[out_xdim - 99:*, out_ydim - 54:out_ydim - 1]

    tv, save
  endif

  kcor_nrgf_annotations, year, name_month, day, hour, minute, second, doy, $
                         cmin=cmin, cmax=cmax, $
                         top=top, right=right, $
                         charsize=charsize, big_charsize=big_charsize, $
                         annotation_color=annotation_color, $
                         cropped=cropped, averaged=averaged

  ; create NRGF GIF file
  save = tvrd()
  fts_loc  = strpos(fits_file, '.fts')
  if (keyword_set(averaged)) then begin
    if (keyword_set(daily)) then begin
      fts_loc -= 1 + 3 + 3   ; remove _extavg too
    endif else begin
      fts_loc -= 1 + 3   ; remove _avg too
    endelse
  endif
  gif_file = string(strmid(fits_file, 0, fts_loc), $
                    keyword_set(daily) ? '_extavg' : '', $
                    keyword_set(cropped) ? '_cropped' : '', $
                    format='(%"%s_nrgf%s%s.gif")')

  write_gif, gif_file, save, red, green, blue
  mg_log, 'wrote GIF file %s', file_basename(gif_file), name=log_name, /debug

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
    fxaddpar, rhdu, 'LEVEL', 'L1', $
              ' Level 1'
    if (keyword_set(averaged)) then begin
      fxaddpar, rhdu, 'PRODUCT', 'NRGFAVG', $
                ' Averaged Normalized Radially-Graded Intensity'
    endif else begin
      fxaddpar, rhdu, 'PRODUCT', 'NRGF', $
                ' Normalized Radially-Graded Intensity'
    endelse
    fxaddpar, rhdu, 'BSCALE', bscale, $
              ' Normalized Radially-Graded H.Morgan+S.Fineschi', $
              format='(f10.3)'
    fxaddpar, rhdu, 'DATAMIN', datamin, ' minimum value of  data', $
              format='(f10.3)'
    fxaddpar, rhdu, 'DATAMAX', datamax, ' maximum value of  data', $
              format='(f10.3)'
    fxaddpar, rhdu, 'DISPMIN', dispmin, ' minimum value for display', $
              format='(f10.3)'
    fxaddpar, rhdu, 'DISPMAX', dispmax, ' maximum value for display', $
              format='(f10.3)'
    fxaddpar, rhdu, 'DISPEXP', 1, ' exponent value for display (d=b^dispexp)', $
              format='(f10.3)'

    ; write NRG FITS file
    if (keyword_set(averaged)) then begin
      if (keyword_set(daily)) then begin
        remove_loc = strpos(fits_file, '_extavg.fts')
      endif else begin
        remove_loc = strpos(fits_file, '_avg.fts')
      endelse
    endif else begin
      remove_loc = strpos(fits_file, '.fts')
    endelse
    rfts_file = strmid(fits_file, 0, remove_loc) + '_nrgf.fts'
    rfts_file = string(strmid(fits_file, 0, remove_loc), $
                       keyword_set(daily) ? '_extavg' : '', $
                       format='(%"%s_nrgf%s.fts")')

    writefits, rfts_file, simg, rhdu
    mg_log, 'wrote FITS file %s', file_basename(rfts_file), name=log_name, /info
  endif
end


; main-level example program

f = '20161127_175011_kcor_l1.fts.gz'
run = kcor_run('20161127', $
               config_filename=filepath('kcor.mgalloy.mahi.latest.cfg', $
                                       subdir=['..', '..', 'config'], $
                                       root=mg_src_root()))
kcor_nrgf, f, /cropped, run=run
kcor_nrgf, f, run=run

end
