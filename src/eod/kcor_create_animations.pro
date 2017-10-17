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

  date_parts = kcor_decompose_date(date)
  fullres_dir = filepath('', subdir=date_parts, root=run.fullres_basedir)
  cropped_dir = filepath('', subdir=date_parts, root=run.croppedgif_basedir)
  if (run.distribute) then begin
    if (~file_test(fullres_dir, /directory)) then file_mkdir, fullres_dir
  endif

  l1_dir   = filepath('level1', subdir=date, root=run.raw_basedir)

  cd, current=current
  cd, l1_dir

  nrgf_gif_filenames = file_basename(nrgf_files, '.fts.gz') + '.gif'
  gif_filenames = file_basename(nrgf_files, '_l1_nrgf.fts.gz') + '.gif'
  cropped_nrgf_gif_filenames = file_basename(nrgf_files, '.fts.gz') + '_cropped.gif'
  cropped_gif_filenames = file_basename(nrgf_files, '_l1_nrgf.fts.gz') + '_cropped.gif'

  n_gif_filenames = n_elements(gif_filenames)

  nrgf_dailygif_filename = string(date, format='(%"%s_kcor_l1_nrgf.gif")')
  nrgf_dailymp4_filename = string(date, format='(%"%s_kcor_l1_nrgf.mp4")')
  cropped_nrgf_dailygif_filename = string(date, format='(%"%s_kcor_l1_nrgf_cropped.gif")')
  cropped_nrgf_dailymp4_filename = string(date, format='(%"%s_kcor_l1_nrgf_cropped.mp4")')

  dailygif_filename = string(date, format='(%"%s_kcor_l1.gif")')
  dailymp4_filename = string(date, format='(%"%s_kcor_l1.mp4")')
  cropped_dailygif_filename = string(date, format='(%"%s_kcor_l1_cropped.gif")')
  cropped_dailymp4_filename = string(date, format='(%"%s_kcor_l1_cropped.mp4")')


  ; create daily GIF of NRGF files
  cmd = string(run.convert, $
               strjoin(nrgf_gif_filenames, ' '), $
               nrgf_dailygif_filename, $
               format='(%"%s -delay 10 -loop 0 %s %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem creating NRGF daily GIF with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    goto, done
  endif else begin
    if (run.distribute) then begin
      file_copy, nrgf_dailygif_filename, fullres_dir, /overwrite
    endif
  endelse

  ; create daily mp4 of NRGF files
  cmd = string(run.ffmpeg, $
               date, $
               nrgf_dailymp4_filename, $
               format='(%"%s -r 20 -i %s_%%*_kcor_l1_nrgf.gif -y -loglevel error -vcodec libx264 -passlogfile kcor_nrgf_tmp -r 20 %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem creating NRGF daily mp4 with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    goto, done
  endif else begin
    if (run.distribute) then begin
      file_copy, nrgf_dailymp4_filename, fullres_dir, /overwrite
    endif
  endelse


  tmp_files = file_search('kcor_nrgf_tmp*', count=n_tmp_files)
  if (n_tmp_files gt 0L) then file_delete, tmp_files


  ; create daily GIF of L1 files
  cmd = string(run.convert, $
               strjoin(gif_filenames, ' '), $
               dailygif_filename, $
               format='(%"%s -delay 10 -loop 0 %s %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem creating daily GIF with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    goto, done
  endif else begin
    if (run.distribute) then begin
      file_copy, dailygif_filename, fullres_dir, /overwrite
    endif
  endelse


  ; create daily mp4 of L1 files
  tmp_gif_fmt = '(%"tmp-%04d.gif")'
  for f = 0L, n_gif_filenames - 1L do begin
    file_link, gif_filenames[f], string(f, format=tmp_gif_fmt)
  endfor

  cmd = string(run.ffmpeg, $
               dailymp4_filename, $
               format='(%"%s -r 20 -i tmp-%%*.gif -y -loglevel error -vcodec libx264 -passlogfile kcor_tmp -r 20 %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem creating daily mp4 with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    goto, done
  endif else begin
    if (run.distribute) then begin
      file_copy, dailymp4_filename, fullres_dir, /overwrite
    endif
  endelse


  tmp_files = file_search('tmp-*.gif', count=n_tmp_files)
  if (n_tmp_files gt 0L) then file_delete, tmp_files
  tmp_files = file_search('kcor_tmp*', count=n_tmp_files)
  if (n_tmp_files gt 0L) then file_delete, tmp_files


  ; create daily GIF of cropped NRGF GIF files
  cmd = string(run.convert, $
               strjoin(cropped_nrgf_gif_filenames, ' '), $
               cropped_nrgf_dailygif_filename, $
               format='(%"%s -delay 10 -loop 0 %s %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem creating cropped NRGF daily GIF with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    goto, done
  endif else begin
    if (run.distribute) then begin
      file_copy, cropped_nrgf_dailygif_filename, cropped_dir, /overwrite
    endif
  endelse

  ; create daily mp4 of cropped NRGF GIF files
  cmd = string(run.ffmpeg, $
               date, $
               cropped_nrgf_dailymp4_filename, $
               format='(%"%s -r 20 -i %s_%%*_kcor_l1_nrgf_cropped.gif -y -loglevel error -vcodec libx264 -passlogfile kcor_nrgf_tmp -r 20 %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem creating cropped NRGF daily mp4 with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    goto, done
  endif else begin
    if (run.distribute) then begin
      file_copy, cropped_nrgf_dailymp4_filename, cropped_dir, /overwrite
    endif
  endelse


  tmp_files = file_search('kcor_nrgf_tmp*', count=n_tmp_files)
  if (n_tmp_files gt 0L) then file_delete, tmp_files


  ; create daily GIF of cropped L1 GIF files
  cmd = string(run.convert, $
               strjoin(cropped_gif_filenames, ' '), $
               cropped_dailygif_filename, $
               format='(%"%s -delay 10 -loop 0 %s %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem creating daily cropped GIF with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    goto, done
  endif else begin
    if (run.distribute) then begin
      file_copy, cropped_dailygif_filename, cropped_dir, /overwrite
    endif
  endelse


  ; create daily mp4 of cropped L1 GIF files
  tmp_gif_fmt = '(%"tmp-%04d.gif")'
  for f = 0L, n_gif_filenames - 1L do begin
    file_link, cropped_gif_filenames[f], string(f, format=tmp_gif_fmt)
  endfor

  cmd = string(run.ffmpeg, $
               cropped_dailymp4_filename, $
               format='(%"%s -r 20 -i tmp-%%*.gif -y -loglevel error -vcodec libx264 -passlogfile kcor_tmp -r 20 %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem creating daily cropped mp4 with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    goto, done
  endif else begin
    if (run.distribute) then begin
      file_copy, cropped_dailymp4_filename, cropped_dir, /overwrite
    endif
  endelse


  tmp_files = file_search('tmp-*.gif', count=n_tmp_files)
  if (n_tmp_files gt 0L) then file_delete, tmp_files
  tmp_files = file_search('kcor_tmp*', count=n_tmp_files)
  if (n_tmp_files gt 0L) then file_delete, tmp_files


  ; restore
  done:
  for f = 0L, n_gif_filenames - 1L do file_delete, string(f, format=tmp_gif_fmt)
  cd, current
end


; main-level example program

date = '20161127'
run = kcor_run(date, config_filename=filepath('kcor.mgalloy.mahi.latest.cfg', $
                                              subdir=['..', '..', 'config'], $
                                              root=mg_src_root()))

nrgf_list = filepath('oknrgf.ls', $
                     subdir=[date, 'level1'], $
                     root=run.raw_basedir)

n_nrgf_files = file_test(nrgf_list) ? file_lines(nrgf_list) : 0L

if (n_nrgf_files gt 0L) then begin
  nrgf_files = strarr(n_nrgf_files)
  openr, lun, nrgf_list, /get_lun
  readf, lun, nrgf_files
  free_lun, lun

  kcor_create_animations, date, list=nrgf_files, run=run
endif

end
