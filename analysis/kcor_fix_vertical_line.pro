; docformat = 'rst'

; main-level example program

; pick date and times to reprocess and construct an NRGF file from
date = '20200404'
time = '182730'
times = ['182730', $
         '182746', $
         '182801', $
         '182816', $
         '182831', $
         '182846', $
         '182901', $
         '182917']

config_filename = filepath('kcor.vline.cfg', subdir=['..', 'config'], root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
run->setProperty, time=times[0]

; reprocess the 8 L1/L2 files needed
;l0_filenames = date + '_' + times + '_kcor.fts.gz'
;kcor_process_files, l0_filenames, run=run, error=error, /eod
;print, error

;unzipped_glob = filepath('*_kcor.fts', $
;                         subdir=[date, 'level2'], $
;                         root=run->config('processing/raw_basedir'))
;unzipped_files = file_search(unzipped_glob, count=n_unzipped_files)
;gzip_cmd = string(run->config('externals/gzip'), unzipped_glob, $
;                  format='(%"%s %s")')
;spawn, gzip_cmd, result, error_result, exit_status=status

im_total = fltarr(1024, 1024)
for t = 0L, n_elements(times) - 1L do begin
  im_total += readfits(filepath(date + '_' + times[t] + '_kcor_l2.fts', $
                         subdir=[date, 'level2'], $
                         root=run->config('processing/raw_basedir')), $
                      /silent)
endfor

im_total /= n_elements(times)

set_plot, 'X'

loadct, 0, /silent
gamma_ct, run->epoch('display_gamma'), /current
tvlct, red, green, blue, /get

display_factor = 1.0e6
scaled_image = bytscl((display_factor * im_total)^run->epoch('display_exp'), $
                      min=display_factor * run->epoch('display_min'), $
                      max=display_factor * run->epoch('display_max'))
mg_image, bytscl(scaled_image), /new

; create the NRGF file
;l2_zipped_files_glob = filepath('*_kcor_l2.fts.gz', $
;                                subdir=[date, 'level2'], $
;                                root=run->config('processing/raw_basedir'))
;l2_zipped_files = file_search(l2_zipped_files_glob, count=n_l2_zipped_files)
;kcor_create_averages, date, l2_zipped_files, run=run
;kcor_redo_nrgf, date, run=run

obj_destroy, run

end

