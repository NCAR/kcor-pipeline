; docformat = 'rst'

;=============================================================================
;       reg.cpp         register a sequence of 1 or more images
;       A 2D cross correlation is computed with respect to a reference image;
;       the position of the maximum is interpolated for sub-pixel position;
;       the positions are collected into a table of control (tile) points;
;       a B-spline surface is fitted to these tile points; and finally
;       the scene is resampled on the non-uniform grid.
;
;       The above may be accomplished with the function 'reg' (below).
; For example, the following IDL code should do the job:
;
;       ...
;       sequence = bytarr (256,256,200) ; series of 2D arrays to destretch
;       readu, unit, sequence           ; get'um into memory
;       ref = sequence (*,*,0)          ; select reference frame
;       kernel = bytarr (15,15)         ; select kernel (tile) size
;       destretched = reg (sequence, ref, kernel) ; doit - result will be
;       ...                             ; same size fltarr as input sequence
;
;       We have used the method iteratively, with successively
;       smaller kernel sizes (suggest 64^2, 40^2, 25^2 for 256^2 images).
;       We have also had better luck if the entire image is first correlation
;       tracked.  More recently (26 Sep 90) refinements have been added
;       that permit successful use of a small kernal, one time (i.e.,
;       iteration should be unnecessary).
;
;       The implementation consists of several routines that are intended
;       to be user callable, to give the user control over such things as
;       updateing the reference scene.  For this, the reader's attention is
;       called to the routines:
;
;       mkcps   to compute reference control point coordinates (one time)
;       cps     to compute the offsets for current scene from reference
;       repair  to repair control point displacements
;       doreg   to apply destretch to scene, which may become the
;               new reference.
;
;       Debug plots are generated and various debug print statements
;       to trace the progress through the package.  The package works, but
;       somewhat ungracefully on a tektronix compatible terminal, as well
;       as on a sun workstation. 
;       The plots are not crucial, though they give some indication of how
;       well the tracking is doing.
;
;       For more information contact:
;
;       Phil Wiborg
;       National Solar Observatory
;       Sun Spot, NM 88349
;       505-434-7000
;       pwiborg@sunspot.noao.edu
;       or
;       Thomas Rimmele
;       Kiepenheuer Institut f"ur 
;       Sonnenphysik
;       7800 Freiburg
;       0761-3198-0
;       tr@kis.uni-freiburg.de
;=============================================================================


;+
; Bilinear interpolation of scene, s.
;-
function mlso_registration_bilinear, s, xy, nearest_neighbor=nearest_neighbor
  ; All control info is passed between support programs via common block
  common reg_com, kx, ky,         $ ; kernel x,y size (16,16)
                  wx, wy,         $ ; wander limits (32,32)
                  bx, by,         $ ; boundary x,y size (4,4)
                  cpx, cpy,       $ ; control point x,y size (7,4)
                  debug             ; = 0   silent operation
                                    ; = 1   TV_FLG
                                    ; = 2   GRD_FLG
                                    ; = 4   PRT_FLG

  ; if ((debug and 4) ne 0) then print, 'bilin'

  if (keyword_set(nearest_neighbor)) then begin   ; nearest neighbor
    x = fix(xy[*, *, 0] + 0.5)
    y = fix(xy[*, *, 1] + 0.5)
    ans = s[x, y]
  endif else begin            ; bilinear
    x = xy[*, *, 0]
    y = xy[*, *, 1]

    x0 = fix(x)
    x1 = fix(x + 1)
    y0 = fix(y)
    y1 = fix(y + 1)

    fx = x mod 1.0
    fy = y mod 1.0

    ss = float(s)

    ; original (slow) version
    ;    ssfx = (ss[x1, y0] - ss[x0, y0]) * fx
    ;    ans = ssfx $
    ;            + (ss[x0, y1] - ss[x0, y0]) * fy $
    ;            + ((ss[x1, y1] - ss[x0, y1]) * fx - ssfx) * fy $
    ;            + ss[x0, y0]

    ; optimized version
    ss00 = ss[x0, y0]
    ss01 = ss[x0, y1]
    ssfx = (ss[x1, y0] - ss00) * fx
    ans  = ss00 + ssfx + (ss01 - ss00 + (ss[x1, y1] - ss01) * fx - ssfx) * fy
  endelse

  return, ans
end


function mlso_registration_patch, compx, compy, s, t
  compile_opt strictarr

  ans = fltarr(n_elements(s), n_elements(t), 2)
  ss = reform([s^3, s^2, s, replicate(1.0, n_elements(s))], n_elements(s), 4)
  tt = transpose(reform([t^3, t^2, t, replicate(1.0, n_elements(t))], $
                        n_elements(t), 4))
  ans[*, *, 0] = ss # compx # tt
  ans[*, *, 1] = ss # compy # tt

  return, ans
end


;+
; Extend reference and actual displacements to cover whole scene.
;-
pro mlso_registration_extend, r, d, rd, sd
  compile_opt strictarr

  dsz = size(d)
  ns = dsz[1] + 6
  nt = dsz[2] + 6

  rd = fltarr(ns, nt)
  dif = r[1, 0] - r[0, 0]
  zro = r[0, 0] - 3 * dif
  z = findgen(ns) * dif + zro
  for j = 0L, nt - 1L do rd[*, j] = z

  sd = fltarr(ns, nt)
  sd[3:ns - 4, 3:nt - 4] = d - r

  x = sd[*, 3]
  sd[*, 0] = x
  sd[*, 1] = x
  sd[*, 2] = x
  x = sd[*, nt - 4]
  sd[*, nt - 3] = x
  sd[*, nt - 2] = x
  sd[*, nt - 1] = x
  sd = transpose(sd)

  x = sd[*, 3]
  sd[*, 0] = x
  sd[*, 1] = x
  sd[*, 2] = x
  x = sd[*, ns - 4]
  sd[*, ns - 3] = x
  sd[*, ns - 2] = x
  sd[*, ns - 1] = x
  sd = transpose(sd)

  sd += rd
end


;+
; destretch scene using B-splines
; (Foley & Van Dam: pp 521-536.)
;
; scene(nx,ny), image to be destretched
; r, d(2,*,*),  reference and actual displacements of control points
;
; returns coordinates for scene(nx,ny) destretch
;-
function mlso_registration_bspline, scene, r, dd
  compile_opt strictarr
  ; All control info is passed between support programs via common block
  common reg_com, kx, ky,         $ ; kernel x,y size (16,16)
                  wx, wy,         $ ; wander limits (32,32)
                  bx, by,         $ ; boundary x,y size (4,4)
                  cpx, cpy,       $ ; control point x,y size (7,4)
                  debug             ; = 0   silent operation
                                    ; = 1   TV_FLG
                                    ; = 2   GRD_FLG
                                    ; = 4   PRT_FLG

  ;if ((debug and 4) ne 0) then print, 'B-spline'

  always = 1      ; exterior control points drift with interior (best)
  ;always = 0     ; exterior control points fixed by ref. displacements

  ; a kludgery: increases magnitude of error, since
  ; curve doesn't generally pass through the tie pts.
  d = (dd - r) * 1.1 + r

  ds = r[0, 1, 0] - r[0, 0, 0]
  dt = r[1, 0, 1] - r[1, 0, 0]

  dsz = size(d)

  ; extend r & d to cover entire image. Two possible methods:
  if (always) then begin
    ; (1) this method lets boundry drift with actual displacements at
    ;     edges of 'd' table.

    ns = dsz[2]
    nt = dsz[3]
    mlso_registration_extend, reform(r[0, *, *], ns, nt), $
                              reform(d[0, *, *], ns, nt), $
                              Rx, Px
    mlso_registration_extend, transpose(reform(r[1, *, *], ns, nt)), $
                              transpose(reform(d[1, *, *], ns, nt)), $
                              Ry, Py
    Ry = transpose(Ry)
    Py = transpose(Py)

  endif else begin
    ; (0) this (eariler) method fixes boundry of image to 'r' reference
    ;     displacements.
    ns = dsz[2] + 6
    nt = dsz[3] + 6

    Px = fltarr(ns, nt)
    s0 = r[0, 0, 0] - 3 * ds
    z = findgen(ns) * ds + s0
    for j = 0L, nt - 1L do Px[*, j] = z
    Rx = Px
    Px[3:ns - 4, 3:nt - 4] = d[0, *, *]

    Py = fltarr(ns, nt)
    t0 = r[1, 0, 0] - 3 * dt
    z = findgen(nt) * dt + t0
    for i = 0L, ns - 1L do Py[i, *] = z
    Ry = Py
    Py[3:ns - 4, 3:nt - 4] = d[1, *, *]
  endelse

  Ms = [-1, 3,- 3, 1, 3, -6, 0, 4, -3, 3, 3, 1, 1, 0, 0, 0] / 6.0
  Ms = reform(Ms, 4, 4)
  MsT = transpose(Ms)

  sz = size(scene)
  nx = sz[1]
  ny = sz[2]

  ans = fltarr(nx, ny, 2)
  for v = 0L, dsz[3] + 3 do begin
    t0 = Ry[1, v + 1]
    tn = Ry[1, v + 2]
    if ((tn le 0) or (t0 ge ny - 1)) then goto, nextv
    t0 = max([t0, 0])
    tn = min([tn, ny - 1])
    t = findgen(tn - t0) / dt + (t0 - Ry[1, v + 1]) / dt
    for u = 0, dsz[2] + 3 do begin
      s0 = Rx[u + 1, v + 1]
      sn = Rx[u + 2, v + 1]
      if ((sn le 0) or (s0 ge nx - 1)) then goto, nextu
      s0 = max([s0, 0])
      sn = min([sn, nx - 1])
      s = findgen(sn - s0) / ds + (s0 - Rx[u + 1, v + 1]) / ds
      compx = reform(Ms # Px[u:u + 3, v:v + 3] # MsT, 4, 4)
      compy = reform(Ms # Py[u:u + 3, v:v + 3] # MsT, 4, 4)
      ans[s0:sn - 1, t0:tn - 1, *] = mlso_registration_patch(compx, compy, s, t)

      ;;lk:disabled plots
      ;;        if ((debug and 2) ne 0) and (u gt 0) and (v gt 0) then begin
      ;;            plots, reform(ans(s0,t0,*),2,1), /dev, psym=7
      ;;            wait,0.
      ;;       endif

      nextu:
    endfor
    nextv:
  endfor

  return, ans
end


function mlso_registration_mask, nx, ny
  compile_opt strictarr

  ;m   = bytarr(nx/2,ny/2)+1
  ;mm  = bytarr(nx,ny)
  ;mm(0:nx/2-1,0:ny/2-1) = m
  ;mm  = shift(mm,nx/4,ny/4)

  ; only good, if nx eq ny!
  ;z = shift(dist(nx), nx/2,nx/2)
  ;mm = exp(-(z/(nx/1.5))^2)
  ;mm = exp(-(z/(nx/2))^2)

  ; like above, for any nx,ny gt 1
  x = findgen(nx)
  x = exp(-(shift(x < (nx - x), nx / 2)/(nx / 2))^2)
  y = findgen(ny)
  y = exp(-(shift(y < (ny - y), ny / 2) / (ny / 2))^2)
  mm = x # y

  ;  this one takes edges to essentially 0.
  ;x = findgen (nx)
  ;x = 1./(1.+exp(.5*(nx/4 - x)))* 1./(1.+exp(.5*(x - nx*3/4)))
  ;y = findgen (ny)
  ;y = 1./(1.+exp(.5*(ny/4 - y)))* 1./(1.+exp(.5*(y - ny*3/4)))
  ;mm = x # y

  return, mm
end


function mlso_registration_smouth, nx, ny
  compile_opt strictarr

  x = findgen(nx / 2)
  if (nx mod 2) then x = [x, x(nx / 2 - 1), rotate(x, 2)] else x = [x, rotate(x, 2)]
  x = exp(-(x / (nx / 6 > 10))^2)
  y = findgen(ny / 2)
  if (ny mod 2) then y = [y, y(ny / 2 - 1), rotate(y, 2)] else y = [y, rotate(y, 2)]
  y = exp(-(y / (ny / 6 > 10))^2)
  mm = x # y

  return, mm
end


function mlso_registration_doref, ref, mask        ; setup reference window

; ref   reference image (*,*)           (in)
; mask                                  (in)

; Returns:
; win   reorganized window              (out)

; All control info is passed between support programs via common block
common reg_com, kx, ky,         $; kernel x,y size (16,16)
                wx, wy,         $; wander limits (32,32)
                bx, by,         $; boundary x,y size (4,4)
                cpx, cpy,       $; control point x,y size (7,4)
                debug           ; = 0   silent operation
                                ; = 1   TV_FLG
                                ; = 2   GRD_FLG
                                ; = 4   PRT_FLG

;if ((debug and 4) ne 0) then print, 'doref'

win = complexarr (wx, wy, cpx, cpy)
nelz = wx*wy
ly = by
hy = ly + wy - 1
for j = 0, cpy-1 do begin
    lx = bx
    hx = lx + wx - 1
    for i = 0, cpx-1 do begin
        z = ref(lx:hx, ly:hy)
        z = z - total(z)/nelz
        win(*,*,i,j) = conj (fft (z*mask, -1))

        lx = lx + kx
        hx = hx + kx
        endfor
    ly = ly + ky
    hy = hy + ky
    endfor

return, win

end


function mlso_registration_cploc, s, w, mask, smou ; locate control points

; s(*,*) scene to be registered
; w(*,*,*,*) reference image, from doref
; mask
; smou

; All control info is passed between support programs via common block
common reg_com, kx, ky,         $; kernel x,y size (16,16)
                wx, wy,         $; wander limits (32,32)
                bx, by,         $; boundary x,y size (4,4)
                cpx, cpy,       $; control point x,y size (7,4)
                debug           ; = 0   silent operation
                                ; = 1   TV_FLG
                                ; = 2   GRD_FLG
                                ; = 4   PRT_FLG

;if ((debug and 4) ne 0) then print, 'cploc'

ans = fltarr(2,cpx,cpy) ; gets the results

nels = wx*wy

; setup gradient correction
;   added by Friedrich Woeger
tx = rebin((findgen(wx)/(wx-1) - 0.5)*2.0, wx, wy)
ty = rebin((transpose(findgen(wy))/(wy-1) - 0.5)*2.0, wx, wy)
nnx= total(tx*tx)
nny= total(ty*ty)
; -----------------------

ly = by
hy = ly + wy
for j = 0, cpy-1 do begin
    lx = bx
    hx = lx + wx
    for i = 0, cpx-1 do begin

;       cross correlation, inline
        ss = s(lx:hx-1,ly:hy-1)

        ; compute gradient in subfield
        k_tx = total(ss*tx)/nnx
        k_ty = total(ss*ty)/nny

        ; gradient correction added by Friedrich Woeger
        ss = (ss - (k_tx*tx + k_ty*ty))*mask
;       ss = (ss - total(ss)/nels)*mask
;       ss = (ss - total(ss)/nels)
        cc = shift(abs(fft(fft(ss,-1)*w(*,*,i,j),1)),wx/2,wy/2)


        mx = max (cc,loc)

;       simple maximum location
        ccsz = size (cc)
        xmax = loc mod ccsz(1)
        ymax = loc/ccsz(1)

;       a more complicated interpolation
;       (from Niblack, W: An Introduction to Digital Image Processing, p 139.)
        if (xmax*ymax gt 0) and (xmax lt (ccsz(1)-1)) and (ymax lt (ccsz(2)-1)) then begin


;       Sep 91 phw      try including more points in interpolations
            denom = mx*2 - cc(xmax-1,ymax) - cc(xmax+1,ymax)
            xfra = (xmax-.5) + (mx-cc(xmax-1,ymax))/denom

            denom = mx*2 - cc(xmax,ymax-1) - cc(xmax,ymax+1)
            yfra = (ymax-.5) + (mx-cc(xmax,ymax-1))/denom

            xmax=xfra
            ymax=yfra
            endif

        ans(0,i,j) = lx + xmax
        ans(1,i,j) = ly + ymax

;;lk disabled plots
;;        if ((debug and 2) ne 0) then begin
;;            plots, reform(ans(*,i,j),2,1), /dev, psym=1
;;            wait,0.     ; flushes plots
;;            endif

        lx = lx + kx
        hx = hx + kx
        endfor

    ly = ly + ky
    hy = hy + ky
    endfor

return, ans

end


;+
; check parameters are reasonable
;
; scene, ref, kernel: as defined by 'reg'
;-
pro mlso_registration_validation, scene, ref, kernel
  compile_opt strictarr
  on_error, 2

  ssz = size(scene)
  rsz = size(ref)
  ksz = size(kernel)
  errflg = 0

  if (ssz[0] ne 2) and (ssz[0] ne 3) then begin
    print, 'argument ''scene'' must be 2-D or 3-D'
    errflg += 1
  endif

  if (rsz[0] ne 2) then begin
    print, 'argument ''ref'' must be 2-D'
    errflg += 1
  endif

  if (ssz[1] ne rsz[1]) or (ssz[2] ne rsz[2]) then begin
    print, 'arguments ''scene'' & ''ref'' 1st 2 dimensions must agree'
    errflg += 1
  endif

  if (ksz[0] ne 2) then begin
    print, 'argument kernel must be 2-D'
    errflg += 1
  endif

  if (errflg gt 0) then message, 'quitting - too many errors'
end


;+
; Destretch by re-sample of scene.
;
; :Returns:
;   destretched scene, `fltarr(nx, ny)`
;
; :Params:
;   scene : in, required, type=fltarr(nx,ny)
;     image to be destretched
;   r : in, required
;     reference
;   d : in, required, type=fltarr(2, *, *)
;     actual displacements of control points
;-
function mlso_registration_doreg, scene, r, d
  compile_opt strictarr

  ; B-spline method
  xy = mlso_registration_bspline(scene, r, d)

  return, mlso_registration_bilinear(scene, xy)
end


;+
; Choose control point locations.
;
; :Params:
;   ref : in, required, type=
;     reference size
;   kernel : in, required, type=2-dimensional array
;     kernel size
;-
function mlso_registration_mkcps, ref, kernel
  compile_opt strictarr

  ; all control info is passed between support programs via common block
  common reg_com, kx, ky,         $ ; kernel x,y size (16,16)
                  wx, wy,         $ ; wander limits (32,32)
                  bx, by,         $ ; boundary x,y size (4,4)
                  cpx, cpy,       $ ; control point x,y size (7,4)
                  debug             ; = 0   silent operation
                                    ; = 1   TV_FLG
                                    ; = 2   GRD_FLG
                                    ; = 4   PRT_FLG
  debug = -1
  x = size(debug)   ; may be undefined!
  ;if (x(1) gt 0) and (x(1) lt 9) then if ((debug and 4) ne 0) then print, 'mkcps'

  ksz = size(kernel)
  kx = ksz[1]
  ky = ksz[2]

  ; 25 Sep 90:    to make like previous version, set wx = kx, wy = ky
  ; 26 Sep 90:    these worked well on a 320x236 granulation image, with
  ;               kernal of 11x11
  ;wx = kx*3
  ;wy = ky*3
  ; 26 Sep 90:    this is more general and about like above.  Comes from
  ;               a two point fit to w = a*exp(-k/b), at points
  ;               (k,w) = {(10,20), (30,10)}.
  a = 40.0 / sqrt(2.0)
  b = 20.0 / alog(2.0)
  wx = fix(a * exp(-kx / b) + kx)
  wy = fix(a * exp(-ky / b) + ky)
  if (wx mod 2 eq 1) then wx += 1
  if (wy mod 2 eq 1) then wy += 1

  rsz = size(ref)
  cpx = (rsz[1] - wx + kx) / kx
  cpy = (rsz[2] - wy + ky) / ky

  bx = ((rsz[1] - wx + kx) mod kx) / 2
  by = ((rsz[2] - wy + ky) mod ky) / 2

  rcps = fltarr(2, cpx, cpy)
  ly = by
  hy = ly + wy
  for j = 0L, cpy - 1L do begin
    lx = bx
    hx = lx + wx
    for i = 0, cpx-1 do begin
      rcps[0, i, j] = (lx + hx) / 2
      rcps[1, i, j] = (ly + hy) / 2
      lx += kx
      hx += kx
    endfor
    ly += ky
    hy += ky
  endfor

  return, rcps
end


;+
; initialize cps & reg
; scene is (nx,xy) or (nx,ny,nf)        scene(s) to be registered
; ref is (nx,ny)                        reference scene
; kernel is (kx,ky)                     conveys the size of the kernel
;                                       and is otherwise unused
;-
pro mlso_registration_setup, scene, ref, kernel
  compile_opt strictarr

  ; all control info is passed between support programs via common block
  common reg_com, kx, ky,         $ ; kernel x,y size (16,16)
                  wx, wy,         $ ; wander limits (32,32)
                  bx, by,         $ ; boundary x,y size (4,4)
                  cpx, cpy,       $ ; control point x,y size (7,4)
                  debug             ; = 0   silent operation
                                    ; = 1   TV_FLG
                                    ; = 2   GRD_FLG
                                    ; = 4   PRT_FLG

  debug = -1      ; all flags on
  ;debug = 3      ; no printing

  workstation = strpos(getenv('IDL_DEVICE'), 'SUN') + 1 $
                  or strpos(getenv('IDL_DEVICE'), 'X') + 1   ; = 1 if workstation
  debug = debug xor (not workstation and 1)

  ;if ((debug and 4) ne 0) then print, 'setup'
  mlso_registration_validation, scene, ref, kernel

  ssz = size(scene)
  if (ssz[0] eq 2) then begin
    scene = reform(scene, ssz[1], ssz[2], 1)
    ssz = size(scene)
  endif

  ;  set data scaling
  !x.style = 1
  !y.style = 1
  if (workstation) then begin
    !x.range = [0.0, 639.0]
    !y.range = [0.0, 511.0]
    !x.s = [0.0, 1.0 / 640.0]
    !y.s = [0.0, 1.0 / 512.0]
  endif else begin
    !x.range = [0.0, 1023.0]
    !y.range = [0.0, 780.0]
    ;!x.s = [0.0, 1.0 / 1024.0]
    ;!y.s = [0.0, 1.0 / 780.0]
    !x.s = [0.0, 1.0 / 512.0]
    !y.s = [0.0, 1.0 / 390.0]
  endelse
end


;+
; finds & fixs 'bad' control points
; A bad point is one TOOFAR away from reference grid.
;
;       ref(2,nx,ny)    reference coordinates
;       disp(2,nx,ny,*) displacements to be checked
;
;       17 Jan 90: phw
;-
function mlso_registration_repair, ref, disp
  compile_opt strictarr

  ; all control info is passed between support programs via common block
  common reg_com, kx, ky,         $ ; kernel x,y size (16,16)
                  wx, wy,         $ ; wander limits (32,32)
                  bx, by,         $ ; boundary x,y size (4,4)
                  cpx, cpy,       $ ; control point x,y size (7,4)
                  debug             ; = 0   silent operation
                                    ; = 1   TV_FLG
                                    ; = 2   GRD_FLG
                                    ; = 4   PRT_FLG

  ;if ((debug and 4) ne 0) then print, 'repair'

  TOOFAR = 0.12   ; user may want to change this parameter (changed june 2011, lk)
  ;TOOFAR = 0.3

  sz = size(disp)
  nx = sz[2]
  ny = sz[3]
  n_frames = sz[0] eq 4 ? sz[4] : 1
  kkx = ref[0, 1, 0] - ref[0, 0, 0]
  kky = ref[1, 0, 1] - ref[1, 0, 0]
  limit = (max([kkx, kky]) * TOOFAR)^2

  good = disp
  for f = 0L, n_frames - 1 do begin
    kps = reform(disp[*, *, *, f], 2, nx, ny)
    diff = kps - ref

    ; list of bad coordinates in this frame
    bad = where((diff[0, *, *]^2 + diff[1, *, *]^2) gt limit, count)
    for i = 0L, count - 1L do begin
      x = bad[i] mod nx
      y = bad[i] / nx

      ;;lk disabled plots
      ;if ((debug and 2) ne 0) then plots, reform (kps(*,x,y),2), /dev, psym=4

      ; Repairs good @ (x,y). There are many cases to consider: is the point
      ; needing repair at one of 4 corners, on borders, or in interior?  Also,
      ; how many other neighbors are also bad points?  Therefore, we take the
      ; easy way out an say the 'repair' is 'no warping'.
      good[*, x, y, f] = ref[*, x, y]
    endfor
  endfor

  return, good
end


function cps, scene, ref, kernel
;       cps.pro         control points for sequence destretch
;       scene is (nx,xy) or (nx,ny,nf) scene(s) for which displacements
;       are computed
;       ref is (nx,ny) and is reference scene
;       kernel is (kx,ky) and conveys the size of the control points and is
;       otherwise unused
;
;       returns displacement array: (2,cpx,cpy,nf)

;       All control info is passed between support programs via common block
common reg_com, kx, ky,         $; kernel x,y size (16,16)
                wx, wy,         $; wander limits (32,32)
                bx, by,         $; boundary x,y size (4,4)
                cpx, cpy,       $; control point x,y size (7,4)
                debug           ; = 0   silent operation
                                ; = 1   TV_FLG
                                ; = 2   GRD_FLG
                                ; = 4   PRT_FLG

; initialize package
mlso_registration_setup, scene, ref, kernel

; determine border and control point matrix size
rdisp = mlso_registration_mkcps (ref, kernel)

mm=fltarr(wx,wy)
mm(*,*)=1
 
smou=fltarr(wx,wy)
smou(*,*)=1


; condition ref
win = mlso_registration_doref (ref, mm)

ssz = size(scene)
nf = ssz(3)
ans = fltarr (2, cpx, cpy, nf,/nozero)

; compute control point locations
for frm = 0, nf-1 do begin
;    if ((debug and 4) ne 0) then print, 'frame ', frm
;; lk: no display (because of bridges)
;;    if ((debug and 1) ne 0) then tvscl,scene else if ((debug and 2) ne 0) then erase
;;    if ((debug and 2) ne 0) then begin
;;        plots, reform(rdisp,2,n_elements(rdisp)/2), /dev, psym=6
;;        wait,0.         ; enables flushing of plot!
;;        endif
    ans(*,*,*,frm) = mlso_registration_cploc (scene(*,*,frm), win, mm, smou)
    ans(*,*,*,frm) = mlso_registration_repair (rdisp, ans(*,*,*,frm)); optional repair
;    rms = sqrt(total((rdisp - ans(*,*,*,frm))^2)/n_elements(rdisp))
    endfor

undo    ; undo setup

if ssz(3) eq 1 then begin
    scene = reform (scene, ssz(1), ssz(2))
    ans = reform (ans, 2, cpx, cpy)
    endif

return, ans
end


;+
; Register scene(s) with respect to `ref`, using a given kernel size
;
; :Returns:
;   destretched scene, `fltarr(nx, ny, nf)`
;
; :Params:
;   scene : in, required, type="fltarr(nx, xy) or fltarr(nx, ny, nf)"
;     scene(s) to be registered
;   ref : in, required, type="fltarr(nx, ny)"
;     reference scene
;   kernel : in, required, type="fltarr(kx, ky)"
;     conveys the size of the kernel and is otherwise unused
;-
function mlso_registration, scene, ref, kernel, disp=disp
  compile_opt strictarr

  ; all control info is passed between support programs via common block
  common reg_com, kx, ky,         $ ; kernel x,y size (16,16)
                  wx, wy,         $ ; wander limits (32,32)
                  bx, by,         $ ; boundary x,y size (4,4)
                  cpx, cpy,       $ ; control point x,y size (7,4)
                  debug             ; = 0   silent operation
                                    ; = 1   TV_FLG
                                    ; = 2   GRD_FLG
                                    ; = 4   PRT_FLG

  ; save settings before setting up
  x_sys = !x
  y_sys = !y

  mlso_registration_setup, scene, ref, kernel

  ; determine border and control point matrix size
  rdisp = mlso_registration_mkcps(ref, kernel)
  mm    = mlso_registration_mask(wx, wy)
  smou  = mlso_registration_smouth(wx, wy)

  ; condition ref
  win = mlso_registration_doref(ref, mm)

  ssz = size(scene)
  n_frames = ssz[3]
  ans = fltarr(ssz[1], ssz[2], n_frames, /nozero)

  ; compute control point locations
  for f = 0L, n_frames - 1L do begin
    ;if ((debug and 4) ne 0) then print,'frame ', frm

    ;;lk disabled plotting:
    ;;    if ((debug and 1) ne 0) then tvscl,scene else if ((debug and 2) ne 0) then erase
    ;;    if ((debug and 2) ne 0) then begin
    ;;        plots, reform(rdisp,2,n_elements(rdisp)/2), /dev, psym=6
    ;;        wait,0.         ; enables flushing of plot!
    ;;   endif
    disp = mlso_registration_cploc(scene[*, *, f], win, mm, smou)
    disp = mlso_registration_repair(rdisp, disp) ; optional repair
    ;rms = sqrt(total((rdisp - disp)^2)/n_elements(rdisp))
    ;print, 'rms =', rms
    x = mlso_registration_doreg(scene[*, *, f], rdisp, disp)
    ans[*, *, f] = x
    ;win = mlso_registraton_doref(x, mm)   ; optional update of window
  endfor

  ; restore settings
  !x = x_sys
  !y = y_sys

  if (ssz[3] eq 1) then begin
    scene = reform(scene, ssz[1], ssz[2])
    ans = reform(ans, ssz[1], ssz[2])
  endif

  return, ans
end


; main-level example program

date = '20200224'
config_filename = filepath('kcor.reprocess.cfg', $
                           subdir=['..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_file=config_filename)
filenames = file_search(filepath('*_kcor_l2.fts.gz', $
                                 subdir=[date, 'level2'], $
                                 root=run->config('processing/raw_basedir')), $
                        count=n_files)

nx = 1024
ny = 1024
n_images = 100
scene = fltarr(nx, ny, n_images)

print, 'Loading images...'
for f = 0, n_images - 1L do begin
  scene[*, *, f] = readfits(filenames[f], /silent)
endfor

ref = reform(scene[*, *, 0])
kernel = bytarr(15, 15)

print, 'Performing registration...'
destretched = mlso_registration(scene, ref, kernel)

obj_destroy, run

end
