; docformat = 'rst'

;+
; Determine occulter size in arcsec.
;
; :Params:
;   occulter_id : in, required, type=string
;     occulter ID from FITS header
;
; :Keywords:
;   run : in, required, type=object
;     `kcor_run` object
;-
function kcor_get_occulter_size, occulter_id, run=run
  compile_opt strictarr

  if (run->epoch('use_default_occulter_size') || occulter_id eq 'GRID') then begin
    ; beginning of mission occulter ID was OC-1
    return, run->epoch('default_occulter_size')
  endif else begin
    ; later days use the first 8 characters to lookup in epoch file
    return, run->epoch(strmid(occulter_id, 0, 8))
  endelse
end


; main-level example program

date = '20210413'
config_filename = filepath('kcor.reprocess.cfg', $
                           subdir=['..', '..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)
basename = '20210413_174423_kcor.fts.gz'
filename = filepath(basename, $
                    subdir=[date, 'level0'], $
                    root=run->config('processing/raw_basedir'))
kcor_read_rawdata, filename, header=header, $
                   repair_routine=run->epoch('repair_routine'), $
                   xshift=run->epoch('xshift_camera'), $
                   start_state=run->epoch('start_state'), $
                   raw_data_prefix=run->epoch('raw_data_prefix'), $
                   datatype=run->epoch('raw_datatype')

if (run->epoch('use_occulter_id')) then begin
  occltrid = sxpar(header, 'OCCLTRID', count=qoccltrid)
endif else begin
  occltrid = run->epoch('occulter_id')
endelse

occulter_size = kcor_get_occulter_size(occltrid, run=run)

obj_destroy, run

end
