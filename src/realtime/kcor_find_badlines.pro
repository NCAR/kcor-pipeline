
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
                        cam1_badlines=cam1_badlines
  compile_opt strictarr

  diff_threshold = 20.0 ; 25.0

  cam0_badlines = !null
  cam1_badlines = !null

  corona0 = kcor_corona(im[*, *, *, 0])
  corona1 = kcor_corona(im[*, *, *, 1])

;  if (median(im) gt 10000.0) then return
  if (median(corona0) gt 200.0 || median(corona1) gt 200.0) then return

  cam0_badlines = kcor_find_badlines_camera(corona0, diff_threshold=diff_threshold)
  cam1_badlines = kcor_find_badlines_camera(corona1, diff_threshold=diff_threshold)
end


; main-level example program

date = '20190625'
config_filename = filepath('kcor.latest.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

l0_dir = filepath('', subdir=[date, 'level0'], root=run->config('processing/raw_basedir'))
;l0_dir = filepath('', subdir=[date], root=run->config('processing/raw_basedir'))
p_dir = filepath('', subdir=[date, 'p'], root=run->config('processing/raw_basedir'))

raw_files = file_search(filepath('*.fts.gz', root=l0_dir), count=n_raw_files)

orig_device = !d.name
set_plot, 'Z'
device, set_resolution=[2 * 1024, 1024], decomposed=1

for f = 0L, n_raw_files - 1L do begin
  print, file_basename(raw_files[f])

  im = readfits(raw_files[f], header, /silent)
  im = float(im)

  corona0 = kcor_corona(im[*, *, *, 0])
  corona1 = kcor_corona(im[*, *, *, 1])

  kcor_find_badlines, im, $
                      cam0_badlines=cam0_badlines, $
                      cam1_badlines=cam1_badlines

  corrected_im = im
  kcor_correct_horizontal_artifact, corrected_im, cam0_badlines, cam1_badlines
  corrected_corona0 = kcor_corona(corrected_im[*, *, *, 0])
  corrected_corona1 = kcor_corona(corrected_im[*, *, *, 1])

  tv, bytscl(corona0^0.7, min=0.0, max=210.0), 0
  tv, bytscl(corrected_corona0^0.7, min=0.0, max=210.0), 1

  if (n_elements(cam0_badlines) gt 0L) then begin
    print, string(strjoin(strtrim(cam0_badlines, 2), ', '), $
                  format='(%"  cam 0 bad lines: %s")')
    xyouts, 5, 5, /device, $
            string(strjoin(strtrim(cam0_badlines, 2), ', '), $
                         format='(%"bad lines: %s")'), $
            color=255
  endif
  output = tvrd()
  write_gif, filepath(string(file_basename(raw_files[f], '.fts.gz'), $
                             format='(%"%s-badlines-cam0.gif")'), $
                      root=p_dir), $
             output

  tv, bytscl(corona1^0.7, min=0.0, max=210.0), 0
  tv, bytscl(corrected_corona1^0.7, min=0.0, max=210.0), 1

  if (n_elements(cam1_badlines) gt 0L) then begin
    print, string(strjoin(strtrim(cam1_badlines, 2), ', '), $
                  format='(%"  cam 1 bad lines: %s")')
    xyouts, 5, 5, /device, $
            string(strjoin(strtrim(cam1_badlines, 2), ', '), $
                   format='(%"bad lines: %s")'), $
            color=255
  endif
  output = tvrd()
  write_gif, filepath(string(file_basename(raw_files[f], '.fts.gz'), $
                             format='(%"%s-badlines-cam1.gif")'), $
                      root=p_dir), $
             output
endfor

set_plot, orig_device
obj_destroy, run

end
