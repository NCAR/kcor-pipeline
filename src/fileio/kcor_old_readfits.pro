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
function kcor_old_readfits, filename, header
  compile_opt strictarr

  ; read header in the normal manner, if it is requested
  if arg_present(header) then header = headfits(filename, /silent)

  ; the offset of the data into the file is the size of the header, 2 blocks of
  ; 2880 bytes (FITS headers must be in multiples of 2880 bytes), plus the 4
  ; extra bytes
  offset = 2880L * 2L + 4L

  im = uintarr(1024, 1024, 4, 2)
  openr, lun, filename, /get_lun
  point_lun, lun, offset
  readu, lun, im
  free_lun, lun

  return, im
end
