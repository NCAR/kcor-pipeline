; docformat = 'rst'

pro kcor_l2, l1_filename, $
             l1_header, $
             intensity, qmk4, umk4, $
             flat_vdimref, $
             nomask=nomask, $
             l2_filename=l2_filename, $
             run=run, $
             log_name=log_name, $
             error=error
  compile_opt strictarr

  error = 0L

  if (n_elements(l1_header) eq 0L) then begin
    mg_log, 'no L1 header, skipping', name=log_name, /debug
    goto, done
  endif

  ; setup directories
  dirs  = filepath('level' + ['0', '1', '2'], $
                   subdir=run.date, $
                   root=run->config('processing/raw_basedir'))
  l0_dir = dirs[0]
  l1_dir = dirs[1]
  l2_dir = dirs[2]

  if (~file_test(l2_dir, /directory)) then file_mkdir, l2_dir

  mg_log, 'L2 processing %s%s', $
          file_basename(l1_filename), keyword_set(nomask) ? ' (nomask)' : '', $
          name=log_name, /info

  clock = tic('l2_loop')

  date_obs = sxpar(l1_header, 'DATE-OBS')   ; yyyy-mm-ddThh:mm:ss
  date_struct = kcor_parse_dateobs(date_obs)
  run.time = date_obs

  sun, date_struct.year, date_struct.month, date_struct.day, $
       date_struct.ehour, $
       pa=pangle, sd=radsun

  ; create coordinate system
  xsize = run->epoch('xsize')
  ysize = run->epoch('ysize')
  xx   = dindgen(xsize, ysize) mod xsize - (xsize / 2.0 - 0.5)
  yy   = transpose(dindgen(ysize, xsize) mod ysize) - (ysize / 2.0 - 0.5)

  center_offset = run->config('realtime/center_offset')
  rad  = sqrt((xx + center_offset[0])^ 2.0 + (yy + center_offset[1]) ^ 2.0)

  theta = atan(- yy, - xx)
  theta += !pi
  theta = rot(reverse(theta), pangle + run->epoch('rotation_correction'), 1, /interp)

  if (run->config('realtime/smooth_sky')) then begin
    qmk4 = gauss_smooth(qmk4, 3, /edge_truncate)
  endif

  ; sky polarization removal on coordinate-transformed data
  case strlowcase(run->config('realtime/skypol_method')) of
    'subtraction': begin
        mg_log, 'correcting sky polarization with subtraction method', $
                name=log_name, /debug

        qmk4_new = float(qmk4)

        ; umk4 contains the corona
        umk4_new = float(umk4) - float(rot(qmk4, 45.0, /interp)) + run->epoch('skypol_bias')
      end
    'sine2theta': begin
        mg_log, 'correcting sky polarization with sine2theta (%d params) method', $
                run->epoch('sine2theta_nparams'), name=log_name, /debug
        kcor_sine2theta_method, umk4, qmk4, intensity, radsun, theta, rad, $
                                q_new=qmk4_new, u_new=umk4_new, $
                                run=run
      end
    else: mg_log, 'no sky polarization correction', name=log_name, /debug
  endcase

  ; use only corona minus sky polarization background
  corona = umk4_new

  ; sky transmission correction
  if (run->epoch('use_sgs')) then begin
    vdimref = kcor_getsgs(l1_header, 'SGSDIMV', /float)
    dimv_comment = ''
  endif else begin
    vdimref = kcor_simulate_sgsdimv(date_obs, run=run)
    dimv_comment = ' (simulated)'
  endelse
  mg_log, 'flat DIMV: %0.1f, image DIMV: %0.1f%s', $
          flat_vdimref, vdimref, dimv_comment, $
          name=log_name, /debug
  if (finite(vdimref) && finite(flat_vdimref) && vdimref ne 0.0) then begin
    skytrans = flat_vdimref / vdimref
    corona *= skytrans
  endif

  ; create mask for final image
  if (~keyword_set(nomask)) then begin
    if (run->epoch('use_occulter_id')) then begin
      occltrid = sxpar(l1_header, 'OCCLTRID')
    endif else begin
      occltrid = run->epoch('occulter_id')
    endelse
    occulter = kcor_get_occulter_size(occltrid, run=run)  ; arcsec

    r_in  = fix(occulter / run->epoch('plate_scale')) + run->epoch('r_in_offset')
    r_out = run->epoch('r_out')

    ; mask pixels beyond field of view
    mask = where(rad lt r_in or rad ge r_out, /null)
    corona[mask] = run->epoch('display_min')
  endif

  kcor_create_gif, l1_filename, corona, date_obs, $
                   level=2, $
                   scaled_image=scaled_image, $
                   nomask=nomask, $
                   run=run, log_name=log_name

  ; convert L1 header to an L2 header
  l2_header = l1_header

  fxaddpar, l2_header, 'NAXIS', 2, ' number of dimensions; FITS image' 
  sxdelpar, l2_header, 'NAXIS3'
  fxaddpar, l2_header, 'OBJECT', 'Solar K-Corona', $
            ' white light polarization brightness'
  fxaddpar, l2_header, 'LEVEL', 'L2', $
            ' level 2 pB intensity is fully-calibrated'

  date_dp = string(bin_date(systime(/utc)), $
                   format='(%"%04d-%02d-%02dT%02d:%02d:%02d")')
  fxaddpar, l2_header, 'DATE_DP', date_dp, ' L2 processing date (UTC)'
  version = kcor_find_code_version(revision=revision, date=code_date)
  fxaddpar, l2_header, 'DPSWID',  $
            string(version, revision, $
                   format='(%"%s [%s]")'), $
            string(code_date, $
                   format='(%" L2 data processing software (%s)")')

  fxaddpar, l2_header, 'SKYTRANS', skytrans, $
            ' ' + run->epoch('skytrans_comment'), $
            format='(F5.3)', /null
  fxaddpar, l2_header, 'BIASCORR', run->epoch('skypol_bias'), $
            ' bias added after sky polarization correction', $
            format='(G0.3)'
  skypol_method = strlowcase(run->config('realtime/skypol_method'))
  skypol_method_comment = ' sky polarization removal method'
  case skypol_method of
    'subtraction':
    'sine2theta': skypol_method_comment += string(run->epoch('sine2theta_nparams'), $
                                                  format='(%" (%d params)")')
    else: skypol_method = 'none'
  endcase
  fxaddpar, l2_header, 'SKYPOLRM', skypol_method, skypol_method_comment

  if (run->config('realtime/smooth_sky')) then begin
    fxaddpar, l2_header, 'SKYSM', run->config('realtime/smooth_sky') ? 'T' : 'F', $
              ' was sky smoothed before subtracting from corona'
  endif

  fxaddpar, l2_header, 'DATAMIN', min(corona, /nan), ' minimum value of data', $
            format='(E0.4)'
  fxaddpar, l2_header, 'DATAMAX', max(corona, /nan), ' maximum value of data', $
            format='(E0.4)'

  sxdelpar, l2_header, 'HISTORY'
  fxaddpar, l2_header, 'DUMMY', 1.0
  history = ['Level 1 calibration and processing steps: dark current subtracted;', $
             'gain correction; apply polarization demodulation matrix; apply', $
             'distortion correction; align each camera to center, rotate to solar', $
             'north and combine cameras; coordinate transformation from cartesian', $
             'to tangential polarization; remove sky polarization; correct for', $
             'sky transmission.']
  history = mg_strwrap(strjoin(history, ' '), width=72)
  for h = 0L, n_elements(history) - 1L do sxaddhist, history[h], l2_header

  sxdelpar, l2_header, 'DUMMY'

  ; give a warning for NaN/infinite values in the final corona image
  !null = where(finite(corona) eq 0, n_nans)
  if (n_nans gt 0L) then begin
    mg_log, '%d NaN/Inf values in L1 FITS', n_nans, name=log_name, /warn
  endif

  ; write FITS image to disk
  l2_filename = string(strmid(file_basename(l1_filename), 0, 20), $
                       keyword_set(nomask) ? '_nomask' : '', $
                       format='(%"%s_l2%s.fts")')
  writefits, filepath(l2_filename, root=l2_dir), corona, l2_header

  ; write Helioviewer JPEG2000 image to a web accessible directory
  if (run->config('results/hv_basedir') ne '' && ~keyword_set(nomask)) then begin
    hv_kcor_write_jp2, scaled_image, l2_header, $
                       run->config('results/hv_basedir'), $
                       log_name=log_name
  endif

  ; now make cropped GIF file
  kcor_cropped_gif, corona, run.date, date_struct, $
                    run=run, nomask=nomask, log_name=log_name, $
                    level=2

  ; create NRGF (normalized, radially-graded filter) GIF image
  cd, l2_dir
  if (date_struct.second lt 15 and date_struct.minute mod 2 eq 0 $
        and ~keyword_set(nomask)) then begin
    kcor_nrgf, l2_filename, run=run, log_name=log_name
    mg_log, /check_math, name=log_name, /debug
    kcor_nrgf, l2_filename, /cropped, run=run, log_name=log_name
    mg_log, /check_math, name=log_name, /debug
  endif
  cd, l0_dir

  loop_time = toc(clock)   ; save loop time
  mg_log, '%0.1f sec to process %s', loop_time, file_basename(l2_filename), $
          name=log_name, /debug

  done:
  mg_log, /check_math, name=log_name, /debug
end
