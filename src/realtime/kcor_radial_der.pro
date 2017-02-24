; docformat = 'rst'

;+
; Procedure to interpolate radial scans in an image, take the derivative, and
; fit the maximum with a parabola to find the location of a discontinuity. This
; routine is used to find the location of the solar limb. The variable nscan
; below determined the number of radial scans. This routine differentiates
; between positive and negative discontinuities, depending on the input keyword
; neg_pol. Positive polarity is the default.  Modified from the function
; `COMP_RADIAL_DER`.
;
; :Returns:
;   the the array of radial positions is returned (pixels)

; :Params:
;   data : in, required
;     the data image to analyze
;   xcen : in, required, type=float
;     initial guess for x-coordindate of center in pixels
;   ycen : in, required, type=float
;     initial guess for y-coordindate of center in pixels
;   radius : in, required, type=float
;     initial guess for radius in pixels
;   dr : in, required, type=float
;     the region +/- around radius to make the scan (pixels)
;   theta : out, optional
;     the of array of angles used (radians)
;   cent : out, optional
;     the of array of inflection points marking the limb
;
; :Keywords:
;    nscan : in, optional, type=integer, default=360
;      number of radial scans
;    neg_pol : in, optional, type=boolean
;      this determines the polarity of the discontinuity, set neg_pol for
;      negative polarity
;
; :Author:
;  Tomczyk with modifications by de Toma 
;
; :History:
;   added comments, 10/24/14 ST
;   changed from function to procedure and to return full arrays  11/12/2014  GdT
;   changed nscan to keyword  11/12/2014  GdT
;   now requires initial guess  for xcen, ycen and radius   11/12/2014  GdT
;- 
pro kcor_radial_der, data, xcen, ycen, radius, dr, theta, cent, $
                     nscan=nscan, neg_pol=neg_pol, debug=debug
  compile_opt strictarr

  default, nscan, 180
  default, neg_pol, 0 
  default, debug, 0 

  theta = dblarr(nscan)
  cent  = dblarr(nscan)
  
  data = double(data)

  ; make initial guess of x and y positions the center of the array
  x0 = double(xcen)
  y0 = double(ycen)

  nvals = dr * 2   ;number of points in interpolated radial scan
  
  ; if debug eq 1 then tvwin,data
  
  ; make radial scans
  for i = 0L, nscan - 1L do begin
    theta[i] = double(i) * 2.0d * !dpi / double(nscan)   ; angle for radial scan

    ; x1 and y1 are start x and y coords; x2 and y2 are end coords
    x1 = x0 + (radius - dr) * cos(theta[i])
    y1 = y0 + (radius - dr) * sin(theta[i])
    x2 = x0 + (radius + dr) * cos(theta[i])
    y2 = y0 + (radius + dr) * sin(theta[i])

    dx = (x2 - x1) / double(nvals - 1)   ; dx and dy are spacing in x and y
    dy = (y2 - y1) / double(nvals - 1)

    ; xx and yy are x and y coords to interpolate onto for radial scan
    xx = dindgen(nvals) * dx + x1
    yy = dindgen(nvals) * dy +y1

    ; if debug eq 1 then plots, xx, yy, color=200, /device

    ; compute radial intensity scan
    rad = interpolate(data, xx, yy, cubic=-0.5, missing=0.0)

    ; take derivative of radial intensity scan
    rad = deriv(rad)

    ; change sign if negative polarity
    if (keyword_set(neg_pol)) then rad = -1.0 * rad

    ; find position of maximum derivative, imax
    mx = max(rad, imax)

    if (imax gt nvals - 3) then imax = nvals - 3
    if (imax lt 2) then imax = 2
    
    cent[i] = radius - dr $
                + parabola([double(imax - 1.), $
                            double(imax), $
                            double(imax + 1.)], $
                           [rad[imax - 1], $
                            rad[imax], $
                            rad[imax + 1]])
  endfor
end
