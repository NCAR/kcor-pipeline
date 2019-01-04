; docformat = 'rst'

;+
; Read a calibration file listing and return the filenames.
;
; :Returns:
;   strarr
;
; :Params:
;   date : in, required, type=string
;     date in the form 'YYYYMMDD'
;   process_basedir : in, required, type=string
;     process base directory
;
; :Keywords:
;   exposures : out, optional, type=strarr
;     set to a named variable to retrieve the exposures matching the filenames
;     returned
;   n_files : out, optional, type=long
;     set to a named variable to retrieve the number of filenames returned
;-
function kcor_read_calibration_text, date, process_basedir, $
                                     exposures=exposures, $
                                     n_files=n_files, $
                                     all_files=filenames, $
                                     n_all_files=n_all_files, $
                                     quality=quality, $
                                     run=run

  compile_opt strictarr

  cal_file = filepath('calibration_files.txt', $
                      subdir=date, $
                      root=process_basedir)

  if (~file_test(cal_file)) then begin
    n_files = 0L
    n_all_files = 0L
    return, !null
  endif

  n_files = file_lines(cal_file)
  n_all_files = n_files
  if (n_files lt 1) then return, !null

  text = strarr(n_files)

  openr, lun, cal_file, /get_lun
  readf, lun, text
  free_lun, lun

  filenames = strarr(n_files)
  exposures = strarr(n_files)
  quality   = lonarr(n_files)

  angle_values = findgen(9) / 8.0 * 180.0

  for i = 0L, n_files - 1L do begin
    tokens = strsplit(text[i], /extract)
    filenames[i] = tokens[0]
    exposures[i] = tokens[1]

    file_date = strmid(tokens[0], 0, 8)
    file_time = strmid(tokens[0], 9, 6)
    run.time = file_time

    ; use GBU params file, if specified for epoch
    gbuparams_basename = run->epoch('gbuparams_filename')
    if (n_elements(gbuparams_basename) eq 0L) then begin
      quality[i] = 99L * run->epoch('process') * run->epoch('use_calibration_data')
    endif else begin
      date_parts = long(kcor_decompose_date(file_date))
      time_parts = long(kcor_decompose_time(file_time))

      sun, date_parts[0], $
           date_parts[1], $
           date_parts[2], $
           time_parts[0] + time_parts[1] / 60.0 + time_parts[2] / 3600.0, $
           dist=sunearth_dist

      dark = tokens[6] eq 'in'                              ; dark in
      flat = (tokens[8] eq 'in') && (tokens[10] eq 'out')   ; diff in, cal out

      means = reform(float(tokens[14:21]) * sunearth_dist^2, 4, 2)

      gbuparams_filename = filepath(gbuparams_basename, subdir='..', root=mg_src_root())
      restore, filename=gbuparams_filename

      quality[i] = 99.0
      case 1 of
        dark: begin
            for p = 0, 3 do begin
              for c = 0, 1 do begin
                range = dark_mean_stddev[c, 0] + 2.0 * [-1.0, 1.0] * dark_mean_stddev[c, 1]
                if ((means[p, c] lt range[0]) || (means[p, c] gt range[1])) then begin
                  mg_log, 'mean (%0.1f) outside of range [%0.1f, %0.1f]', $
                          means[p, c], range[0], range[1], $
                          name='kcor/eod', /debug
                  quality[i] = 0.0
                endif
              endfor
            endfor
          end
        flat: begin
            for p = 0, 3 do begin
              for c = 0, 1 do begin
                range = flat_mean_stddev[c, 0] + 2.0 * [-1.0, 1.0] * flat_mean_stddev[c, 1]
                if ((means[p, c] lt range[0]) || (means[p, c] gt range[1])) then begin
                  mg_log, 'mean (%0.1f) outside of range [%0.1f, %0.1f]', $
                          means[p, c], range[0], range[1], $
                          name='kcor/eod', /debug
                  quality[i] = 0.0
                endif
              endfor
            endfor
          end
        else: begin
            angle = float(tokens[12])
            !null = min(angle_values - angle, calpol_angle_index)
            calpol_angle_index mod= 8   ; 180.0 degrees is same as 0.0 degrees
            for p = 0, 3 do begin
              for c = 0, 1 do begin
                gbu_mean = calpol_mean_stddev[c, calpol_angle_index, p, 0]
                gbu_stddev = calpol_mean_stddev[c, calpol_angle_index, p, 1]
                range = gbu_mean + 2.0 * [-1.0, 1.0] * gbu_stddev
                if ((means[p, c] lt range[0]) || (means[p, c] gt range[1])) then begin
                  mg_log, 'mean (%0.1f) outside of range [%0.1f, %0.1f]', $
                          means[p, c], range[0], range[1], $
                          name='kcor/eod', /debug
                  quality[i] = 0.0
                endif
              endfor
            endfor
          end
      endcase
    endelse
  endfor

  return, filenames[where(quality ge run->epoch('min_cal_quality'), n_files, /null)]
end


; main-level example program

date = '20181021'
config_filename = filepath('kcor.mgalloy.kaula.production.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
help, run->epoch('gbuparams_filename')
;filenames = kcor_read_calibration_text(date, run.process_basedir, $
;                                       exposures=exposures, n_files=n_files, run=run)
;obj_destroy, run

end
