; docformat = 'rst'

;+
; Apply RG (normalized, radially-graded) filter to kcor an image list, using a
; cadence of 2 minutes. Create GIF files.
;
; :Params:
;   fits_list : in, required, type=string
;     list file containing KCor L1 fits files
;
; :Author:
;   Andrew L. Stanger   HAO/NCAR
;
; :History:
;   14 Apr 2015
;   20 Apr 2015 input is a list file, instead of a single fits file name.
;   15 May 2015 Adapt from "kcor_nrgfs.pro".  Add 2-minute time cadence logic.
;   26 May 2015 use Joan's modifications to mask the image & cause the
;               occulter region to be black.
;   07 Jul 2015 Add polar grid in occulter region.
;   15 Jul 2015 Add /NOSCALE keyword to readfits.
;   04 Mar 2016 Add fits option.
;-
pro kcor_rg2m, fits_list, fits=fits
  compile_opt strictarr

  tic

  nfiles = 0
  fits_file = ''

  ; file loop
  openr, ulist, fits_list, /get_lun
  while (~eof(ulist)) do begin
    nfiles += 1
    readf, ulist, fits_file 
    fts_loc  = strpos(fits_file, '.fts')
    img      = readfits(fits_file, hdu, /noscale, /silent)

    xdim     = sxpar(hdu, 'NAXIS1')
    ydim     = sxpar(hdu, 'NAXIS2')
    xcen     = (xdim / 2.0) - 0.5
    ycen     = (ydim / 2.0) - 0.5
    date_obs = sxpar (hdu, 'DATE-OBS')   ; yyyy-mm-ddThh:mm:ss

    ; extract date and time from FITS header
    year   = strmid(date_obs, 0, 4)
    month  = strmid(date_obs, 5, 2)
    day    = strmid(date_obs, 8, 2)
    hour   = strmid(date_obs, 11, 2)
    minute = strmid(date_obs, 14, 2)
    second = strmid(date_obs, 17, 2)
    m2     = strmid(date_obs, 15, 1)
    sec    = fix(second)

    ; select the first image every 2 minutes:
    ;   - skip images whose least significant minute digit is odd
    ;   - skip image unless the seconds are <= 15
    if (m2 eq '1' or m2 eq '3' or m2 eq '5' or m2 eq '7' or m2 eq '9') then $
      continue
    if (sec gt 14) then continue
    mg_log, 'sec: %f', sec, name='kcor/rt', /debug

    odate   = strmid(date_obs, 0, 10)   ; yyyy-mm-dd
    otime   = strmid(date_obs, 11, 8)   ; hh:mm:ss

    ; convert month from integer to name of month
    name_month = (['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', $
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'])[fix(month) - 1]

    ; determine DOY
    mday      = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
    mday_leap = [0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335]   ; leap year

    if ((fix(year) mod 4) eq 0) then begin
      doy = (mday_leap[fix(month) - 1] + fix(day))
    endif else begin
      doy = (mday[fix(month) - 1] + fix(day))
    endelse

    rsun = sxpar(hdu, 'RSUN')   ; radius of photosphere

    ; find size of occulter
    ;   - one occulter has 4 digits; other two have 5
    ;   - only read in 4 digits to avoid confusion

    occulter_id = ''
    occulter_id = sxpar(hdu, 'OCCLTRID')
    occulter = strmid(occulter_id, 3, 5)
    occulter = float(occulter)
    if (occulter eq 1018.0) then occulter = 1018.9
    if (occulter eq 1006.0) then occulter = 1006.9

    radius_guess = 178
    img_info = kcor_find_image(img, radius_guess, log_name='kcor/rt')
    xc   = img_info[0]
    yc   = img_info[1]
    r    = img_info[2]
    arcpix = run->epoch('plate_scale')   ; arcsec / pixel = platescale

    rocc    = occulter / arcpix   ; occulter radius [pixels]
    r_photo = rsun / arcpix       ; photosphere radius [pixels]
    r0      = rocc + 2            ; add 2 pixels for inner FOV
    ;r0      = (960.0 * 1.05) / arcpix

    cneg = fix(ycen - r_photo)
    cpos = fix(ycen + r_photo)

    mg_log, 'rsun     [arcsec]: %f', rsun, name='kcor/rt', /debug
    mg_log, 'occulter [arcsec]: %f', occulter, name='kcor/rt', /debug
    mg_log, 'rocc     [pixels]: %f', rocc, name='kcor/rt', /debug
    mg_log, 'r0       [pixels]: %f', r0, name='kcor/rt', /debug

    ; compute normalized, radially-graded filter
    for_nrgf, img, xcen, ycen, r0, imgflt

    imin = min(imgflt)
    imax = max(imgflt)
    cmin = imin / 2.0 
    cmax = imax / 2.0
    cmin = imin
    cmax = imax

    if (imin LT 0.0) then begin
      amin = abs(imin)
      amax = abs(imax)
      max = amax gt amin ? amax : amin
    endif

    mg_log, 'imin: %f, imax: %f', imin, imax, name='kcor/rt', /debug
    mg_log, 'cmin: %f, cmax: %f', cmin, cmax, name='kcor/rt', /debug

    ; use mask to build gif image

    ; set image dimensions
    xsize = long(xdim)
    ysize = long(ydim)
    xx1   = findgen(xsize, ysize) mod xsize - 511.5
    yy1   = transpose (findgen(ysize, xsize) mod ysize) - 511.5
    xx1   = double(xx1)
    yy1   = double(yy1)
    rad1  = sqrt(xx1 ^ 2.0 + yy1 ^ 2.0)

    r_in  = fix(rocc) + 5.0   ; inner radius
    r_out = 504.0             ; outer radius

    dark = where(rad1 lt r_in or rad1 ge r_out)
    imgflt[dark] = -10.0

    ; write RG image to a FITS file
    if (keyword_set(fits)) then begin
      ; create short integer RG image
      bscale = 0.001
      simg = fix(imgflt * 1000.0)   ; convert RG image to short integer
      datamin = min(simg) * bscale
      datamax = max(simg) * bscale
      dispmin = cmin
      dispmax = cmax

      ; modify the FITS header for an NRG fits image
      rhdu = hdu
      fxaddpar, rhdu, 'LEVEL',  'L1NRGF', $
                ' Level 1 Normalized Radially-Graded Intensity'
      fxaddpar, rhdu, 'BSCALE', bscale, $
                ' Normalized Radially-Graded H.Morgan+S.Fineschi',$
                format='(f10.3)'
      fxaddpar, rhdu, 'DATAMIN', datamin, ' minimum value of  data', $
                format='(f10.3)'
      fxaddpar, rhdu, 'DATAMAX', datamax, ' maximum value of  data', $
                format='(f10.3)'
      fxaddpar, rhdu, 'DISPMIN', dispmin, ' minimum value for display', $
                format='(f10.3)'
      fxaddpar, rhdu, 'DISPMAX', dispmax, ' maximum value for display', $
                format='(f10.3)'
      fxaddpar, rhdu, 'DISPEXP', 1, ' exponent value for display (d=b^dispexp)',$
                format='(f10.3)'

      ; write NRG fits file
      fts_loc   = strpos(fits_file, '.fts')
      rfts_file = strmid(fits_file, 0, fts_loc) + '_nrgf.fts'

      mg_log, 'rfts_file: %s', rfts_file, name='kcor/rt', /debug

      writefits, rfts_file, simg, rhdu
    endif

    ; graphics setup
    set_plot, 'Z'
    device, set_resolution = [xdim, ydim], $
            decomposed=0, set_colors=256, z_buffering=0
    erase

    ;set_plot, 'X'
    ;device, decomposed = 1
    ;window, xsize=xdim, ysize=ydim, retain=2

    ; load color table
    lct, filepath('quallab.lut', root=run.resources_dir)   ; color table
    tvlct, red, green, blue, /get

    ; display image and annotate
    tv, bytscl(imgflt, cmin, cmax, top=249)

    xyouts, 4, 990, 'HAO/MLSO', color=255, charsize=1.5, /device
    xyouts, 4, 970, 'K-Coronagraph', color=255, charsize=1.5, /device

    ; xyouts, 512, 1000, 'North', color=255, charsize=1.2, alignment=0.5, $
    ;         /device
    ; xyouts, 22, 512, 'East', color=255, charsize=1.2, alignment=0.5, $
    ;         orientation=90., /device
    ; xyouts, 512, 12, 'South', color=255, charsize=1.2, alignment=0.5, $
    ;         /device
    ; xyouts, 1012, 512, 'West', color=255, charsize=1.2, alignment=0.5, $
    ;         orientation=90., /device

    xyouts, 505, cpos - 24, 'N', color=254, charsize=1.5, /device
    xyouts, cneg + 12, 505, 'E', color=254, charsize=1.5, /device
    xyouts, 506, cneg + 12, 'S', color=254, charsize=1.5, /device
    xyouts, cpos - 24, 505, 'W', color=254, charsize=1.5, /device

    xyouts, 1018, 995, string(format='(a2)', day) + ' ' + $
                       string(format='(a3)', name_month) +  ' ' + $
                       string(format='(a4)', year), /device, alignment = 1.0,$
                       charsize=1.2, color=255
    xyouts, 1010, 975, 'DOY ' + string (format='(i3)', doy), /device, $
                       alignment=1.0, charsize=1.2, color=255
    xyouts, 1018, 955, string(format='(a2)', hour) + ':' + $
                       string(format='(a2)', minute) + ':' + $
                       string(format='(a2)', second) + ' UT', /device, $
                       alignment=1.0, charsize=1.2, color=255

    xyouts, 4, 46, 'Level 1 data', color=255, charsize=1.2, /device
    xyouts, 4, 26, 'min/max: ' + string(format='(f4.1)', cmin) + ', ' $
                               + string(format='(f4.1)', cmax), $
                   color=255, charsize=1.2, /device
    xyouts, 4, 6, 'Intensity: normalized, radially-graded filter', $
                  color=255, charsize=1.2, /device
    xyouts, 1018, 6, 'circle: photosphere.', $
                     color=255, charsize=1.2, /device, alignment=1.0

    ; image has been shifted to center of array
    ; draw circle at photosphere

    ; tvcircle, r_photo, 511.5, 511.5, color=255, /device
    kcor_suncir, xdim, ydim, xcen, ycen, 0, 0, r_photo, 0.0

    ; save displayed image into a GIF file
    save     = tvrd()
    gif_file = strmid(fits_file, 0, fts_loc) + '_nrgf.gif'

    mg_log, 'gif_file: %s', gif_file, name='kcor/rt', /debug

    write_gif, gif_file, save, red, green, blue
  endwhile   ; end of file loop

  free_lun, ulist

  total_time = toc()
  loop_time  = total_time / nfiles
  mg_log, 'loop time: %0.1f sec/file, total time: %0.1f sec', $
          loop_time, total_time, $
          name='kcor/rt', /info
end
