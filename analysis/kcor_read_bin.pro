; docformat = 'rst'

;+
; Read a KCor binary file.
;
; :Params:
;   filename : in, required, type=string
;     filename of ".bin" file
;-
function kcor_read_bin, filename
  compile_opt strictarr

  byte_size = 16782976
  bin_im = intarr(byte_size / 2)

  openr, lun, f, /get_lun
  readu, lun, bin_im
  free_lun, lun

  bin_im = bin_im[2880:*]
  bin_im = reform(bin_im, 1024, 1024, 4, 2)
  bin_im = uint(bin_im + 32768L)

  return, bin_im
end
