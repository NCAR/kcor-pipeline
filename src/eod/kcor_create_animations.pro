; docformat = 'rst'

;+
; Create one specific type of animations, e.g., enhanced average pB files.
;
; :Params:
;   gif_filenames : in, required, type=strarr
;     GIF filenames that comprise the frames of the animations
;   output_basename : in, required, type=string
;     basename of output file, i.e., without the ".gif" or ".mp4"
;   type : in, required, type=string
;     type of animation created, used for logs, e.g., "enhanced avg pB"
;
; :Keywords:
;   run : in, required, type=object
;     KCor run object
;-
pro kcor_create_animations_type, gif_filenames, output_basename, distribute_dir, $
                                 type, run=run
  compile_opt strictarr

  ; create animated GIF of files
  if (run->config('eod/create_animated_gifs')) then begin
    mg_log, 'creating %s animated GIF', type, name='kcor/eod', /info
    kcor_create_animated_gif, gif_filenames, output_basename + '.gif', $
                              run=run, status=status
    if (status eq 0 && run->config('realtime/distribute')) then begin
      file_copy, output_basename + '.gif', distribute_dir, /overwrite
    endif
  endif

  ; create mp4 of files
  mg_log, 'creating %s mp4', type, name='kcor/eod', /info
  kcor_create_mp4, gif_filenames, output_basename + '.mp4', $
                   run=run, status=status
  if (status eq 0 && run->config('realtime/distribute')) then begin
    file_copy, output_basename + '.mp4', distribute_dir, /overwrite
  endif
end


;+
; Create GIF and mp4 animations for the day.
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;
; :Keywords:
;   timestamps : in, required, type=strarr
;     timestamps for frames
;   run : in, required, type=object
;     `kcor_run` object
;-
pro kcor_create_animations, date, timestamps=timestamps, run=run
  compile_opt strictarr

  mg_log, 'creating animations', name='kcor/eod', /info

  date_parts = kcor_decompose_date(date)
  fullres_dir = filepath('', subdir=date_parts, $
                         root=run->config('results/fullres_basedir'))
  cropped_dir = filepath('', subdir=date_parts, $
                         root=run->config('results/croppedgif_basedir'))

  l2_dir = filepath('level2', subdir=date, root=run->config('processing/raw_basedir'))

  cd, current=current
  cd, l2_dir

  pb_gif_filenames = timestamps + '_kcor_l2_pb_avg.gif'
  pb_daily_basename = string(date, format='(%"%s_kcor_l2_pb_avg")')

  if (~file_test(fullres_dir, /directory)) then file_mkdir, fullres_dir

  kcor_create_animations_type, pb_gif_filenames, $
                               pb_daily_basename, $
                               fullres_dir, 'avg pB', run=run

  enhanced_pb_gif_filenames = timestamps + '_kcor_l2_pb_avg_enhanced.gif'
  enhanced_pb_daily_basename = string(date, format='(%"%s_kcor_l2_pb_avg_enhanced")')
  kcor_create_animations_type, enhanced_pb_gif_filenames, $
                               enhanced_pb_daily_basename, $
                               fullres_dir, 'enhanced avg pB', run=run

  if (~file_test(cropped_dir, /directory)) then file_mkdir, cropped_dir

  cropped_pb_gif_filenames = timestamps + '_kcor_l2_pb_avg_cropped.gif'
  cropped_pb_daily_basename = string(date, format='(%"%s_kcor_l2_pb_avg_cropped")')
  kcor_create_animations_type, cropped_pb_gif_filenames, $
                               cropped_pb_daily_basename, $
                               cropped_dir, 'cropped avg pB', run=run

  enhanced_cropped_pb_gif_filenames = timestamps + '_kcor_l2_pb_avg_cropped_enhanced.gif'
  enhanced_cropped_daily_basename = string(date, format='(%"%s_kcor_l2_pb_avg_cropped_enhanced")')
  kcor_create_animations_type, enhanced_cropped_pb_gif_filenames, $
                               enhanced_cropped_daily_basename, $
                               cropped_dir, 'cropped enhanced avg pB', run=run

  nrgf_gif_filenames = timestamps + '_kcor_l2_nrgf_avg.gif'
  nrgf_daily_basename = string(date, format='(%"%s_kcor_l2_nrgf_avg")')
  kcor_create_animations_type, nrgf_gif_filenames, $
                               nrgf_daily_basename, $
                               fullres_dir, 'avg NRGF', run=run

  enhanced_nrgf_gif_filenames = timestamps + '_kcor_l2_nrgf_avg_enhanced.gif'
  enhanced_nrgf_daily_basename = string(date, format='(%"%s_kcor_l2_nrgf_avg_enhanced")')
  kcor_create_animations_type, enhanced_nrgf_gif_filenames, $
                               enhanced_nrgf_daily_basename, $
                               fullres_dir, 'enhanced avg NRGF', $
                               run=run

  cropped_nrgf_gif_filenames = timestamps + '_kcor_l2_nrgf_avg_cropped.gif'
  cropped_nrgf_daily_basename = string(date, format='(%"%s_kcor_l2_nrgf_avg_cropped")')
  kcor_create_animations_type, cropped_nrgf_gif_filenames, $
                               cropped_nrgf_daily_basename, $
                               cropped_dir, 'cropped avg NRGF', $
                               run=run

  enhanced_cropped_nrgf_gif_filenames = timestamps + '_kcor_l2_nrgf_avg_cropped_enhanced.gif'
  enhanced_cropped_nrgf_daily_basename = string(date, format='(%"%s_kcor_l2_nrgf_avg_cropped_enhanced")')
  kcor_create_animations_type, enhanced_cropped_nrgf_gif_filenames, $
                               enhanced_cropped_nrgf_daily_basename, $
                               cropped_dir, 'cropped enhanced avg NRGF', $
                               run=run

  ; restore
  done:
  cd, current
  mg_log, 'done', name='kcor/eod', /info
end


; main-level example program

date = '20161127'
run = kcor_run(date, config_filename=filepath('kcor.latest.cfg', $
                                              subdir=['..', '..', 'config'], $
                                              root=mg_src_root()))

nrgf_list = filepath('oknrgf.ls', $
                     subdir=[date, 'level2'], $
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
