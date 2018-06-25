; docformat = 'rst'

;+
; Draw a circle at 1.0 Rsun.
;
; xdim : in
;   x-axis dimension
; ydim : in
;   y-axis dimension
; xcen : in
;   x-axis center
; ycen : in
;   y-axis center
; xb : in
;   x-axis border for annotation
; yb : in
;   y-axis border for annotation
; pixrs : in
;   pixels/solar radius
; roll : in
;   roll angle (solar north w.r.t. +Y axis, CCW=positive).
;
; :History:
;   Andrew L. Stanger   HAO/NCAR   23 November 2004
;   11 Feb 2005 [ALS]: Do NOT draw a circle at 1.1 Rsun.
;   21 May 2015 derived from suncir_mk4.pro.
;-
pro kcor_suncir, xdim, ydim, xcen, ycen, xb, yb, pixrs, roll, log_name=log_name
  compile_opt strictarr

  mg_log, 'dims=[%d, %d], center=[%0.2f, %0.2f]', $
          xdim, ydim, xcen, ycen, $
          name=log_name, /debug
  mg_log, 'xb=%d, yb=%d, pixels/R_sun=%0.2f, roll=%0.2f', $
          xb, yb, pixrs, roll, $
          name=log_name, /debug

  white  = 255
  red    = 254
  green  = 253
  blue   = 252
  grey   = 251
  yellow = 250
  black  =   0

  r       = 1.0
  r1min   = 0.2		; radial inner limit for major lines.
  r1max   = 1.0		; radial outer limit for major lines.
  r1inc   = 0.2		; radial  increment between major lines
  ang1inc = 30.0        ; angular increment between major lines.

  r2min   = 0.2		; radial inner limit for major lines.
  r2max   = 0.8		; radial outer limit for major lines.
  r2inc   = 0.1		; radial  increment between major lines
  ang2inc = 90.0        ; angular increment between major lines.

  ;print, 'pixrs: ', pixrs

  ; sun center location

  xg = fix(xcen + xb + 0.5)
  yg = fix(ycen + yb + 0.5)
  rp = fix(pixrs / 10.0 + 0.5) - 1
  rp = rp * (pixrs / 160.0)

  if (pixrs lt 120.0) then begin
    ; draw "+ mark at sun center
    plots, xg - rp, yg,      /device, color=white
    plots, xg - 1,  yg,      /device, color=white, /continue
    
    plots, xg + 1,  yg,      /device, color=white
    plots, xg + rp, yg,      /device, color=white, /continue

    plots, xg,      yg - rp, /device, color=white
    plots, xg,      yg - 1,  /device, color=white, /continue

    plots, xg,      yg + 1,  /device, color=white
    plots, xg,      yg + rp, /device, color=white, /continue
  endif

  if (pixrs ge 120.0) then begin
    ; draw a triangle with a base on the equator
    plots, xg - rp,     yg,      /device, color=white
    plots, xg,          yg + rp, /device, color=white, /continue

    plots, xg + 1,      yg + rp, /device, color=white
    plots, xg + rp + 1, yg,      /device, color=white, /continue

    plots, xg - rp,     yg,      /device, color=white
    plots, xg - 1,      yg,      /device, color=white, /continue

    plots, xg + 2,      yg,      /device, color=white
    plots, xg + rp + 1, yg,      /device, color=white, /continue

    ; draw a vertical line below the triangle
    plots, xg,          yg - rp, /device, color=white
    plots, xg,          yg - 1,  /device, color=white, /continue

    plots, xg + 1,      yg - rp, /device, color=white
    plots, xg + 1,      yg - 1,  /device, color=white, /continue

    plots, xg,          yg + 2,  /device, color=white
    plots, xg + 1,      yg + 2,  /device, color=white, /continue
  endif

   ; draw a triangle with a base 10 pixels above the equator
  ;   PLOTS, xg,    yg+1,  /device, color=white
  ;   PLOTS, xg,    yg+7,  /device, color=white, /continue

  ;   PLOTS, xg,    yg+8,  /device, color=white
  ;   PLOTS, xg,    yg+10, /device, color=white, /continue

  ;   PLOTS, xg-5,  yg+10, /device, color=white
  ;   PLOTS, xg,    yg+15, /device, color=white, /continue

  ;   PLOTS, xg,    yg+15, /device, color=white
  ;   PLOTS, xg+5,  yg+10, /device, color=white, /continue

  ;   PLOTS, xg-5,  yg+10, /device, color=white
  ;   PLOTS, xg+5,  yg+10, /device, color=white, /continue

   ; draw radial scans every 30 degrees
  for th = 0.0, 360.0, ang1inc do begin
    for radius = r1min, r1max*1.01, r1inc do begin
      ierr = rcoord(radius, th, x, y, 1, roll, xcen, ycen, pixrs)
      xg = fix(x + xb + 0.5)
      yg = fix(y + yb + 0.5)
      plots, xg, yg, /device, color=white
      plots, xg, yg, /device, color=white, /continue
      ;	 print, 'radius/th: ', radius, th, ' x/y: ', x, y
    endfor
  endfor

  ; draw radial scans every 90 degrees
  for th = 0.0, 360.0, ang2inc do begin
    for radius = r2min, r2max*1.01, r2inc do begin
      ierr = rcoord(radius, th, x, y, 1, roll, xcen, ycen, pixrs)
      xg = fix(x + xb + 0.5)
      yg = fix(y + yb + 0.5)
      plots, xg, yg, /device, color=white
      plots, xg, yg, /device, color=white, /continue
      plots, xg, yg, /device, color=white
      plots, xg, yg, /device, color=white, /continue
    endfor
  endfor

  ; draw a circle at 1.0 Rsun:  one dot every 5 degrees
  r = 1.0
  for th = 0, 360, 5 do begin
    ierr = rcoord (r, th, x, y, 1, roll, xcen, ycen, pixrs)
    xg = fix(x + xb + 0.5)
    yg = fix(y + yb + 0.5)
    plots, xg,   yg,   /device, color=white
    plots, xg,   yg,   /device, color=white, /continue
    plots, xg,   yg,   /device, color=white
    plots, xg,   yg,   /device, color=white, /continue
  endfor

  ; draw a circle at 1.0 Rsun: one BOLD dot every 10 degrees
  r = 1.0
  for th = 0, 360, 10 do begin
    ierr = rcoord(r, th, x, y, 1, roll, xcen, ycen, pixrs)
    xg = fix(x + xb + 0.5)
    yg = fix(y + yb + 0.5)
    ; PLOTS, xg,   yg,   /device, color=white
    ; PLOTS, xg,   yg,   /device, color=white, /continue

    plots, xg - 1, yg - 1, /device, color=white
    plots, xg + 1, yg - 1, /device, color=white, /continue
    plots, xg + 1, yg + 1, /device, color=white, /continue
    plots, xg - 1, yg + 1, /device, color=white, /continue
    plots, xg - 1, yg - 1, /device, color=white, /continue
  endfor

   ; draw a circle at 1.1 Rsun: one dot every 30 degrees

  ;   r = 1.1
  ;   FOR th = 0, 360, 30 DO			$
  ;   BEGIN ;{
  ;      ierr = rcoord (r, th, x, y, 1, roll, xcen, ycen, pixrs)
  ;      xg = FIX (x + xb + 0.5)
  ;      yg = FIX (y + yb + 0.5)
  ;      PLOTS, xg,   yg,   /device, color=white
  ;      PLOTS, xg,   yg,   /device, color=white, /continue
  ;      PLOTS, xg,   yg,   /device, color=white
  ;      PLOTS, xg,   yg,   /device, color=white, /continue
  ;   END   ;}

  ; draw a circle at 3.0 Rsun

  r3 = pixrs * 3.0
  ; tvcircle, r3, xcen, ycen, color=254, /device

  ; draw a circle at 3.0 Rsun: one BOLD dot every 30 degrees

  r = 3.02
  for th = 0, 360, 30 do begin
    ierr = rcoord(r, th, x, y, 1, roll, xcen, ycen, pixrs)
    xg = fix(x + xb + 0.5)
    yg = fix(y + yb + 0.5)
    ; PLOTS, xg,   yg,   /device, color=white
    ; PLOTS, xg,   yg,   /device, color=white, /continue

    ; PLOTS, xg-3, yg-3, /device, color=white
    ; PLOTS, xg+3, yg-3, /device, color=white, /continue
    ; PLOTS, xg+3, yg+3, /device, color=white, /continue
    ; PLOTS, xg-3, yg+3, /device, color=white, /continue
    ; PLOTS, xg-3, yg-3, /device, color=white, /continue
    ; PLOTS, xg+3, yg+3, /device, color=white, /continue
  endfor

  ; draw a circle at 3.0 Rsun: one BOLD dot every 10 degrees

  r = 3.02
  for th = 0, 360, 10 do begin
    ierr = rcoord(r, th, x, y, 1, roll, xcen, ycen, pixrs)
    xg = fix(x + xb + 0.5)
    yg = fix(y + yb + 0.5)
    ; PLOTS, xg,   yg,   /device, color=white
    ; PLOTS, xg,   yg,   /device, color=white, /continue
    plots, xg - 1, yg - 1, /device, color=white
    plots, xg + 1, yg - 1, /device, color=white, /continue
    plots, xg + 1, yg + 1, /device, color=white, /continue
    plots, xg - 1, yg + 1, /device, color=white, /continue
    plots, xg - 1, yg - 1, /device, color=white, /continue
  endfor
end
