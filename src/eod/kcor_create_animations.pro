; docformat = 'rst'

;+
; Create GIF and MPEG animations for the day.
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

  l1_dir   = filepath('level1', subdir=date, root=run.raw_basedir)

  cd, current=current
  cd, l1_dir

  nrgf_gif_filenames = file_basename(nrgf_files, '.fts.gz') + '.gif'
  gif_filenames = file_basename(nrgf_files, '_l1_nrgf.fts.gz') + '.gif'

  nrgf_dailygif_filename = string(date, format='(%"%s_kcor_l1_nrgf.gif")')
  nrgf_dailympeg_filename = string(date, format='(%"%s_kcor_l1_nrgf.mp4")')

  dailygif_filename = string(date, format='(%"%s_kcor_l1.gif")')
  dailympeg_filename = string(date, format='(%"%s_kcor_l1.mp4")')


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
  endif

  ; create daily MPEG of NRGF files
  cmd = string(run.ffmpeg, $
               date, $
               nrgf_dailympeg_filename, $
               format='(%"%s -r 25 -i %s_%%*_kcor_l1_nrgf.gif -y -loglevel error -vcodec libx264 -passlogfile kcor_nrgf_tmp -r 25 %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem creating NRGF daily MP4 with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    goto, done
  endif

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
  endif

  ; create daily MPEG of L1 files
  cmd = string(run.ffmpeg, $
               date, $
               dailympeg_filename, $
               format='(%"%s -r 25 -i %s_%%*_kcor.gif -y -loglevel error -vcodec libx264 -passlogfile kcor_tmp -r 100 %s")')
  spawn, cmd, result, error_result, exit_status=status
  if (status ne 0L) then begin
    mg_log, 'problem creating daily MP4 with command: %s', cmd, $
            name='kcor/eod', /error
    mg_log, '%s', strjoin(error_result, ' '), name='kcor/eod', /error
    goto, done
  endif

  tmp_files = file_search('kcor_tmp*', count=n_tmp_files)
  if (n_tmp_files gt 0L) then file_delete, tmp_files


  ; restore
  done:
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
