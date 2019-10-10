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
;-
pro kcor_find_badlines, im, $
                        cam0_badlines=cam0_badlines, $
                        cam1_badlines=cam1_badlines, $
                        difference_threshold=difference_threshold, $
                        median_max=median_max, $
                        corona_max=corona_max
  compile_opt strictarr

  cam0_badlines = !null
  cam1_badlines = !null

  corona0 = kcor_corona(im[*, *, *, 0])
  corona1 = kcor_corona(im[*, *, *, 1])

  if (median(im) gt median_max) then return
  if (median(corona0) gt corona_max || median(corona1) gt corona_max) then return

  cam0_badlines = kcor_find_badlines_camera(corona0, $
                                            difference_threshold=difference_threshold)
  cam1_badlines = kcor_find_badlines_camera(corona1, $
                                            difference_threshold=difference_threshold)
end


; main-level example program

date = '20190625'
config_filename = filepath('kcor.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

;basename = '20190625_184435_kcor.fts.gz'
;basename = '20190625_193439_kcor.fts.gz'
;basename = '20190625_174052_kcor.fts.gz'
;basename = '20190625_174253_kcor.fts.gz'
;basename = '20190625_172355_kcor.fts.gz'
;basename = '20190625_172426_kcor.fts.gz'
;basename = '20190625_174842_kcor.fts.gz'
;basename = '20190625_183025_kcor.fts.gz'
;basename = '20190625_182421_kcor.fts.gz'
;basename = '20190625_184218_kcor.fts.gz'
;basename = '20190625_184435_kcor.fts.gz'
;basename = '20190625_192603_kcor.fts.gz'
basename = '20190625_193338_kcor.fts.gz'
filename = filepath(basename, $
                    subdir=[date, 'level0'], $
;                    subdir=[date], $
                    root=run->config('processing/raw_basedir'))
im = readfits(filename, header, /silent)

corona0 = kcor_corona(im[*, *, *, 0])
corona1 = kcor_corona(im[*, *, *, 1])

window, xsize=1024, ysize=1024, /free, title='Raw corona0 ' + basename
tv, bytscl(corona0, min=0.0, max=200.0)
window, xsize=1024, ysize=1024, /free, title='Raw corona1 ' + basename
tv, bytscl(corona1, min=0.0, max=200.0)

kcor_find_badlines, im, $
                    cam0_badlines=cam0_badlines, $
                    cam1_badlines=cam1_badlines, $
                    difference_threshold=run->config('badlines/difference_threshold'), $
                    median_max=run->config('badlines/median_max'), $
                    corona_max=run->config('badlines/corona_max')

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

obj_destroy, run

end
