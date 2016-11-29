pro lct, lutname

;+
;-------------------------------------------------------------------------------
; NAME
; lct
;-------------------------------------------------------------------------------
; PURPOSE
; Load colormap from disk file.
;-------------------------------------------------------------------------------
; SYNTAX
; lct, 'grey.lut'
; color table is stored as ASCII numbers [0-255]; each line: index, R, G, B.
;-------------------------------------------------------------------------------
; AUTHOR
; Andrew L. Stanger	HAO/NCAR
;-------------------------------------------------------------------------------
; HISTORY
; 19 Apr 1995 IDL procedure created.
; 15 Jun 2015 Use get_lun.
;-------------------------------------------------------------------------------
;-

;--- Declare storage variables.

index = bytarr (256)
red   = bytarr (256)
green = bytarr (256)
blue  = bytarr (256)

c = byte (0)
r = byte (0)
g = byte (0)
b = byte (0)

; --- Read colormap from ASCII file with the format:
;     (4I4), index, red, green, blue

get_lun, FID
openr,   FID, lutname

for i = 0, 255 do $
begin

   readf, FID, c, r, g, b
   index (i) = c
   red   (i) = r
   green (i) = g
   blue  (i) = b

endfor

; --- Write RGB values to colormap.

tvlct, red, green, blue

free_lun, FID

end
