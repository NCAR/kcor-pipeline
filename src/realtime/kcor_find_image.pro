; docformat = 'rst'

;+
; Find either the edge of the occulting disk. Modified from the CoMP pipeline
; routine `comp_find_image.pro`.
;
; :Returns:
;   A 3-element array is returned containing the x_center, y_center and radius
;   of the occulter
;
; :Params:
;    data : in, out, required
;      the data array in which to locate the image
;    radius_guess : in, required
;      the guess of the radius based on the occulter size
;
; :Keywords:
;   center_guess : in, optional
;     guess for the center coordinates. if set uses horizontal/vertical scans
;     to guess center if not set uses center of the array
;   drad : in, optional, type=float
;     the +/- size of the radius which to scan
;   neg_pol : in, optional, type=boolean
;     if set, negative discontinuities will be found
;   chisq : out, optional, type=float
;     set to a named variable to retrieve the chi^2
;   log_name : in, required, type=string
;     name of log to send log messages to
;   xoffset : in, optional, type=float, default=0.0
;     optional offset for x-value of center
;   yoffset : in, optional, type=float, default=0.0
;     optional offset for y-value of center
;   offset_xyr : out, optional, type=fltarr(3)
;     set to a named variable to retrieve the center offset by `XOFFSET` and
;     `YOFFSET`
;   max_center_difference : in, optional, type=float, default=40.0
;     max difference (in both the x- and y-direction) that the center guess can
;     move from the center of the image when using `CENTER_GUESS`
;
; :Uses:
;   kcor_radial_der, fitcircle
;
; :Author:
;   Tomczyk
;   Modified by de Toma
;
; :History:
;   changed to double precision to find derivative correctly 11/07/2014 GdT
;   added radius_guess as input  11/07/2014 GdT
;   added keyword center_guess  11/07/2014 GdT
;   changed to fitcircle because faster 11/12/2014 GdT
;-
function kcor_find_image, data, radius_guess, $
                          center_guess=center_guess, $
                          drad=drad, $
                          chisq=chisq, $
                          debug=debug, $
                          xoffset=xoffset, $
                          yoffset=yoffset, $
                          offset_xyr=offset_xyr, $
                          max_center_difference=max_center_difference, $
                          log_name=log_name
  compile_opt strictarr

  default, debug, 0
  default, center_guess, 0
  default, drad, 40

  _max_center_difference = n_elements(max_center_difference) eq 0L $
                             ? 40.0 %
                             : max_center_difference

  data = double(data)

  if (debug eq 1) then begin
    datamax = 25000
    if (max(data) lt datamax) then datamax = 2000
    window, xsize=1024, ysize=1024, retain=2
    loadct, 0
    tv, bytscl(data, 0, datamax)
    wait, 1
  endif

  isize = size(data)
  xdim = isize[1]
  ydim = isize[2]

  xcen = fix((float(xdim) * 0.5 ) - 0.5)
  ycen = fix((float(ydim) * 0.5 ) - 0.5)

  if (keyword_set(center_guess)) then begin 
    ; find guess coordinates for the image center

    ; extract coords
    xtest  = data[*, ycen]
    xtest2 = data[*, ycen - 50]
    xtest3 = data[*, ycen + 50]
    ytest  = data[xcen - 60, *]
    ytest2 = data[xcen + 60, *]

    xmaxl = max(xtest[0:xcen], xl)
    xmaxr = max(xtest[xcen:xdim - 1], xr)
    xr += xcen
    xmaxl = max(xtest2[0:xcen], xl2)
    xmaxr = max(xtest2[xcen:xdim - 1], xr2)
    xr2 += xcen
    xmaxl = max(xtest3[0:xcen], xl3)
    xmaxr = max(xtest3[xcen:xdim - 1], xr3)
    xr3 += xcen

    ymaxb = max(ytest[0:ycen], yb)
    ymaxt = max(ytest[ycen:ydim - 1], yt)
    yt += ycen
    ymaxb = max(ytest2[0:ycen], yb2)
    ymaxt = max(ytest2[ycen:ydim - 1], yt2)
    yt2 += ycen

    xcen_guess = (xl + (xr - xl) * 0.5 + xl2 + (xr2 - xl2) * 0.5 + xl3 + (xr3 - xl3) * 0.5) / 3.0
    ycen_guess = (yb + (yt - yb) * 0.5 + yb2 + (yt2 - yb2) * 0.5) * 0.5

    ; if center is more than _max_center_difference pixels off the center of the
    ; array, use center of the array
    if (abs(xcen_guess - xcen) ge _max_center_difference) then xcen_guess = xcen
    if (abs(ycen_guess - ycen) ge _max_center_difference) then ycen_guess = ycen

    if (debug eq 1) then begin 
      !p.multi = [0, 1, 4]
      plot, xtest, charsize=2
      plot, xtest3, charsize=2
      plot, ytest, charsize=2
      plot, ytest2, charsize=2
      !p.multi = 0
      wait, 1
    endif
  endif else begin
    xcen_guess = xcen
    ycen_guess = ycen
  endelse

  if (debug eq 1) then begin 
    loadct, 0
    tv, bytscl(data, 0, datamax)
    loadct, 39
    draw_circle, xcen_guess, ycen_guess, radius_guess, /device, color=50, thick=2
    wait, 1
  endif

  ; find limb positions, array of angles (theta) and limb positions (cent) 
  ; needs double precision for KCor
  kcor_radial_der, data, xcen_guess, ycen_guess, radius_guess, drad, theta, cent

  ; find circle that fits the inflaction points
  x = cent * cos(theta)
  x = transpose(x)
  y = cent * sin(theta)
  y = transpose(y)
  fitcircle, x, y, xc, yc, r

  ; Check if fitting routine failed. If so, try fitting using larger radius
  ; range if it fails again, replace fit values with array center and
  ; radius_guess
  if (finite(xc) eq 0 or finite(yc) eq 0) then begin
    mg_log, 'center not found, trying larger range', name=log_name, /warn
    drad = 52
    kcor_radial_der, data, xcen_guess, ycen_guess, radius_guess, drad, theta, cent
    x = cent * cos(theta)
    x = transpose(x)
    y = cent * sin(theta)
    y = transpose(y)
    fitcircle, x, y, xc, yc, r
    if (finite(xc) eq 0 or finite(yc) eq 0) then begin
      xc = 511.5 - xcen_guess
      yc = 511.5 - ycen_guess
      r = radius_guess
      mg_log, 'center not found, using defaults', $
              name=log_name, /warn
    endif
  endif

  a = [xcen_guess + xc, ycen_guess + yc, r]

  if (debug eq 1) then begin
    loadct, 0
    tv, bytscl(data, 0, datamax)
    loadct, 39
    draw_circle, a[0], a[1], a[2], /device, color=250, thick=1
    print, xcen_guess, ycen_guess, radius_guess
    print, xc, yc, r
    print, a 
  endif

  if (arg_present(offset_xyr)) then begin
    offset_xyr = a
    offset_xyr[0] += n_elements(xoffset) gt 0L ? xoffset : 0.0
    offset_xyr[1] += n_elements(yoffset) gt 0L ? yoffset : 0.0
  endif

  return, a
end
