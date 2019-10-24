; docformat = 'rst'


;+
; Create GIF and mp4 animations for the day.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   list : in, required, type=strarr
;     list of NRGF files to process
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_create_animations, date, list=nrgf_files, run=run
  compile_opt strictarr

  mg_log, 'creating animations', name='kcor/eod', /info

  ; turned off making GIFs right now
  create_gifs = 0B

  date_parts = kcor_decompose_date(date)
  fullres_dir = filepath('', subdir=date_parts, $
                         root=run->config('results/fullres_basedir'))
  cropped_dir = filepath('', subdir=date_parts, $
                         root=run->config('results/croppedgif_basedir'))
  if (run->config('realtime/distribute')) then begin
    if (~file_test(fullres_dir, /directory)) then file_mkdir, fullres_dir
  endif

  l1_dir = filepath('level1', subdir=date, root=run->config('processing/raw_basedir'))

  cd, current=current
  cd, l1_dir

  nrgf_gif_filenames = file_basename(nrgf_files, '.fts.gz') + '.gif'
  gif_filenames = file_basename(nrgf_files, '_nrgf.fts.gz') + '.gif'
  cropped_nrgf_gif_filenames = file_basename(nrgf_files, '.fts.gz') + '_cropped.gif'
  cropped_gif_filenames = file_basename(nrgf_files, '_nrgf.fts.gz') + '_cropped.gif'

  n_gif_filenames = n_elements(gif_filenames)

  nrgf_dailygif_filename = string(date, format='(%"%s_kcor_l1.5_nrgf.gif")')
  nrgf_dailymp4_filename = string(date, format='(%"%s_kcor_l1.5_nrgf.mp4")')
  cropped_nrgf_dailygif_filename = string(date, format='(%"%s_kcor_l1.5_nrgf_cropped.gif")')
  cropped_nrgf_dailymp4_filename = string(date, format='(%"%s_kcor_l1.5_nrgf_cropped.mp4")')

  dailygif_filename = string(date, format='(%"%s_kcor_l1.5.gif")')
  dailymp4_filename = string(date, format='(%"%s_kcor_l1.5.mp4")')
  cropped_dailygif_filename = string(date, format='(%"%s_kcor_l1.5_cropped.gif")')
  cropped_dailymp4_filename = string(date, format='(%"%s_kcor_l1.5_cropped.mp4")')

  ; create daily GIF of NRGF files
  if (create_gifs) then begin
    mg_log, 'creating NRGF GIF', name='kcor/eod', /info
    kcor_create_animated_gif, nrgf_gif_filenames, nrgf_dailygif_filename, $
                              run=run, status=status
    if (status eq 0 && run->config('realtime/distribute')) then begin
      file_copy, nrgf_dailygif_filename, fullres_dir, /overwrite
    endif
  endif

  ; create daily mp4 of NRGF files
  mg_log, 'creating NRGF mp4', name='kcor/eod', /info
  kcor_create_mp4, nrgf_gif_filenames, nrgf_dailymp4_filename, $
                   run=run, status=status
  if (status eq 0 && run->config('realtime/distribute')) then begin
    file_copy, nrgf_dailymp4_filename, fullres_dir, /overwrite
  endif

  ; create daily GIF of L1 files
  if (create_gifs) then begin
    mg_log, 'creating L1.5 GIF', name='kcor/eod', /info
    kcor_create_animated_gif, gif_filenames, dailygif_filename, $
                              run=run, status=status
    if (status eq 0 && run->config('realtime/distribute')) then begin
      file_copy, dailygif_filename, fullres_dir, /overwrite
    endif
  endif

  ; create daily mp4 of L1 files
  mg_log, 'creating L1.5 mp4', name='kcor/eod', /info
  kcor_create_mp4, gif_filenames, dailymp4_filename, run=run, status=status
  if (status eq 0 && run->config('realtime/distribute')) then begin
    file_copy, dailymp4_filename, fullres_dir, /overwrite
  endif

  ; create daily GIF of cropped NRGF GIF files
  if (create_gifs) then begin
    mg_log, 'creating cropped NRGF GIF', name='kcor/eod', /info
    kcor_create_animated_gif, cropped_nrgf_gif_filenames, $
                              cropped_nrgf_dailygif_filename, $
                              run=run, status=status
    if (status eq 0 && run->config('realtime/distribute')) then begin
      file_copy, cropped_nrgf_dailygif_filename, cropped_dir, /overwrite
    endif
  endif

  ; create daily mp4 of cropped NRGF GIF files
  mg_log, 'creating cropped NRGF mp4', name='kcor/eod', /info
  kcor_create_mp4, cropped_nrgf_gif_filenames, cropped_nrgf_dailymp4_filename, $
                   run=run, status=status
  if (status eq 0 && run->config('realtime/distribute')) then begin
    file_copy, cropped_nrgf_dailymp4_filename, cropped_dir, /overwrite
  endif

  ; create daily GIF of cropped L1 GIF files
  if (create_gifs) then begin
    mg_log, 'creating cropped L1.5 GIF', name='kcor/eod', /info
    kcor_create_animated_gif, cropped_gif_filenames, $
                              cropped_dailygif_filename, $
                              run=run, status=status 
    if (status eq 0 && run->config('realtime/distribute')) then begin
      file_copy, cropped_dailygif_filename, cropped_dir, /overwrite
    endif
  endif

  ; create daily mp4 of cropped L1 GIF files
  mg_log, 'creating cropped L1.5 mp4', name='kcor/eod', /info
  kcor_create_mp4, cropped_gif_filenames, cropped_dailymp4_filename, $
                   run=run, status=status
  if (status eq 0 && run->config('realtime/distribute')) then begin
    file_copy, cropped_dailymp4_filename, cropped_dir, /overwrite
  endif

  ; restore
  done:
  cd, current
  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

date = '20161127'
run = kcor_run(date, config_filename=filepath('kcor.mgalloy.mahi.latest.cfg', $
                                              subdir=['..', '..', 'config'], $
                                              root=mg_src_root()))

nrgf_list = filepath('oknrgf.ls', $
                     subdir=[date, 'level1'], $
                     root=run->config('processing/raw_basedir'))

n_nrgf_files = file_test(nrgf_list) ? file_lines(nrgf_list) : 0L

if (n_nrgf_files gt 0L) then begin
  nrgf_files = strarr(n_nrgf_files)
  openr, lun, nrgf_list, /get_lun
  readf, lun, nrgf_files
  free_lun, lun

  kcor_create_animations, date, list=nrgf_files, run=run
endif

end
