; docformat = 'rst'


function kcor_find_latest_cal_files_latest, cal_files
  compile_opt strictarr

  return, 0
end


;+
; Find the latest cal files for a given epoch.
;
; :Returns:
;   `strarr` of full filenames of the latest cal file for each date present in
;   the given cal epoch
;
; :Params:
;   cal_epoch : in, required, type=string
;     cal epoch to compute the master gain for
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
function kcor_find_latest_cal_files, cal_epoch, count=n_cal_files, run=run
  compile_opt strictarr

  cal_dir = run->config('calibration/out_dir')

  ; cal files have the form:
  ; [YYYYMMDD]_[HHMMSS]_kcor_cal_v[CAL_EPOCH]_[CODE_VERSION]_[EXPOSURE]ms.ncdf
  base_glob = string(cal_epoch, format='*_kcor_cal_v%s_*ms.ncdf')
  glob = filepath(base_glob, root=cal_dir)
  cal_filenames = file_search(glob, count=n_cal_files)
  if (n_cal_files eq 0L) then return, !null

  cal_basenames = file_basename(cal_filenames)

  ; keep only the latest cal file for each date
  dates = strmid(cal_basenames, 0, 8)
  unique_dates = dates[uniq(dates, sort(dates))]
  n_cal_files = n_elements(unique_dates)

  unique_cal_filenames = strarr(n_cal_files)
  for d = 0L, n_cal_files - 1L do begin
    indices = where(dates eq unique_dates[d], /null)
    j = kcor_find_latest_cal_files_latest(cal_basenames[indices])
    unique_cal_filenames[d] = cal_filenames[indices[j]]
  endfor

  return, unique_cal_filenames
end
