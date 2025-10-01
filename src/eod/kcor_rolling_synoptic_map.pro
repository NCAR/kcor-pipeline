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

  n_days = 28   ; number of days to include in the plot
  logger_name = run.logger_name

  heights =  [1.11, 1.15, 1.20, 1.35, 1.50, 1.75, 2.00, 2.25, 2.50]
  height_names = ['r111', 'r115', 'r12', 'r135', 'r15', 'r175', 'r20', 'r225', 'r25']
  if (keyword_set(enhanced)) then height_names = 'enhanced_' + height_names

  ; query database for data
  end_date_tokens = long(kcor_decompose_date(run.date))
  end_date = string(end_date_tokens, format='(%"%04d-%02d-%02d")')
  end_date_jd = julday(end_date_tokens[1], $
                       end_date_tokens[2], $
                       end_date_tokens[0], $
                       0, 0, 0)
  start_date_jd = end_date_jd - n_days + 1
  start_date = string(start_date_jd, $
                      format='(C(CYI4.4, "-", CMoI2.2, "-", CDI2.2))')

  query = 'select kcor_sci.* from kcor_sci, mlso_numfiles where kcor_sci.obs_day=mlso_numfiles.day_id and mlso_numfiles.obs_day between ''%s'' and ''%s'''
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
    mg_log, 'producing synoptic plot for %0.2f Rsun of last %d days', $
            heights[h], n_days, $
            name=logger_name, /info

    height_index = where(tag_names(raw_data) eq strupcase(height_names[h]))
    data = raw_data.(height_index[0])

    dates = raw_data.date_obs
    n_dates = n_elements(dates)

    map = fltarr(n_days, 720) + !values.f_nan
    means = fltarr(n_days) + !values.f_nan
    for r = 0L, n_dates - 1L do begin
      decoded = *data[r]
      if (n_elements(decoded) gt 0L) then begin
        if (n_elements(decoded) eq 720L * 4L) then begin
          *data[r] = float(decoded, 0, 720)   ; decode byte data to float
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
      date_index = mlso_dateobs2jd(date) - start_date_jd - 10.0/24.0
      date_index = floor(date_index)

      if (ptr_valid(data[r]) && n_elements(*data[r]) gt 0L) then begin
        map[date_index, *] = *data[r]
        means[date_index] = mean(*data[r])
      endif else begin
        map[date_index, *] = !values.f_nan
        means[date_index] = !values.f_nan
      endelse
    endfor

    ; plot data
    set_plot, 'Z'
    device, set_resolution=[(30 * n_days + 50) < 1200, 800]
    original_device = !d.name

    device, get_decomposed=original_decomposed
    tvlct, rgb, /get
    device, decomposed=0

    range = mg_range(map)
    if (range[0] lt 0.0) then begin
      minv = 0.0
      maxv = range[1]

      loadct, 0, /silent
      foreground = 0
      background = 255
    endif else begin
      minv = 0.0
      maxv = range[1]

      loadct, 0, /silent
      foreground = 0
      background = 255
    endelse

    north_up_map = shift(map, 0, -180)
    east_limb = reverse(north_up_map[*, 0:359], 2)
    west_limb = north_up_map[*, 360:*]

    !null = label_date(date_format='%D %M %Z')
    jd_dates = dblarr(n_dates)
    for d = 0L, n_dates - 1L do jd_dates[d] = mlso_dateobs2jd(dates[d])

    charsize = 1.0
    smooth_kernel = [11, 1]

    title = string(keyword_set(enhanced) ? 'Enhanced synoptic' : 'Synoptic', $
                   heights[h], start_date, end_date, $
                   format='(%"%s map for r%0.2f Rsun from %s to %s")')
    erase, background
    mg_image, reverse(east_limb, 1), reverse(jd_dates), $
              xrange=[end_date_jd, start_date_jd], $
              xtyle=1, xtitle='Date (not offset for E limb)', $
              min_value=minv, max_value=maxv, $
              /axes, yticklen=-0.005, xticklen=-0.01, $
              color=foreground, background=background, $
              title=string(title, format='(%"%s (East limb)")'), $
              xtickformat='label_date', $
              position=[0.05, 0.55, 0.97, 0.95], /noerase, $
              yticks=4, ytickname=['S', 'SE', 'E', 'NE', 'N'], yminor=4, $
              smooth_kernel=smooth_kernel, $
              charsize=charsize
    mg_image, reverse(west_limb, 1), reverse(jd_dates), $
              xrange=[end_date_jd, start_date_jd], $
              xstyle=1, xtitle='Date (not offset for W limb)', $
              min_value=minv, max_value=maxv, $
              /axes, yticklen=-0.005, xticklen=-0.01, $
              color=foreground, background=background, $
              title=string(title, format='(%"%s (West limb)")'), $
              xtickformat='label_date', $
              position=[0.05, 0.05, 0.97, 0.45], /noerase, $
              yticks=4, ytickname=['S', 'SW', 'W', 'NW', 'N'], yminor=4, $
              smooth_kernel=smooth_kernel, $
              charsize=charsize

    xyouts, 0.97, 0.485, /normal, alignment=1.0, $
            string(minv, maxv, format='(%"min/max: %0.3g, %0.3g")'), $
            charsize=charsize, color=128

    im = tvrd()

    p_dir = filepath('p', subdir=run.date, root=run->config('processing/raw_basedir'))
    if (~file_test(p_dir, /directory)) then file_mkdir, p_dir

    gif_filename = filepath(string(run.date, $
                                   n_days, $
                                   keyword_set(enhanced) ? 'enhanced.' : '', $
                                   100.0 * heights[h], $
                                   format='(%"%s.kcor.%dday.synoptic.%sr%03d.gif")'), $
                            root=p_dir)
    write_gif, gif_filename, im, rgb[*, 0], rgb[*, 1], rgb[*, 2]

    mkhdr, primary_header, map, /extend

    sxaddpar, primary_header, 'NAXIS1', sxpar(primary_header, 'NAXIS1'), $
              ' number of days'
    sxaddpar, primary_header, 'NAXIS2', sxpar(primary_header, 'NAXIS2'), $
              ' number of angles'

    sxdelpar, primary_header, 'DATE'
    sxaddpar, primary_header, 'DATE-OBS', start_date, $
              ' [UTC] start date of synoptic map', after='EXTEND'
    sxaddpar, primary_header, 'DATE-END', end_date, $
              ' [UTC] end date of synoptic map', $
              format='(F0.2)', after='DATE-OBS'
    sxaddpar, primary_header, 'HEIGHT', heights[h], $
              ' [Rsun] height of annulus +/- 0.02 Rsun', $
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
    sxaddpar, primary_header, 'PRODUCT', 'pB', $
              ' coronal polarization brightness', $
              after='INSTRUME'
    sxaddpar, primary_header, 'WAVELNTH', 735, $
              ' [nm] center wavelength of bandpass filter', $
              after='PRODUCT'
    sxaddpar, primary_header, 'WAVEFWHM', 30, $
              ' [nm] full width half max of bandpass filter', $
              after='WAVELNTH'

    current_time = systime(/utc)
    date_dp = string(bin_date(current_time), $
                    format='(%"%04d-%02d-%02dT%02d:%02d:%02d")')
    sxaddpar, primary_header, 'DATE_DP', date_dp, $
              ' L1 processing date (UTC)', $
              after='WAVEFWHM'
    version = kcor_find_code_version(revision=revision, date=code_date)
    sxaddpar, primary_header, 'DPSWID',  $
              string(version, revision, $
                     format='(%"%s [%s]")'), $
              string(code_date, $
                     format='(%" L1 data processing software (%s)")'), $
              after='DATE_DP'
    ; TODO: fix these up
    ; ??? This is a function of how many pixels we average in the radial
    ; direction for each annulus
    sxaddpar, primary_header, 'CDELT1', 1.0, $
              ' [days/pixel]', $
              format='(F0.2)', after='DPSWID'
    ; this is a function of height, apparent size of the Sun on a given day and
    ; the K-Cor platescale
    sxaddpar, primary_header, 'CDELT2', !values.f_nan, $
              ' [arcsec/pixel]', $
              format='(F0.2)', after='CDELT1', /null

    ; ephemeris data
    mid_jd = (end_date_jd + start_date_jd) / 2.0
    caldat, mid_jd, mid_month, mid_day, mid_year
    sun, mid_year, mid_month, mid_day, 0.0, sd=radsun, dist=dist_au

    caldat, end_date_jd, end_month, end_day, end_year
    sun, end_year, end_month, end_day, 0.0, sd=radsun_end

    caldat, start_date_jd, start_month, start_day, start_year
    sun, start_year, start_month, start_day, 0.0, sd=radsun_start

    sxaddpar, primary_header, 'RSUN_OBS', radsun, $
              string(dist_au * radsun, $
                     '(%" [arcsec] solar radius using ref radius %0.2f\"")'), $
              format='(f8.2)', after='CDELT2'
    sxaddpar, primary_header, 'RSUN', radsun, $
              ' [arcsec] solar radius (old standard keyword)', $
              format='(f8.2)', after='RSUN_OBS'
    sxaddpar, primary_header, 'RSUN-STA', radsun_start, $
              ' [arcsec] solar radius at rotation start', $
              format='(f8.2)', after='RSUN'
    sxaddpar, primary_header, 'RSUN-END', radsun_end, $
              ' [arcsec] solar radius at rotation end', $
              format='(f8.2)', after='RSUN-STA'

    fits_filename = filepath(string(run.date, $
                                    n_days, $
                                    keyword_set(enhanced) ? 'enhanced.' : '', $
                                    100.0 * heights[h], $
                                    format='(%"%s.kcor.%dday.synoptic.%sr%03d.fts")'), $
                             root=p_dir)
    writefits, fits_filename, map, primary_header

    synoptic_maps_basedir = run->config('results/synoptic_maps_basedir')
    if (n_elements(synoptic_maps_basedir) gt 0L) then begin
      date_parts = kcor_decompose_date(run.date)
      synoptic_maps_dir = filepath('', $
                                   subdir=[date_parts[0], date_parts[1]], $
                                   root=synoptic_maps_basedir)
      if (~file_test(synoptic_maps_dir, /directory)) then file_mkdir, synoptic_maps_dir
      mg_log, 'distributing %d day rolling synoptic map for %0.2f Rsun to synmaps dir...', $
              n_days, heights[h], name=logger_name, /info
      file_copy, fits_filename, synoptic_maps_dir, /overwrite
      file_copy, gif_filename, synoptic_maps_dir, /overwrite
    endif

    engineering_basedir = run->config('results/engineering_basedir')
    if (n_elements(engineering_basedir) gt 0L) then begin
      date_parts = kcor_decompose_date(run.date)
      eng_dir = filepath('', subdir=kcor_decompose_date(run.date), root=engineering_basedir)
      if (~file_test(eng_dir, /directory)) then file_mkdir, eng_dir
      mg_log, 'distributing %d day rolling synoptic map for %0.2f Rsun to engineering...', $
              n_days, heights[h], name=logger_name, /info
      file_copy, fits_filename, eng_dir, /overwrite
      file_copy, gif_filename, eng_dir, /overwrite
    endif
  endfor

  ; clean up
  done:
  if (n_elements(rgb) gt 0L) then tvlct, rgb
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

date = '20221007'
config_filename = filepath('kcor.latest.cfg', $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
db = kcordbmysql()
db->connect, config_filename=run->config('database/config_filename'), $
             config_section=run->config('database/config_section')

kcor_rolling_synoptic_map, database=db, run=run

obj_destroy, [db, run]

end
