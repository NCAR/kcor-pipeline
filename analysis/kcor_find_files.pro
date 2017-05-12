; docformat = 'rst'

;+
; Find L1 files between the given dates.
;
; :Returns:
;   `strarr(n_files)`
;
; :Params:
;   start_jd : in, required, type=double
;     start date/time in Julian days
;   end_jd : in, required, type=double
;     end date/time in Julian days
;
; :Keywords:
;   root : in, optional, type=string, default='/hao/acos'
;     default root of directory hierarchy
;   n_days : out, optional, type=long
;     set to a named variable to retrieve the number of days in the time period
;     requested
;   n_files : out, optional, type=long
;     set to a named variable to retrieve the number of files in the time period
;     requested
;-
function kcor_find_files, start_jd, end_jd, $
                          root=root, $
                          n_days=n_days, $
                          n_files=n_files
  compile_opt strictarr

  _root = n_elements(root) eq 0L ? '/hao/acos' : root

  ; find number of days between start day and end day
  caldat, start_jd, start_month, start_day, start_year
  _start_jd = julday(start_month, start_day, start_year)
  caldat, end_jd, end_month, end_day, end_year
  _end_jd = julday(end_month, end_day, end_year)
  n_days = long(_end_jd - _start_jd + 1.0D)

  result_list = list()
  n_files = 0L

  for d = 0L, n_days - 1L do begin
    caldat, start_jd + d, month, day, year

    l1_files = file_search(filepath('*_*_kcor_l1.fts.gz', $
                                    subdir=string(year, month, day, $
                                                  format='(%"%04d/%02d/%02d")'), $
                                    root='/hao/acos'), $
                           count=n_l1_files)
    if (n_l1_files eq 0L) then continue

    l1_basenames = file_basename(l1_files)
    if (d eq 0L) then begin
      hours = long(strmid(l1_basenames, 9, 2))
      mins  = long(strmid(l1_basenames, 11, 2))
      secs  = long(strmid(l1_basenames, 13, 2))
      jds = julday(month, day, year, hours, mins, secs)

      ind = where(jds ge start_jd, count)
      if (count gt 0L) then begin
        result_list->add, l1_files[ind], /extract
        n_files += count
      endif
    endif else if (d eq n_days - 1L) then begin
      hours = long(strmid(l1_basenames, 9, 2))
      mins  = long(strmid(l1_basenames, 11, 2))
      secs  = long(strmid(l1_basenames, 13, 2))
      jds = julday(month, day, year, hours, mins, secs)

      ind = where(jds le end_jd, count)
      if (count gt 0L) then begin
        result_list->add, l1_files[ind], /extract
        n_files += count
      endif
    endif else begin
      result_list->add, l1_files, /extract
      n_files += n_l1_files
    endelse
  endfor

  result = result_list->toArray()
  obj_destroy, result_list
  return, result
end


; main-level example program

files = kcor_find_files(julday(5, 9, 2017, 21, 47, 14), $
                        julday(5, 11, 2017, 17, 03, 17), $
                        n_files=n_files, n_days=n_days)
help, n_files, n_days

end
