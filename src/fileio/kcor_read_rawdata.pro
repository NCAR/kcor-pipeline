; docformat = 'rst'

;+
; Routine to read raw KCor data and, optionally, repair it.
;
; :Params:
;   filename : in, required, type=string
;     raw FITS filename
;
; :Keywords:
;   image : out, optional, type="uintarr(1024, 1024, 4, 2)"
;     repaired image
;   header : out, optional, type=strarr
;     repaired header
;   start_state : in, optional, type=integer, default=lonarr(2)
;     start state by camera
;   repair_routine : in, optional, type=string
;     if present, repair routine will be called; interface is::
;
;       pro repair_routine, image=im, header=header
;
;     where `im` and `header` are inputs and outputs
;-
pro kcor_read_rawdata, filename, $
                       image=im, header=header, $
                       repair_routine=repair_routine, $
                       errmsg=errmsg, $
                       xshift=xshift, $
                       start_state=start_state, $
                       datatype=datatype, $
                       raw_data_prefix=raw_data_prefix, $
                       double=double
  compile_opt strictarr

  errmsg = ''

  case 1 of
    arg_present(im) && arg_present(header): begin
        if (keyword_set(raw_data_prefix)) then begin
          im = kcor_old_readfits(filename, header, errmsg=errmsg, datatype=datatype)
        endif else begin
          im = readfits(filename, header, /silent, errmsg=errmsg)
        endelse
      end
    arg_present(im): begin
        if (keyword_set(raw_data_prefix)) then begin
          im = kcor_old_readfits(filename, header, errmsg=errsg, datatype=datatype)
        endif else begin
          im = readfits(filename, /silent, errmsg=errmsg)
        endelse
      end
    arg_present(header): header = headfits(filename, errmsg=errmsg, /silent)
    else: return
  endcase

  if (arg_present(im) && n_elements(xshift) gt 0L) then begin
    for c = 0, 1 do begin
      if (xshift[c] ne 0L) then begin
        im[*, *, *, c] = shift(im[*, *, *, c], xshift[c], 0, 0)
      endif
    endfor
  endif

  if (arg_present(im) && (n_elements(start_state) gt 0L) && ~array_equal(start_state, lonarr(2))) then begin
    for c = 0L, 1L do begin
      im[*, *, *, c] = shift(im[*, *, *, c], 0, 0, start_state[c])
    endfor
  endif

  if (n_elements(repair_routine) gt 0L && repair_routine ne '') then begin
    call_procedure, repair_routine, image=im, header=header
  endif

  if (keyword_set(double)) then im = double(im)
end


; main-level example program

f = '/hao/corona3/Data/KCor/raw/2019/20191207/level0/20191207_214536_kcor.fts.gz'

; simple reading of file
kcor_read_rawdata, f, image=im, header=header, repair_routine='kcor_repair_mid2out'

; using the epochs file
date = '20191207'
config_basename = 'kcor.reprocess.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename, mode='test')

dt = strmid(file_basename(f), 0, 15)
run.time = string(strmid(dt, 0, 4), $
                  strmid(dt, 4, 2), $
                  strmid(dt, 6, 2), $
                  strmid(dt, 9, 2), $
                  strmid(dt, 11, 2), $
                  strmid(dt, 13, 2), $
                  format='(%"%s-%s-%sT%s:%s:%s")')

kcor_read_rawdata, f, image=img, header=header, $
                   repair_routine=run->epoch('repair_routine'), $
                   xshift=run->epoch('xshift_camera'), $
                   start_state=run->epoch('start_state'), $
                   raw_data_prefix=run->epoch('raw_data_prefix'), $
                   datatype=run->epoch('raw_datatype')

obj_destroy, run

end
