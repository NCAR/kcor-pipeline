; docformat = 'rst'

;+
; Create a synoptic plot for the last 28 days.
; 
; :Keywords:
;   database : in, required, type=object
;     database connection
;   run : in, required, type=object]
;     KCor run object
;-
pro kcor_rolling_synoptic_map, database=db, run=run, enhanced=enhanced
  compile_opt strictarr

  n_days = 28L   ; number of days to include in the plot
  n_angles = 720L

  logger_name = run.logger_name

  heights = run->epoch('synoptic_heights')
  height_names = run->epoch('synoptic_height_names')
  min_values = run->epoch('synoptic_display_minimums') * 1.0e-6
  max_values = run->epoch('synoptic_display_maximums') * 1.0e-6

  if (keyword_set(enhanced)) then height_names = 'enhanced_' + height_names

  ; query database for data
  end_date_tokens = long(kcor_decompose_date(run.date))
  end_date = string(end_date_tokens, format='(%"%04d-%02d-%02d")')
  end_date_jd = julday(end_date_tokens[1], $
                       end_date_tokens[2], $
                       end_date_tokens[0], $
                       0, 0, 0) + 1
  start_date_jd = end_date_jd - n_days
  start_date = string(start_date_jd, $
                      format='(C(CYI4.4, "-", CMoI2.2, "-", CDI2.2))')

  ; ephemeris data
  mid_jd = (end_date_jd + start_date_jd) / 2.0
  caldat, mid_jd, mid_month, mid_day, mid_year
  sun, mid_year, mid_month, mid_day, 0.0, sd=radsun, dist=dist_au, lat0=mid_bangle

  caldat, end_date_jd, end_month, end_day, end_year
  sun, end_year, end_month, end_day, 0.0, sd=radsun_end, lat0=end_bangle

  caldat, start_date_jd, start_month, start_day, start_year
  sun, start_year, start_month, start_day, 0.0, sd=radsun_start, lat0=start_bangle

  query = 'select kcor_sci.*, mlso_numfiles.obs_day as mlso_obs_day from kcor_sci, mlso_numfiles where kcor_sci.obs_day=mlso_numfiles.day_id and mlso_numfiles.obs_day between ''%s'' and ''%s'' order by date_obs'
  raw_data = db->query(query, start_date, end_date, $
                       count=n_rows, error=error, fields=fields)
  if (n_rows gt 0L) then begin
    mg_log, '%d dates between %s and %s', n_rows, start_date, end_date, $
            name=logger_name, /debug
  endif else begin
    mg_log, 'no data found between %s and %s', start_date, end_date, $
            name=logger_name, /warn
    goto, done
  endelse

  for h = 0L, n_elements(heights) - 1L do begin
    mg_log, 'producing %d-day synoptic plot for %0.2f Rsun', $
            n_days, heights[h], $
            name=logger_name, /info

    height_index = where(tag_names(raw_data) eq strupcase(height_names[h]))
    data = raw_data.(height_index[0])

    dates = raw_data.mlso_obs_day
    times = raw_data.date_obs
    n_dates = n_elements(dates)

    map = fltarr(n_days, n_angles) + !values.f_nan
    means = fltarr(n_days) + !values.f_nan
    date_names = strarr(n_days)
    time_names = strarr(n_days)
    for r = 0L, n_dates - 1L do begin
      decoded = *data[r]
      if (n_elements(decoded) gt 0L) then begin
        if (n_elements(decoded) eq n_angles * 4L) then begin
          *data[r] = float(decoded, 0, n_angles)   ; decode byte data to float
        endif else begin
          mg_log, 'invalid size for %s at %s: %d bytes', $
                  height_names[h], $
                  dates[r], $
                  n_elements(decoded), $
                  name=logger_name, /warn
          continue
        endelse
      endif

      date = dates[r]
      date_index = mlso_dateobs2jd(date) - start_date_jd; - 10.0/24.0
      date_index = floor(date_index)
      date_names[date_index] = date
      time_names[date_index] = strjoin(strsplit(times[r], ' ', /extract), 'T')

      if (ptr_valid(data[r]) && n_elements(*data[r]) gt 0L) then begin
        map[date_index, *] = *data[r]
        means[date_index] = mean(*data[r])
      endif else begin
        map[date_index, *] = !values.f_nan
        means[date_index] = !values.f_nan
      endelse
    endfor

    north_up_map = reverse(shift(map, 0, -180), 1)
    east_limb = reverse(north_up_map[*, 0:359], 2)
    west_limb = north_up_map[*, 360:*]

    ; plot data
    original_device = !d.name

    set_plot, 'Z'
    device, get_decomposed=original_decomposed
    tvlct, original_rgb, /get

    device, set_resolution=[(30 * n_days + 50) < 1200, 450]
    device, decomposed=0

    minv = min_values[h]
    maxv = max_values[h]
    loadct, 0, /silent
    foreground = 0
    background = 255

    display_gamma = run->epoch('synoptic_map_gamma')
    mg_gamma_ct, display_gamma, /current

    tvlct, rgb, /get

    !null = label_date(date_format='%D %M %Z')
    jd_dates = dblarr(n_dates)
    for d = 0L, n_dates - 1L do jd_dates[d] = mlso_dateobs2jd(dates[d])

    charsize = 1.0
    smooth_kernel = [11, 1]

    limbs = ['East', 'West']
    gif_filenames = strarr(n_elements(limbs))
    for i = 0L, n_elements(limbs) - 1L do begin
      limb = limbs[i]
      limb_data = limb eq 'East' ? east_limb : west_limb
      ytick_names = limb eq 'East' $
        ? ['S', 'SE', 'E', 'NE', 'N'] $
        : ['S', 'SW', 'W', 'NW', 'N']

      title = string(keyword_set(enhanced) ? 'Enhanced synoptic' : 'Synoptic', $
                    heights[h], start_date, end_date, $
                    format='(%"%s map for r%0.2f Rsun from %s to %s")')

      erase, background
      top_margin = 0.90
      right_margin = 0.97
      bottom_margin = 0.15
      left_margin = 0.05

      mg_image, limb_data, reverse(jd_dates), $
                xrange=[end_date_jd, start_date_jd], $
                xtyle=1, xtitle='UT time of observations', $
                min_value=minv, max_value=maxv, $
                /axes, yticklen=-0.005, xticklen=-0.01, $
                color=foreground, background=background, $
                title=string(title, limb, format='(%"%s (%s limb)")'), $
                xtickformat='label_date', $
                position=[left_margin, bottom_margin, right_margin, top_margin], $
                /noerase, $
                yticks=4, ytickname=ytick_names, yminor=4, $
                smooth_kernel=smooth_kernel, $
                charsize=charsize

      xyouts, right_margin, 0.050, /normal, alignment=1.0, $
              string(minv, maxv, display_gamma, $
                     format='(%"min/max: %0.3g/%0.3g, gamma: %0.2f")'), $
              charsize=charsize, color=128

      bangle_charsize = 0.75 * charsize
      xyouts, right_margin, top_margin + 0.01, /normal, alignment=0.75, $
              string(start_bangle, format='B-angle %0.2f') + string(176B), $
              charsize=bangle_charsize, color=128
      xyouts, left_margin, top_margin + 0.01, /normal, alignment=0.25, $
              string(end_bangle, format='B-angle %0.2f') + string(176B), $
              charsize=bangle_charsize, color=128

      im = tvrd()

      p_dir = filepath('p', subdir=run.date, root=run->config('processing/raw_basedir'))
      if (~file_test(p_dir, /directory)) then file_mkdir, p_dir

      gif_filenames[i] = filepath(string(run.date, $
                                         n_days, $
                                         keyword_set(enhanced) ? 'enhanced.' : '', $
                                         100.0 * heights[h], $
                                         strlowcase(limb), $
                                         format='(%"%s.kcor.%dday.synoptic.%sr%03d.%s.gif")'), $
                                  root=p_dir)
      write_gif, gif_filenames[i], im, reform(rgb[*, 0]), reform(rgb[*, 1]), reform(rgb[*, 2])
    endfor

    mkhdr, primary_header, map, extend=0

    ; remove automated comments about FITS standard
    sxdelpar, primary_header, 'COMMENT'

    times_indices = where(time_names ne '', n_good_times)
    date_obs = n_good_times eq 0L ? !null : time_names[times_indices[0]]
    date_end = n_good_times eq 0L ? !null : time_names[times_indices[-1]]

    sxdelpar, primary_header, 'DATE'
    fxaddpar, primary_header, 'DATE-OBS', date_obs, $
              ' [UTC] start date of available data for map', $
              after='EXTEND', /null
    fxaddpar, primary_header, 'DATE-END', date_end, $
              ' [UTC] end date of available data for map', $
              after='DATE-OBS', /null
    annulus_width = run->epoch('synoptic_map_annulus_width')
    sxaddpar, primary_header, 'HEIGHT', heights[h], $
              string(annulus_width / 2.0, $
                     format=' [Rsun] height of annulus +/- %0.2f Rsun'), $
              format='(F0.2)', after='DATE-END'

    sxaddpar, primary_header, 'LOCATION', 'MLSO', $
              ' Mauna Loa Solar Observatory, Hawaii', $
              after='HEIGHT'
    sxaddpar, primary_header, 'ORIGIN', 'NCAR/HAO', $
              ' Nat.Ctr.Atmos.Res. High Altitude Observatory', $
              after='LOCATION'
    sxaddpar, primary_header, 'INSTRUME', 'COSMO K-Coronagraph', $
              ' Nat.Ctr.Atmos.Res. High Altitude Observatory', $
              after='ORIGIN'
    sxaddpar, primary_header, 'OBJECT', 'Solar K-Corona', $
              ' white light polarization brightness', $
              after='INSTRUME'
    sxaddpar, primary_header, 'PRODUCT', 'pB 28-day map', $
              ' coronal polarization brightness map', $
              after='OBJECT'

    sxaddpar, primary_header, 'BUNIT', 'Mean Solar Brightness', $
              ' [B/Bsun] mean solar disk brightness', $
              after='PRODUCT'
    sxaddpar, primary_header, 'BZERO', 0, $
              ' offset for unsigned integer data', $
              after='BUNIT'
    sxaddpar, primary_header, 'BSCALE', 1.0, $
              ' physical = data * BSCALE + BZERO', $
              format='(F0.3)', after='BZERO'

    sxaddpar, primary_header, 'WAVELNTH', 735, $
              ' [nm] center wavelength of bandpass filter', $
              after='BSCALE'
    sxaddpar, primary_header, 'WAVEFWHM', 30, $
              ' [nm] full width half max of bandpass filter', $
              after='WAVELNTH'

    current_time = systime(/utc)
    date_dp = string(bin_date(current_time), $
                    format='(%"%04d-%02d-%02dT%02d:%02d:%02d")')
    sxaddpar, primary_header, 'DATE_DP', date_dp, $
              ' synoptic map creation date (UTC)', $
              after='WAVEFWHM'
    version = kcor_find_code_version(revision=revision, date=code_date)
    sxaddpar, primary_header, 'DPSWID',  $
              string(version, revision, $
                     format='(%"%s [%s]")'), $
              string(code_date, $
                     format='(%" synoptic map creation software (%s)")'), $
              after='DATE_DP'

    sxaddpar, primary_header, 'CDELT1', 24.0, $
              ' [hour/pixel] time cadence of images', $
              format='(F0.2)', after='DPSWID'
    sxaddpar, primary_header, 'CDELT2', 0.5, $
              ' [arcsec/pixel] data averaged over 0.5 deg along annulus', $
              format='(F0.2)', after='CDELT1'

    sxaddpar, primary_header, 'CTYPE1', 'Temporal Cadence', $
              ' [hour] maps created using 1 image per day', $
              after='CDELT2'
    ctype2_comment = limb eq 'East' $
      ? ' [deg] CW direction around Sun, North at top' $
      : ' [deg] CCW direction around Sun, North at top'
    sxaddpar, primary_header, 'CTYPE2', 'Position Angle (PA)', ctype2_comment, $
              after='CTYPE1'

    plate_scale = kcor_platescale(run=run)
    sun_pixels = radsun / plate_scale
    pixels_per_bin = kcor_pixels_per_bin(heights[h], $
                                         annulus_width / 2.0, $
                                         sun_pixels, $
                                         n_angles)

    sxaddpar, primary_header, 'PIX_BIN', pixels_per_bin, $
              ' level 2 pixels per synoptic pixel', $
              format='(f8.2)', after='CTYPE2'
    sxaddpar, primary_header, 'RSUN_OBS', radsun, $
              string(dist_au * radsun, $
                     '(%" [arcsec] solar radius using ref radius %0.2f\"")'), $
              format='(f8.2)', after='PIX_BIN'
    sxaddpar, primary_header, 'RSUN', radsun, $
              ' [arcsec] solar radius (old standard keyword)', $
              format='(f8.2)', after='RSUN_OBS'
    sxaddpar, primary_header, 'RSUN-STA', radsun_start, $
              ' [arcsec] solar radius at rotation start', $
              format='(f8.2)', after='RSUN'
    sxaddpar, primary_header, 'RSUN-END', radsun_end, $
              ' [arcsec] solar radius at rotation end', $
              format='(f8.2)', after='RSUN-STA'
    sxaddpar, primary_header, 'CRLT-STA', start_bangle, $
              ' [deg] solar B angle at rotation start', $
              format='(f8.2)', after='RSUN-END'
    sxaddpar, primary_header, 'CRLT-END', end_bangle, $
              ' [deg] solar B angle at rotation end', $
              format='(f8.2)', after='CRLT-STA'

    limb_comment = limb eq 'East' $
      ? ' 180 deg PA at bottom; 90 deg PA middle; 0 deg PA at top of map' $
      : ' 180 deg PA at bottom; 270 deg PA middle; 0 deg PA at top of map'
    sxaddpar, primary_header, 'LIMB', limb, limb_comment, after='CTYPE2'

    after = 'CRLT-END'
    for d = 0L, n_days - 1L do begin
      time_name = string(d + 1, format='TIME%02d')
      time_index = n_days - 1 - d
      time_value = time_names[time_index] eq '' ? !null : time_names[time_index]
      if (d eq 0) then begin
        time_comment = ' TIME01 is latest'
      endif else if (d eq n_days - 1L) then begin
        time_comment = string(n_days, format='TIME%02d is the oldest')
      endif else time_comment = ''

      fxaddpar, primary_header, time_name, time_value, time_comment, $
                after=after, /null
      after = time_name
    endfor

    ; add COMMENTS
    sxaddpar, primary_header, 'COMMENT', $
              'South pole = 180 deg PA, West Eqtr = 270 deg PA', $
              after='LIMB'
    sxaddpar, primary_header, 'COMMENT', $
              'North pole = 0 deg PA, East Eqtr = 90 deg PA', $
              after='LIMB'
    sxaddpar, primary_header, 'COMMENT', $
              'No correction for solar B-angle', $
              after='LIMB'
    sxaddpar, primary_header, 'COMMENT', $
              'Maps are not in Carrington coordinates', $
              after='CRLT-END'

    fits_filenames = strarr(n_elements(limbs))
    for i = 0L, n_elements(limbs) - 1L do begin
      limb = limbs[i]
      limb_map = limb eq 'East' ? east_limb : west_limb

      sxaddpar, primary_header, 'LIMB', limb

      sxaddpar, primary_header, 'NAXIS1', n_days, $
                ' number of days in synoptic map'
      naxis2_comment = limb eq 'East' $
        ? ' images scanned CW direction every 0.5 deg' $
        : ' images scanned CCW direction every 0.5 deg'
      sxaddpar, primary_header, 'NAXIS2', n_angles / 2L, naxis2_comment

      fits_filenames[i] = filepath(string(run.date, $
                                          n_days, $
                                          keyword_set(enhanced) ? 'enhanced.' : '', $
                                          100.0 * heights[h], $
                                          strlowcase(limb), $
                                          format='(%"%s.kcor.%dday.synoptic.%sr%03d.%s.fts")'), $
                                   root=p_dir)
      writefits, fits_filenames[i], limb_map, primary_header

      gzip_cmd = string(run->config('externals/gzip'), fits_filenames[i], $
                        format='(%"%s -f %s")')
      spawn, gzip_cmd, result, error_result, exit_status=status
      fits_filenames[i] += '.gz'
    endfor

    synoptic_maps_basedir = run->config('results/synoptic_maps_basedir')
    if (n_elements(synoptic_maps_basedir) gt 0L) then begin
      date_parts = kcor_decompose_date(run.date)
      synoptic_maps_dir = filepath('', $
                                   subdir=[date_parts[0], date_parts[1]], $
                                   root=synoptic_maps_basedir)
      if (~file_test(synoptic_maps_dir, /directory)) then file_mkdir, synoptic_maps_dir
      mg_log, 'publishing %d-day synoptic map for %0.2f Rsun', $
              n_days, heights[h], name=logger_name, /info
      for i = 0L, n_elements(limbs) - 1L do begin
        file_copy, fits_filenames[i], synoptic_maps_dir, /overwrite
        file_copy, gif_filenames[i], synoptic_maps_dir, /overwrite
      endfor
    endif

    engineering_basedir = run->config('results/engineering_basedir')
    if (n_elements(engineering_basedir) gt 0L) then begin
      date_parts = kcor_decompose_date(run.date)
      eng_dir = filepath('', subdir=kcor_decompose_date(run.date), root=engineering_basedir)
      if (~file_test(eng_dir, /directory)) then file_mkdir, eng_dir
      mg_log, 'copying %d-day synoptic map for %0.2f Rsun to eng_dir', $
              n_days, heights[h], name=logger_name, /info
      for i = 0L, n_elements(limbs) - 1L do begin
        file_copy, fits_filenames[i], eng_dir, /overwrite
        file_copy, gif_filenames[i], eng_dir, /overwrite
      endfor
    endif
  endfor

  ; clean up
  done:
  if (n_elements(original_rgb) gt 0L) then tvlct, original_rgb
  if (n_elements(original_decomposed) gt 0L) then device, decomposed=original_decomposed
  if (n_elements(original_device) gt 0L) then set_plot, original_device

  for d = 0L, n_elements(data) - 1L do begin
    s = raw_data[d]
    ptr_free, s.intensity, s.intensity_stddev
    for h = 0L, n_elements(height_names) - 1L do begin
      height_index = where(tag_names(s) eq strupcase(height_names[h]))
      ptr_free, s.(height_index[0])
    endfor
  endfor

  mg_log, 'done', name=logger_name, /info
end


; main-level example program

date = '20220901'
; date = '20181224'
; date = '20141228'
; date = '20221024'
config_filename = filepath('kcor.reprocessing.cfg', $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
db = kcordbmysql()
db->connect, config_filename=run->config('database/config_filename'), $
             config_section=run->config('database/config_section')

kcor_rolling_synoptic_map, database=db, run=run

obj_destroy, [db, run]

end
