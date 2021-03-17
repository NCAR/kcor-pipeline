; docformat = 'rst'

;+
; Replacement for READFITS for old KCor raw FITS files with an extra 4 bytes at
; the beginning of the data that must be skipped.
;
; :Returns:
;   `uintarr(1024, 1024, 4, 2)`
;
; :Params:
;   filename : in, required, type=string
;     raw filename
;   header : out, optional, type=strarr
;     set to a named variable to retrieve the FITS header as a string array
;-
function kcor_old_readfits, filename, header, errmsg=errmsg, datatype=datatype
  compile_opt strictarr
  on_ioerror, bad_file

  errmsg = ''

  ext = strmid(filename, strpos(filename, '.', /reverse_search) + 1L)
  compress = strlowcase(ext) eq 'gz'

  ; read header in the normal manner, if it is requested
  header = headfits(filename, /silent)

  ; the offset of the data into the file is the size of the header, 2 blocks of
  ; 2880 bytes (FITS headers must be in multiples of 2880 bytes), plus the 4
  ; extra bytes
  offset = 2880L * 2L + 4L

  _datatype = n_elements(datatype) eq 0L ? 12 : datatype  ; 12 = uint
  im = make_array(1024, 1024, 4, 2, type=_datatype)
  openr, lun, filename, /get_lun, compress=compress, /swap_if_little_endian
  point_lun, lun, offset
  readu, lun, im
  free_lun, lun

  bzero = sxpar(header, 'BZERO', count=n_bzero)

  im -= uint(bzero)

  sxaddpar, header, 'BZERO', 0
  sxaddpar, header, 'O_BZERO', bzero, ' Original BZERO Value'

  return, im

  bad_file:
  if (arg_present(errmsg)) then begin
    errmsg = !error_state.msg
  endif else begin
    print, !error_state.msg
  endelse

  return, im
end
