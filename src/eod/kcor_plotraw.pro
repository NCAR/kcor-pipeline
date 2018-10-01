; docformat = 'rst'


;+
; Helper function to format y-axis tick marks. Formats them as integers and sets
; every other to an empty string.
;
; :Returns:
;   string
;
; :Params:
;   axis : in, required, type=integer
;     axis number, 0 for x, 1 for y
;   index : in, required, type=integer
;     index of tick mark, i.e, 0, 1, ... yticks
;   value : in, required, type=double
;     value of tick mark
;-
function kcor_plotraw_ytickformat, axis, index, value
  compile_opt strictarr

  return, index mod 2 eq 0 ? string(value, format='(I)') : ''
end


;+
; Plot parameters from raw KCor files corresponding to NRGFs.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   list : in, required, type=strarr
;     list of NRGF files to process
;   run : in, required, type=object
;     `kcor_run` object
;   line_means : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the mean of the pixel values of the
;     corresponding camera/raw file at `im[10:300, 512]`
;   line_medians : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the median of the pixel values of the
;     corresponding camera/raw file at `im[10:300, 512]`
;   azi_means : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the mean of the pixel values of the
;     corresponding camera/raw file at a fixed solar radius 
;   azi_medians : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the median of the pixel values of the
;     corresponding camera/raw file at a fixed solar radius
;-
pro kcor_plotraw, date, list=list, run=run, $
                  line_means=line_means, line_medians=line_medians, $
                  azi_means=azi_means, azi_medians=azi_medians
  compile_opt strictarr

  mg_log, 'starting', name='kcor/eod', /info

  ; get raw filenames
  n_nrgf_files = n_elements(list)
  if (n_nrgf_files eq 0L) then begin
    mg_log, 'no NRGF raw files to plot', name='kcor/eod', /warn
    goto, done
  endif else begin
    mg_log, 'plotting %d NRGF raw files', n_nrgf_files, name='kcor/eod', /info
  endelse

  raw_nrgf_files = strmid(file_basename(list), 0, 20) + '.fts.gz'

  ; create output arrays
  line_means    = fltarr(2, n_nrgf_files)
  line_medians  = fltarr(2, n_nrgf_files)

  azi_means    = fltarr(2, n_nrgf_files)
  azi_medians  = fltarr(2, n_nrgf_files)

  l0_dir   = filepath('level0', subdir=date, root=run.raw_basedir)
  plot_dir = filepath('p', subdir=date, root=run.raw_basedir)
  if (~file_test(plot_dir, /directory)) then file_mkdir, plot_dir

  cd, current=orig_dir
  cd, l0_dir

  y_profile_value = 512

  ; set up plotting environment
  orig_device = !d.name
  set_plot, 'Z'
  device, set_resolution=[772, 1000], decomposed=0, set_colors=256, z_buffering=0
  red   = 255B - bindgen(256)
  green = 255B - bindgen(256)
  blue  = 255B - bindgen(256)
  tvlct, red, green, blue
  !p.multi = [0, 1, 4]

  radius = 1.1   ; in solar radii
  theta_degrees = findgen(360)
  theta = theta_degrees * !dtor

  n_digits = floor(alog10(n_nrgf_files)) + 1L  ; for formatting
  for f = 0L, n_nrgf_files - 1L do begin
    mg_log, '%' + strtrim(n_digits, 2) + 'd/%d: %s', $
            f + 1, n_nrgf_files, file_basename(raw_nrgf_files[f]), $
            name='kcor/eod', /info

    im = readfits(raw_nrgf_files[f], header, /silent)

    bitpix   = fix(sxpar(header, 'BITPIX'))
    if (bitpix gt 16) then begin
      mg_log, 'skipping %d-bit raw image', bitpix, name='kcor/eod', /warn
      continue
    endif

    ; find pixels / solar radius
    date_obs = sxpar(header, 'DATE-OBS', count=qdate_obs)
    year   = long(strmid(date_obs,  0, 4))
    month  = long(strmid(date_obs,  5, 2))
    day    = long(strmid(date_obs,  8, 2))
    hour   = long(strmid(date_obs, 11, 2))
    minute = long(strmid(date_obs, 14, 2))
    second = long(strmid(date_obs, 17, 2))

    fhour = hour + minute / 60.0 + second / 60.0 / 60.0
    mlso_sun, year, month, day, fhour, sd=rsun, pa=pangle, la=bangle

    run.time = date_obs
    sun_pixels = rsun / run->epoch('plate_scale')

    if (run->epoch('use_occulter_id')) then begin
      occltrid = sxpar(header, 'OCCLTRID', count=qoccltrid)
    endif else begin
      occltrid = run->epoch('occulter_id')
    endelse
    occulter = kcor_get_occulter_size(occltrid, run=run)
    radius_guess = occulter / run->epoch('plate_scale')   ; pixels

    for c = 0, 1 do begin
      line_means[c, f] = mean((im[*, y_profile_value, 0, c])[10:300])
      line_medians[c, f] = median((im[*, y_profile_value, 0, c])[10:300])
      mg_log, 'camera %d: line mean: %0.1f, median: %0.1f', $
              c, line_means[c, f], line_medians[c, f], $
              name='kcor/eod', /debug
      plot, reform(im[*, y_profile_value, 0, c]), $
            title=string(y_profile_value, c, $
                         format='(%"Line profile of intensity at y=%d for camera %d")'), $
            charsize=2.0, $
            xticks=8, xtickv=findgen(9) * 128.0, $
            xstyle=1, xtickformat='(I)', xtitle='Raw image x-coordinate', $
            ytickformat='kcor_plotraw_ytickformat', $
            ytitle='Raw pixel value', yrange=[0, 40000], $
            yticks=8, yminor=1, yticklen=1.0, ygridstyle=1
    endfor

    for c = 0, 1 do begin
      info_raw  = kcor_find_image(im[*, *, 0, c], $
                                  radius_guess, /center_guess, log_name='kcor/eod')

      x_0 = info_raw[0]
      y_0 = info_raw[1]

      x = radius * sun_pixels * cos(theta) + x_0
      y = radius * sun_pixels * sin(theta) + y_0

      ; need to get to a 2-dimensional array to index correctly
      spatial_im = reform(im[*, *, 0, c])
      azi_profile = reform(spatial_im[round(x), round(y)])

      azi_means[c, f] = mean(azi_profile)
      azi_medians[c, f] = median(azi_profile)

      mg_log, 'camera %d: azi mean: %0.1f, median: %0.1f', $
              c, azi_means[c, f], azi_medians[c, f], $
              name='kcor/eod', /debug

      plot, theta_degrees, azi_profile, $
            title=string(radius, c, $
                         format='(%"Azimuthal profile of intensity at r=%0.1f solar radius for camera %d")'), $
            charsize=2.0, $
            xticks=8, xtickv=findgen(9) * 45.0, $
            xstyle=1, xtickformat='(I)', xtitle='Angle (degrees)', $
            ytickformat='kcor_plotraw_ytickformat', $
            ystyle=1, yrange=[0, 70000], ytitle='Raw pixel value', $
            yticks=8, yminor=1, yticklen=1.0, ygridstyle=1
    endfor

    plot_image = tvrd()

    file_tokens = strsplit(raw_nrgf_files[f], '_', /extract)
    write_gif, filepath(string(file_tokens[0], file_tokens[1], $
                               format='(%"%s.%s.kcor.profile.gif")'), $
                        root=plot_dir), $
               plot_image, red, green, blue
  endfor

  set_plot, orig_device

  !p.multi = 0
  cd, orig_dir

  done:
  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

date = '20161127'
list = ['20161127_175011_kcor_l1_nrgf.fts.gz', $
        '20161127_175212_kcor_l1_nrgf.fts.gz', $
        '20161127_175413_kcor_l1_nrgf.fts.gz', $
        '20161127_175801_kcor_l1_nrgf.fts.gz']

run = kcor_run(date, $
               config_filename=filepath('kcor.mgalloy.mahi.latest.cfg', $
                                       subdir=['..', '..', 'config'], $
                                       root=mg_src_root()))
kcor_plotraw, date, list=list, run=run
obj_destroy, run

end
