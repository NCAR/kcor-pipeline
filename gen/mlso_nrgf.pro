; docformat = 'rst'

;+
; Apply the Normalized Radial Graded Filter (NRGF) for removing the radial
; gradient from coronal images to reveal coronal structures.
;
; :Returns:
;   filtered image, the same dimensions as `im`
;
; :Params:
;   im : in, required, type="fltarr(m, n)"
;     the image to be filtered
;   xctr : in, required, type=float
;     x-axis coordinate of the center of the solar disk's image
;   yctr : in, required, type=float
;     y-axis coordinate of the center of the solar disk's image
;   r0 : in, required, type=float
;     initial radius of the image to be filtered
;
; :Keywords:
;   mean_r : out, optional, type=fltarr(r_min - r0 + 1)
;     set to a named variable to retrieve the radial means
;   sdev_r : out, optional, type=fltarr(r_min - r0 + 1)
;     set to a named variable to retrieve the radial standard deviations
;   min_value : in, optional, type=float, default=-2.0
;     theshold values below this minimum value
;   max_value : in, optional, type=float, default=4.0
;     theshold values above this maximum value
;
; :Author:
;   Written by Silvano Fineschi and Sarah Gibson
;
; :History:
;   vers. 0:  S. Fineschi, 06 April, 2006.
;   vers. 1:  S. Fineschi, 11 April, 2006
;   vers. 2:  S. Fineschi, 14 April, 2006
;   vers. 3:  for_nrgf S. Gibson 19 May 2014
;   Changes:
;     1) fixed bug(?) where r_min compared to r_w twice
;     2) made r dimensions same as image dimensions (not necessarily 1024x1024
;        - bug?)
;     3) commented out printing and plotting commands
;     4) found integer (round) value of r_o,r_min in loop so that program could
;        handle non-integer input for central pixel and r0
;     5) rescaled if smaller than 1024X1024
;
;   Version 2.0 July 2014
;-
function mlso_nrgf, im, xctr, yctr, r0, $
                    radius=radius, mean_r=iavg_r, sdev_r=sdev_r, $
                    min_value=min_vlaue, max_value=max_value
  compile_opt strictarr

  _min_value = n_elements(min_value) eq 0L ? -2.0 : max_value
  _max_value = n_elements(max_value) eq 0L ? 4.0 : max_value

  ; dimensions of the input image
  dims = size(im, /dimensions)
  xdim = dims[0]
  ydim = dims[1]

  ; if resolution is too low, won't work
  mult     = 1.0
  _im = im
  if (xdim lt 1024.0) then begin
    xdim_orig = xdim
    ydim_orig = ydim

    mult = 1024.0 / xdim
    mult = fix(mult)
    xdim *= mult
    ydim *= mult
    xctr *= mult
    yctr *= mult
    r0   *= mult
    _im = congrid(im, xdim, ydim)
  endif

  ; determine the min radii from the Sun-disk's center to the image's edge
  r_n = ydim - yctr
  r_e = xctr
  r_s = yctr
  r_w = xdim - xctr

  r_max = max([r_n, r_e, r_s, r_w])
  r_min = min([r_n, r_e, r_s, r_w])

  r0 = fix(r0)
  r_min = fix(r_min)

  ; radial distances between the Sun-disk center and the two-dimensional array
  ; locations
  r      = lonarr(xdim, ydim)

  ; output fitered image
  output = fltarr(xdim, ydim)

  ; number of points on the circles with radii "r" | r0 < r < r_min
  dim_r  = fltarr(r_min - r0 + 1)

  ; average intensities of the points on the circles with radii "r"
  iavg_r = fltarr(r_min - r0 + 1)

  ; intensities' standard deviations of the points on the circles with radii "r"
  sdev_r = fltarr(r_min - r0 + 1)

  ; intensities' variances of the points on the circles with radii "r"
  var_r  = fltarr(r_min - r0 + 1)

  ; calculate the distances between the Sun-disk center and the two-dimensional
  ; array locations.
  r = fix(shift(dist(xdim, ydim), xctr, yctr))

  radius = findgen(r_min - r0 + 1) + r0
  for i = r0, r_min do begin
    ; calculate the number and the one-dimensional array locations of the
    ; points with same distance "i" from the Sun-disk center
    points_r = where(r eq i, count)
    dim_r[i - r0] = count

    ; use ARRAY_INDICES to convert the one-dimensional array location to a
    ; two-dimensional array location.
    coord_r = array_indices(r, points_r)

    ; compute the radial mean intensity and variance
    points = _im[coord_r [0, *], coord_r[1, *]]
    nan_indices = where(points eq -8888.0 or points eq -9999.0, /null)
    points[nan_indices] = !values.f_nan
    moments = moment(points, /nan)

    iavg_r[i - r0] = moments[0]          ; store the radial mean intensity
    sdev_r[i - r0] = sqrt(moments[1])    ; store the radial standard deviation

    ; compute the normalized radial graded intensity
    output[coord_r [0, *], coord_r[1, *]] = $
       (_im[coord_r[0, *], coord_r[1, *]] - iavg_r[i - r0]) $
       / sdev_r[i - r0]

    ; output[coord_r [0, *], coord_r [1, *]] = $
    ;    abs(_im[coord_r [0, *], coord_r[1, *]] - iavg_r[i - r0]) $
    ;    / sdev_r [i - r0]

    ; output[coord_r[0, *], coord_r [1, *]] = $
    ;    (_im[coord_r[0, *], coord_r[1, *]] - iavg_r[i - r0])
  endfor

  ; remove spikes
  output = _max_value < output > _min_value

  if (mult gt 1.0) then output = congrid(output, xdim_orig, ydim_orig)

  return, output
end
