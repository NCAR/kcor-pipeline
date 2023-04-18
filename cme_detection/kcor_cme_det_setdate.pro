; docformat = 'rst'

;+
; Change variables in common block that depend on current date.
;
; :Params:
;   date : in, required, type=string
;     date in the form "YYYYMMDD"
;-
pro kcor_cme_det_setdate, date
  compile_opt strictarr
  @kcor_cme_det_common

  simple_date = date
  ymd = kcor_decompose_date(date)

  datedir = filepath('', subdir=ymd, root=kcor_dir)

  ; make sure that the output directories exist
  hpr_out_dir = filepath('', subdir=ymd, root=kcor_hpr_dir)
  if (keyword_set(store) and not file_exist(hpr_out_dir)) then begin
    file_mkdir, hpr_out_dir
  endif

  diff_out_dir = filepath('', subdir=ymd, root=kcor_hpr_diff_dir)
  if (keyword_set(store) and not file_exist(diff_out_dir)) then begin
    file_mkdir, diff_out_dir
  endif

  cme_detection_params_filename = filepath(string(date, format='%s.kcor.cme-params.txt'), $
                                           root=hpr_out_dir)
end
