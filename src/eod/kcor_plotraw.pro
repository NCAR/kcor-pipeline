; docformat = 'rst'

;+
; Plot parameters from raw KCor files.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   list : in, required, type=strarr
;     list of files to process
;   run : in, required, type=object
;     `kcor_run` object
;   means : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the mean of the pixel values of the
;     corresponding camera/raw file at `im[10:300, 512]`
;   medians : out, optional, type="fltarr(2, n_files)"
;     set to a named variable to retrieve the median of the pixel values of the
;     corresponding camera/raw file at `im[10:300, 512]`
;-
pro kcor_plotraw, date, list=list, run=run, means=means, medians=medians
  compile_opt strictarr

  ; get raw filenames
  raw_nrgf_files = strmid(list, 0, 20) + '.fts'
  n_nrgf_files = n_elements(raw_nrgf_files)
  if (n_nrgf_files eq 0L) then begin
    mg_log, 'no NRGF raw files to plot', name='kcor/eod', /warn
    goto, done
  endif

  ; create output arrays
  means    = fltarr(2, n_nrgf_files)
  medians  = fltarr(2, n_nrgf_files)

  l0_dir   = filepath('level0', subdir=date, root=run.raw_basedir)
  plot_dir = filepath('p', subdir=date, root=run.raw_basedir)
  if (~file_test(plot_dir, /directory)) then file_mkdir, plot_dir

  cd, current=orig_dir
  cd, l0_dir

  ; set up plotting environment
  orig_device = !d.name
  set_plot, 'Z'
  device, set_resolution=[772, 500], decomposed=0, set_colors=256, z_buffering=0
  red   = 255B - bindgen(256)
  green = 255B - bindgen(256)
  blue  = 255B - bindgen(256)
  tvlct, red, green, blue
  !p.multi = [0, 1, 2]

  for f = 0L, n_nrgf_files - 1L do begin
    im = readfits(raw_nrgf_files[f], header, /silent)

    cam0_profile = reform(im[*, 512, 0, 0])
    cam1_profile = reform(im[*, 512, 0, 1])

    means[0, f] = mean(cam0_profile[10:300])
    means[1, f] = mean(cam1_profile[10:300])

    medians[0, f] = median(cam0_profile[10:300])
    medians[1, f] = median(cam1_profile[10:300])

    plot, cam0_profile, $
          title='Line profile at y=512 for Camera 0', $
          xticks=8, xstyle=1, xtickformat='(I)', xtitle='Raw image x-coordinate', $
          ytickformat='(I)', ytitle='Raw pixel value', yrange=[0, 40000], $
          yticks=4, yminor=1, yticklen=1.0, ygridstyle=1
    plot, cam1_profile, $
          title='Line profile at y=512 for Camera 1', $
          xticks=8, xstyle=1, xtickformat='(I)', xtitle='Raw image x-coordinate', $
          ytickformat='(I)', yrange=[0, 40000], ytitle='Raw pixel value', $
          yticks=4, yminor=1, yticklen=1.0, ygridstyle=1

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
