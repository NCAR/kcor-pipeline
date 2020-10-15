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
;   start_state : in, optional, type=integer, default=0
;     start state
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
                       raw_data_prefix=raw_data_prefix
  compile_opt strictarr

  errmsg = ''

  case 1 of
    arg_present(im) && arg_present(header): begin
        if (keyword_set(raw_data_prefix)) then begin
          im = kcor_old_readfits(filename, header)
        endif else begin
          im = readfits(filename, header, /silent)
        endelse
      end
    arg_present(im): begin
        if (keyword_set(raw_data_prefix)) then begin
          im = kcor_old_readfits(filename, header)
        endif else begin
          im = readfits(filename, /silent)
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

  if (arg_present(im) && n_elements(start_state) gt 0L && start_state ne 0L) then begin
    im = shift(im, 0, 0, start_state, 0)
  endif

  if (n_elements(repair_routine) gt 0L && repair_routine ne '') then begin
    call_procedure, repair_routine, image=im, header=header
  endif
end


; main-level example program

f = '/hao/mlsodata1/Data/KCor/raw/20191207/level0/20191207_214536_kcor.fts.gz'
kcor_read_rawdata, f, image=im, header=header, repair_routine='kcor_repair_mid2out'

end
