function clock_angle_remove, infile, verbose = verbose

; IDL 8.6.0 (darwin x86_64 m64)
; Journal File for mscott@harvey.hao.ucar.edu
; Working directory: /Users/mscott/Desktop
; Date: Wed Nov  1 08:48:26 2017
 
;kcor = '/Users/mscott/Desktop/20171029_172616_kcor_l1.fts'
;kcor = '/Users/mscott/Desktop/20171101_205404_kcor_l1.fts'

fits2map, infile, map

if keyword_set(verbose) then begin
  loadct, 0, /silent
  window, 0, xs = 512, ys = 512, retain = 2
  plot_map, map, /log, grid = 25, /limb, dmin = 0, dmax = 2
  help, map, /str
endif

aa = size(map.data)
nx = aa[1]
ny = aa[2]

mapang = fltarr(nx, ny)
x_coord = mapang
y_coord = mapang

r0 = 190. ; edge of the unocculted FOV
rdx = map.dx * 0.725 ; Mm/pix
x_ccd = nx/2.
y_ccd = ny/2.
for ii=0,nx-1 do begin
    for jj=0,ny-1 do begin
        mapang(ii,jj) = atan(ii-x_ccd, jj-y_ccd)/!dtor
        x_coord(ii,jj) = sqrt((ii-x_ccd)^2 + (jj-y_ccd)^2) * cos(mapang(ii,jj)*!dtor)
        y_coord(ii,jj) = sqrt((ii-x_ccd)^2 + (jj-y_ccd)^2) * sin(mapang(ii,jj)*!dtor)
    endfor
endfor
rrr = sqrt(x_coord^2 + y_coord^2)
rrs = rrr / r0 ; divide by the limb pixelmapang = mapang + 180.
radiusmap = map
radiusmap.data = rrs
anglemap = map
anglemap.data = mapang

img_map = map
img_map.data = img_map.data * 0.

inner = 1.005
outer = 2.65

if keyword_set(verbose) then begin
  window, 1, xs = 512, ys = 512, retain = 2
  plot_map, radiusmap, grid = 25, /limb
  plot_map, radiusmap, /over, lev = inner
  plot_map, radiusmap, /over, lev = outer

  window, 2, xs = 512, ys = 512, retain = 2
  window, 3, xs = 512*2, ys = 512, retain = 2
  window, 4, xs = 512, ys = 512, retain = 2
endif

nsteps = 100
angles = findgen(nsteps)*(360./nsteps)
na = n_elements(angles)
dd = 30.

for ii=0, na-2 do begin
    flag = 0

    center_angle = angles[ii]

    bottom = center_angle - dd/2.
    top = center_angle + dd/2.
 
;    help, bottom, top

    if (bottom lt 0.) or (top ge 360.) then begin
       if bottom lt 0 then bottom = (360. + bottom)
       if top gt 360 then top = (top - 360.)
       best = where((mapang ge bottom) or (mapang le top), bcnt, comp = worst)
    endif else begin 
       best = where((mapang ge bottom) and (mapang le top), bcnt)
    endelse

    wheretomulti, mapang, best, xx, yy
    mask = mapang * 0.
    mask[xx,yy] = 1
    better = where(rrs le inner or rrs ge outer)
    wheretomulti, rrs, better, xx, yy
    mask[xx,yy] = 0.
 
    extract = where(mask eq 1)
    wheretomulti, mask, extract, final_xx, final_yy

    final = map
    final.data = final.data * mask

    if keyword_set(verbose) then begin
      wset, 2
      loadct, 0, /silent
      plot_map, final, /log, grid = 25, /limb, dmin = 0, dmax = 2
    endif

    xx = reform(rrs[final_xx, final_yy])
    yy = reform(map.data[final_xx, final_yy])

    if keyword_set(verbose) then begin
      wset, 3
      loadct, 39, /silent
      plot, xx, yy, psym = 3, ytit = 'Natural Log of KCor Data', xtit = 'Radial Distance',$
	chars =1.25
    endif

    fitted = where(xx ge 2.25)

    res = exponential_fit(xx[fitted],yy[fitted])
    rad = 1. + 2.*findgen(100)/99.
    ;y=a*exp(b*x)
    fit = res[0] * exp(res[1]*rad)
    if keyword_set(verbose) then oplot, rad, fit, color = 250, thick = 3    
    ;print, res
    
    img_map.data[final_xx, final_yy] = res[0] * exp(res[1]*rrs[final_xx, final_yy])

    if keyword_set(verbose) then begin
      wset, 4
      loadct, 0, /silent
      plot_map, img_map, /log, grid = 25, /limb, dmin = 0, dmax = 2
      plot_map, radiusmap, /over, lev = inner
      plot_map, radiusmap, /over, lev = outer
    endif

endfor

final = map
final.data = map.data - smooth(img_map.data,10)

if keyword_set(verbose) then begin
  wset,1
  plot_map, final, /log, grid = 25, /limb, dmin =0.002, dmax = 0.5
endif

output = map
output = merge_struct(output, img_map)
output = merge_struct(output, final)

return, output 

end
