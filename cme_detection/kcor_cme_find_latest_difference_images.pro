; docformat = 'rst'

;+
; Find the level 2 pB images to use to create a difference image. The criteria
; for the images are:
;
; - if the latest pB image is longer than 10 minutes ago, indicate "no new
;   data"; call time of latest pB image, $t_0$
; - find the image "from 10 minutes ago", with exact time denoted $t_{10}$,
;   using the following criteria:
;     1. closest to 10 minutes before latest pB image as long as it is within
;        2 minutes, i.e., with $t_{10}$, satisfying $|t_0 - 10 - t_{10}| < 2$
;     2. find closest image to $t_0 - 10$ up to 30 minutes before $t_0$, i.e.,
;        with $t_{10}$ satisfying $t_0 - 30 < t_{10} < t_0 - 12$
;     3. find closest image to $t_0 - 10$ up to 5 before $t_0$, i.e., with
;        $t_{10}$ satisfying $t_0 - 8 < t_{10} < t_0 - 5$
;
; Specified and discussed in issue #484.
;
; :Params:
;   current_time : in, required, type=string
;     current time as returned from `kcor_cme_current_time`, in the format
;     "YYYY-MM-DDTHH:MM:SSZ"
;   diff_age_threshold : in, required, type=float
;     time period before `current_time` to check for potential images [minutes]
;   min_diff_age_threshold : in, required, type=float
;     minimum time period before `current` to check for potential images [minutes]
;   max_diff_age_threshold : in, required, type=float
;     maximum time period before `current` to check for potential images [minutes]
;
; :Keywords:
;   filename1 : out, optional, type=string
;     set to a named variable to retrieve the filename of the earlier of the
;     two files to use in the difference image
;   filename2 : out, optional, type=string
;     set to a named variable to retrieve the filename of the later of the two
;     files to use in the difference image
;   found : out, optional, type=string
;     set to a named variable to retrieve whether two appropriate files were
;     found
;-
pro kcor_cme_find_latest_difference_images, current_time, $
                                            diff_age_threshold, $
                                            min_diff_age_threshold, $
                                            max_diff_age_threshold, $
                                            filename1=filename1, $
                                            filename2=filename2, $
                                            found=found, $
                                            run=run
  compile_opt strictarr

  tolerance = 2.0

  found = 0B

  ; find the level 2 pB images
  glob = filepath('*_kcor_l2_pb.fts*', $
                  subdir=[run.date, 'level2'], $
                  root=run->config('processing/raw_basedir'))
  pb_filenames = file_search(glob, count=n_pb_files)
  if (n_pb_files eq 0L) then begin
    goto, done
  endif

  basenames  = file_basename(pb_filenames)
  ut_years   = float(strmid(basenames, 0, 4))
  ut_months  = float(strmid(basenames, 4, 2))
  ut_days    = float(strmid(basenames, 6, 2))
  ; skip one character for the "_"
  ut_hours   = float(strmid(basenames, 9, 2))
  ut_minutes = float(strmid(basenames, 11, 2))
  ut_seconds = float(strmid(basenames, 13, 2))

  jds = julday(ut_months, ut_days, ut_years, ut_hours, ut_minutes, ut_seconds)
  current_time_jd = kcor_dateobs2julday(current_time)
  minutes_ago = (current_time_jd - jds) * (24.0D * 60.0D)

  potential_indices = where((minutes_ago gt 0.0) $
                              and (minutes_ago lt max_diff_age_threshold), $
                            n_potential_images)
  ; need at least two images in the last 10 minutes
  if (n_potential_images lt 2L) then return

  potential_filenames = pb_filenames[potential_indices]
  minutes_ago = minutes_ago[potential_indices]

  filename2 = potential_filenames[-1]

  ; first find the closest file to within 2 minutes of 10 minutes ago
  closest_minutes = min(abs(minutes_ago - minutes_ago[-1] - diff_age_threshold), $
                        closest_index)
  if (abs(closest_minutes) lt tolerance) then begin
    filename1 = potential_filenames[closest_index]
    print, minutes_ago[closest_index] - minutes_ago[-1], format='found image from %0.1f minutes ago'
    found = 1B
    return
  endif

  ; otherwise, find the closest file to beyond 12 minutes ago
  old_indices = where((minutes_ago - minutes_ago[-1]) gt (diff_age_threshold + tolerance), $
                      n_old)
  if (n_old gt 1L) then begin
    filename1 = potential_filenames[old_indices[-1]]
    print, minutes_ago[old_indices[-1]] - minutes_ago[-1], format='found image from %0.1f minutes ago'
    found = 1B
    return
  endif

  ; otherwise, find the farthest file away from 5 to 8 minutes ago
  close_indices = where((minutes_ago - minutes_ago[-1]) gt min_diff_age_threshold $ 
                          and (minutes_ago - minutes_ago[-1]) lt (max_diff_age_threshold - tolerance), $
                        n_close)
  if (n_close gt 1L) then begin
    filename1 = potential_filenames[close_indices[0]]
    print, minutes_ago[close_indices[0]] - minutes_ago[-1], format='found image from %0.1f minutes ago'
    found = 1B
    return
  endif

  ; otherwise, we couldn't find a match
  done:
end


; main-level example program

diff_age_threshold     = 10.0   ; minutes
min_diff_age_threshold =  5.0   ; minutes
max_diff_age_threshold = 30.0   ; minutes

config_basename = 'kcor.cme-test.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', 'kcor-config'], $
                           root=mg_src_root())

date = '20220425'
run = kcor_run(date, config_filename=config_filename)

current_time = '2022-04-25T18:03:58Z'
kcor_cme_find_latest_difference_images, current_time, $
                                        diff_age_threshold, $
                                        min_diff_age_threshold, $
                                        max_diff_age_threshold, $
                                        filename1=diff_filename1, $
                                        filename2=diff_filename2, $
                                        found=found_diff, $
                                        run=run

if (found_diff) then begin
  print, file_basename(diff_filename1), format='Earlier file: %s'
  print, file_basename(diff_filename2), format='Later file: %s'

  kcor_cme_create_difference_gif, diff_filename1, diff_filename2, $
    difference_filename=difference_filename, run=run
  print, difference_filename, format='difference GIF created: %s'
endif else begin
  print, 'no files found'
endelse

obj_destroy, run

end
