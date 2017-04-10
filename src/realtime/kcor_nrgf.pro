; docformat = 'rst'

pro kcor_nrgf_annotations, year, name_month, day, hour, minute, second, doy, $
                           cmin=cmin, cmax=cmax, $
                           top=top, right=right, $
                           charsize=charsize, big_charsize=big_charsize, $
                           annotation_color=annotation_color, $
                           cropped=cropped
  compile_opt strictarr

  xyouts, 4, top - 34 + keyword_set(cropped) * 12, 'HAO/MLSO/Kcor', $
          color=annotation_color, charsize=big_charsize, /device
  xyouts, 4, top - 54 + keyword_set(cropped) * 12, 'K-Coronagraph', $
          color=annotation_color, charsize=big_charsize, /device

  xyouts, right - 6, top - 29 + keyword_set(cropped) * 12, $
          string(format='(a2)', day) + ' '$
            + string(format='(a3)', name_month) +  ' ' $
            + string(format='(a4)', year), $
          /device, alignment=1.0, charsize=charsize, color=annotation_color
  xyouts, right - 14, top - 49 + keyword_set(cropped) * 12, $
          'DOY ' + string (format='(i3)', doy), $
          /device, alignment=1.0, charsize=charsize, color=annotation_color
  xyouts, right - 6, top - 69 + keyword_set(cropped) * 12, $
          string(format='(a2)', hour) + ':' $
            + string(format='(a2)', minute) + ':' $
            + string(format='(a2)', second) + ' UT', $
          /device, alignment=1.0, charsize=charsize, color=annotation_color

  xyouts, 4, 46, 'Level 1 data', color=annotation_color, charsize=charsize, /device
  xyouts, 4, 26, string(cmin, cmax, format='(%"min/max: %4.1f, %4.1f")'), $
          color=annotation_color, charsize=charsize, /device
  xyouts, 4, 6, 'Intensity: normalized, radially-graded', $
          color=annotation_color, charsize=charsize, /device
  xyouts, right - 6, 6, 'circle: photosphere', $
          color=annotation_color, charsize=charsize, /device, alignment=1.0
end

;+
; Apply NRG (normalized, radially-graded) filter to a KCor image. Creates FITS
; and GIF files.
;
; :Params:
;   fits_file : in, required, type=string
;     KCor L1 fits file
;
; :Keywords:
;   cropped : in, optional, type=boolean
;     set to create a cropped NRGF
;   run : in, required, type=object
;     `kcor_run` object
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
pro kcor_nrgf, fits_file, cropped=cropped, run=run
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
  ;   - one occulter has 4 digits; other two have 5
  ;   - only read in 4 digits to avoid confusion
  occulter_id = ''
  occulter_id = sxpar(hdu, 'OCCLTRID')
  occulter    = strmid(occulter_id, 3, 5)
  occulter    = float(occulter)
  if (occulter eq 1018.0) then occulter = 1018.9
  if (occulter eq 1006.0) then occulter = 1006.9

  radius_guess = 178
  if (keyword_set(cropped)) then radius_guess *= scale

  img_info = kcor_find_image(img, radius_guess, log_name='kcor/rt')
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

  mg_log, 'starting NRGF', name='kcor/rt', /info
  mg_log, 'rsun     [arcsec]: %0.4f', rsun, name='kcor/rt', /debug
  mg_log, 'occulter [arcsec]: %0.4f', occulter, name='kcor/rt', /debug
  mg_log, 'r_photo  [pixels]: %0.2f', r_photo, name='kcor/rt', /debug
  mg_log, 'rocc     [pixels]: %0.2f', rocc, name='kcor/rt', /debug
  mg_log, 'r0       [pixels]: %0.2f', r0, name='kcor/rt', /debug

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

  mg_log, 'cmin: %0.3f, cmax: %0.3f', cmin, cmax, name='kcor/rt', /debug

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
          r_in, r_out, name='kcor/rt', /debug

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

  ;xyouts, 512, 1000, 'North', color=255, charsize=1.2, alignment=0.5, $
  ;        /device
  ;xyouts, 22, 512, 'East', color=255, charsize=1.2, alignment=0.5, $
  ;        orientation = 90., /device
  ;xyouts, 1012, 512, 'West', color=255, charsize=1.2, alignment=0.5, $
  ;        orientation = 90., /device
  ;xyouts, 512, 12, 'South', color=255, charsize=1.2, alignment=0.5, $
  ;        /device

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
  ;tvcircle, r_photo, 511.5, 511.5, color=255, /device
  kcor_suncir, out_xdim, out_ydim, xcen, ycen, 0, 0, r_photo, 0.0

  if (keyword_set(cropped)) then begin
    save     = tvrd()
    erase
  endif

  kcor_nrgf_annotations, year, name_month, day, hour, minute, second, doy, $
                         cmin=cmin, cmax=cmax, $
                         top=top, right=right, $
                         charsize=charsize, big_charsize=big_charsize, $
                         annotation_color=annotation_color, $
                         cropped=cropped

  if (keyword_set(cropped)) then begin
    save_annotation = tvrd() gt 0
    annotation_background = dilate(save_annotation, intarr(3, 3) + 1)

    tv, save or 255B * annotation_background
    kcor_nrgf_annotations, year, name_month, day, hour, minute, second, doy, $
                           cmin=cmin, cmax=cmax, $
                           top=top, right=right, $
                           charsize=charsize, big_charsize=big_charsize, $
                           annotation_color=0, $
                           cropped=cropped
  endif

  ; create NRG gif file
  save = tvrd()
  fts_loc  = strpos(fits_file, '.fts')
  gif_file = string(strmid(fits_file, 0, fts_loc), $
                    keyword_set(cropped) ? '_cropped' : '', $
                    format='(%"%s_nrgf%s.gif")')

  write_gif, gif_file, save, red, green, blue
  mg_log, 'wrote GIF file %s', gif_file, name='kcor/rt', /debug

  if (~keyword_set(cropped)) then begin
    ; create short integer image
    bscale = 0.001
    simg = fix(filtered_image * 1000.0)   ; convert RG image to short integer
    datamin = min(simg) * bscale
    datamax = max(simg) * bscale
    dispmin = cmin
    dispmax = cmax

    ; modify the FITS header for an NRG fits image
    rhdu = hdu
    fxaddpar, rhdu, 'LEVEL', 'L1NRGF', $
              ' Level 1 Normalized Radially-Graded Intensity'
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

    ; write NRG fits file
    fts_loc   = strpos(fits_file, '.fts')
    rfts_file = strmid(fits_file, 0, fts_loc) + '_nrgf.fts'

    writefits, rfts_file, simg, rhdu
    mg_log, 'wrote NRGF FITS file %s', rfts_file, name='kcor/rt', /debug
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
