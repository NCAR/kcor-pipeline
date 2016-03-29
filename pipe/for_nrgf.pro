pro for_nrgf,image,xctr,yctr,r0,imgflt
;+
; NAME:
;   NRGF
;
; PURPOSE:
;   Apply the Normalized Radial Graded Filter (NRGF) for removing the
;   radial gradient from coronal images to reveal coronal structures.
;
; CALLING SEQUENCE:
;   NRGF, image, xctr, yctr, r0, imgflt
;
; INPUTS:
;
;   image:  The image to be filtered.  This value must be a 2D array.
;   xctr:   x-axis coordinate of the center of the solar disk's image.
;   yctr:   y-axis coordinate of the center of the solar disk's image.
;   r0:     initial radius of the image to be filtered.
;
; OUTPUTS:
;   imgflt: The filtered image.  
;           This is an array with the same dimensions of "image".
;
; COMMON BLOCKS:
;   None.
;
; SIDE EFFECTS:
;   None.
;
; RESTRICTIONS:
;   None.
;
; PROCEDURE:
;   Straightforward.
;
; Called by FOR_PLOT
;
; Written by Silvano Fineschi and Sarah Gibson
;
; MODIFICATION HISTORY:
; vers. 0. 	S. Fineschi, 06 April, 2006.
; vers. 1;	S. Fineschi, 11 April, 2006
; vers. 2;	S. Fineschi, 14 April, 2006
; vers. 3; for_nrgf	S. Gibson 19 May 2014
; Changes: 
; 1) fixed bug(?) where r_min compared to r_w twice
; 2) made r dimensions same as image dimensions 
;   (not necessarily 1024X1024 - bug?)
; 3) commented out printing and plotting commands
; 4) found integer (round) value of r_o,r_min in loop
;    so that program could handle non-integer input
;    for central pixel and r0
; 5) rescaled if smaller than 1024X1024
;
; Version 2.0 July 2014
;-

;device,decomposed = 0 ; Handle TrueColor displays:

;--- Dimensions of the input image.

; image = float (image)

xdim = n_elements (image [*, 0])
ydim = n_elements (image [0, *])

; If resolution is too low, won't work.

mult     = 1.0
imagenew = image

if (xdim lt 1024.0) then $
begin ;{
  xdim_orig = xdim
  ydim_orig = ydim

  mult = 1024.0 / xdim
  mult = fix (mult)
  xdim = mult * xdim
  ydim = mult * ydim
  xctr = xctr * mult
  yctr = yctr * mult
  r0   = r0   * mult
  imagenew = congrid (image, xdim, ydim)
endif ;}

;print, xdim, ydim
;
; Coordinates of the Sun-disk's center.
; for example:
;    xctr = 528
;    yctr = 457

;--- Determine the min radii from the Sun-disk's center to the image's edge.

r_n = ydim - yctr
r_e = xctr
r_s = yctr
r_w = xdim - xctr

;print, 'r_n  =  ', r_n
;print, 'r_e  =  ', r_e
;print, 'r_s  =  ', r_s
;print, 'r_w  =  ', r_w

r_max = max ([r_n, r_e, r_s, r_w])
r_min = min ([r_n, r_e, r_s, r_w])

;print, 'r_max  =  ', r_max
;print, 'r_min  =  ', r_min

r0 = fix (r0)
r_min = fix (r_min)

r     = lonarr (xdim, ydim)       ; Radial distances between the Sun-disk center
                                  ; and the two-dimensional array locations.
imgflt = fltarr (xdim, ydim)       ; Output fitered image.
dim_r  = fltarr (r_min - r0 + 1)   ; Number of points on the circles with radii 
                                   ; "r" | r0 < r < r_min.
iavg_r = fltarr (r_min - r0 + 1)   ; Average intensities of the points on the 
                                   ; circles with radii "r".
sdev_r = fltarr (r_min - r0 + 1)   ; Intensities' standard deviations of the 
                                   ; points on the circles with radii "r".
var_r  = fltarr (r_min - r0 + 1)   ; Intensities' variances of the  points on 
                                   ; the circles with radii "r".

;--- Calculate the distances between the Sun-disk center 
;    and the two-dimensional array locations.

r = fix (shift (dist (xdim, ydim), xctr, yctr))

for i = r0, r_min do $
begin ;{

   ;--- Calculate the number and the one-dimensional array locations
   ;    of the points with same distance "i" from the Sun-disk center.

    points_r = where (r EQ i, count)
    dim_r [i-r0] = count

;	print, 'count  =  ', count

   ;--- Use ARRAY_INDICES to convert the one-dimensional array location 
   ;    to a two-dimensional array location.

    coord_r = array_indices (r, points_r)

   ;--- Compute the radial mean intensity and variance.

    points = imagenew [coord_r [0, *], coord_r [1, *]]
    test = where (points EQ -8888.0 OR points EQ -9999.0)
    if (min (test) ne -1) then points [test] = 1.0 / 0.0
    result = moment (points, /nan)

    iavg_r [i - r0] = result [0]           ; store the radial mean intensity
    sdev_r [i - r0] = sqrt (result [1])    ; store the radial standard deviation

   ;--- Compute the normalized radial graded intensity.

;    imgflt [coord_r [0, *], coord_r [1, *]] = $
;       abs (imagenew [coord_r [0, *], coord_r [1, *]] - iavg_r [i - r0]) $
;       / sdev_r [i - r0]

    imgflt [coord_r [0, *], coord_r [1, *]] = $
       (imagenew [coord_r [0, *], coord_r [1, *]] - iavg_r [i - r0]) $
       / sdev_r [i - r0]

;    imgflt [coord_r [0, *], coord_r [1, *]] = $
;       (imagenew [coord_r [0, *], coord_r [1, *]] - iavg_r [i - r0])

endfor ;}

fmin = MIN (imgflt)
fmax = MAX (imgflt)

print, 'fmin/fmax: ', fmin, fmax

;--- Remove spikes.

imgflt = imgflt < 4
imgflt = imgflt > (-2)

;--- Display filtered image.

ws = 512
ws = 1024

;read, 'Set Window Size  =  ',ws
;
; window, /FREE, retain = 2
; plot_io,  sdev_r, linestyle = 2
; oplot,  iavg_r
;
;img = congrid (imgflt, ws, ws)
;xoff = 10
;yoff = 10
;window, /FREE, xsize = (size (img)) [1] + xoff, $
;               ysize = (size (img)) [2] + xoff, xpos = 200, retain = 2
;
;TVSCL, img, xoff - xoff / 2.0, yoff - yoff / 2.0
;
;PROFILES, img

if (mult GT 1.0) then imgflt = congrid (imgflt, xdim_orig, ydim_orig)

end
