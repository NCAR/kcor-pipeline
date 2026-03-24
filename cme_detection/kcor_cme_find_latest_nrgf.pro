; docformat = 'rst'

;+
; Returns the fullpath to the latest NRGF GIF file.
;
; :Returns:
;   string fullpath filename of the latest NRGF GIF
;
; :Params:
;   current_time : in, optional, type=string
;     current time as returned from `kcor_cme_current_time`, in the format
;     "YYYY-MM-DDTHH:MM:SSZ"
;   age : in, optional, type=float
;     age [seconds] that the latest NRGF is from `current_time`, requires
;     `current_time` to be set
;-
function kcor_cme_find_latest_nrgf, current_time, age=age
  compile_opt strictarr
  @kcor_cme_det_common

  ; find latest NRGF image
  glob = filepath('*_kcor_l2_nrgf.gif', $
                  subdir=kcor_decompose_date(simple_date), $
                  root=run->config('results/nrgf_basedir'))
  nrgf_filenames = file_search(glob, count=n_nrgf_files)

  latest_nrgf_filename = n_nrgf_files eq 0L ? !null : nrgf_filenames[-1]

  ; if the caller wants the age of the latest NRGF file, they must also pass
  ; the current time
  if (arg_present(age) && (n_elements(current_time) gt 0L)) then begin
    current_time_jd = kcor_dateobs2julian(current_time)

    primary_header = headfits(latest_nrgf_filename, exten=0)
    latest_nrgf_dateobs = sxpar(primary_header, 'DATE-OBS')
    latest_nrgf_jd = kcor_dateobs2julian(latest_nrgf_dateobs)

    age = (current_time_jd - latest_nrgf_jd) * 24.0 * 60.0 * 60.0
  endif
end
