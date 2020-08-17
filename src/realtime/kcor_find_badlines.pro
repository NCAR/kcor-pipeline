; docformat = 'rst'

;+
; Find the bad horizontal lines in a full raw image by camera.
;
; :Params:
;   im : in, required, type="uintarr(nx, ny, 4, 2)"
;     raw image
;
; :Keywords:
;   cam0_badlines : out, optional, type=lonarr
;     bad lines for camera 0
;   cam1_badlines : out, optional, type=lonarr
;     bad lines for camera 1
;   difference_threshold : in, optional, type=float, default=20.0
;     threshold to check median of column convolution against
;-
pro kcor_find_badlines, im, $
                        cam0_badlines=cam0_badlines, $
                        cam1_badlines=cam1_badlines, $
                        difference_threshold=difference_threshold, $
                        cam0_medians=cam0_medians, $
                        cam1_medians=cam1_medians, $
                        n_skip=n_skip
  compile_opt strictarr

  diff_threshold = 20.0

  cam0_badlines = !null
  cam1_badlines = !null

  corona0 = kcor_corona(im[*, *, *, 0])
  corona1 = kcor_corona(im[*, *, *, 1])

  cam0_badlines = kcor_find_badlines_camera(corona0, $
                                            difference_threshold=difference_threshold, $
                                            n_skip=n_skip, $
                                            medians=cam0_medians)
  cam1_badlines = kcor_find_badlines_camera(corona1, $
                                            difference_threshold=difference_threshold, $
                                            n_skip=n_skip, $
                                            medians=cam1_medians)
end


; main-level example program

date = '20191107'
time = '200530'
;time = '214437'

;date = '20190618'
;time = '184536'
;time = '201254'

config_filename = filepath('kcor.parker.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
run.time = time

basename = string(date, time, format='(%"%s_%s_kcor.fts.gz")')
filename = filepath(basename, $
                    subdir=[date, 'level0'], $
;                    subdir=[date], $
                    root=run->config('processing/raw_basedir'))
kcor_read_rawdata, filename, image=im, header=header, $
                   repair_routine=run->epoch('repair_routine'), $
                   state_state=run->epoch('start_state')

corona0 = kcor_corona(im[*, *, *, 0])
corona1 = kcor_corona(im[*, *, *, 1])

window, xsize=1024, ysize=1024, /free, title='Raw corona0 ' + basename
tv, bytscl(corona0, min=0.0, max=200.0)
window, xsize=1024, ysize=1024, /free, title='Raw corona1 ' + basename
tv, bytscl(corona1, min=0.0, max=200.0)

kcor_find_badlines, im, $
                    cam0_badlines=cam0_badlines, $
                    cam1_badlines=cam1_badlines, $
                    difference_threshold=run->epoch('badlines_diff_threshold'), $
                    cam0_medians=cam0_medians, $
                    cam1_medians=cam1_medians, $
                    n_skip=run->epoch('badlines_nskip')

if (n_elements(cam0_badlines) gt 0L) then begin
  print, strjoin(strtrim(cam0_badlines, 2), ', '), $
         format='(%"cam 0 bad lines: %s")'
endif
if (n_elements(cam1_badlines) gt 0L) then begin
  print, strjoin(strtrim(cam1_badlines, 2), ', '), $
         format='(%"cam 1 bad lines: %s")'
endif

kcor_correct_horizontal_artifact, im, $
                                  cam0_badlines, $
                                  cam1_badlines

corona0 = kcor_corona(im[*, *, *, 0])
corona1 = kcor_corona(im[*, *, *, 1])

window, xsize=1024, ysize=1024, /free, title='Corrected raw corona0 ' + basename
tv, bytscl(corona0, min=0.0, max=200.0)
window, xsize=1024, ysize=1024, /free, title='Corrected raw corona1 ' + basename
tv, bytscl(corona1, min=0.0, max=200.0)

badlines_filename = string(date, time, format='(%"%s.%s.badlines.gif")')
badlines_histogram_filename = string(date, time, $
                                     format='(%"%s.%s.badlines.histogram.gif")')
kcor_plot_badlines_medians, date + '_' + time, $
                            cam0_medians, cam1_medians, $
                            run->epoch('badlines_diff_threshold'), $
                            badlines_filename, $
                            badlines_histogram_filename, $
                            n_skip=run->epoch('badlines_nskip')

obj_destroy, run

end
