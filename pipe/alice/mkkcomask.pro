
filenm = 'kcomask.bin'

pixx = 1024
pixy = 1024
mask = 0
mask = fltarr(pixx,pixy)


mask(*,*) = 1.
pts = 10060
acirc = !PI*2. 
dp  = findgen(pts) * acirc / float(pts)
dpx = intarr(pts)
dpy = intarr(pts)
rndr   = 0.505
xcen = ( float(pixx) * 0.5 ) - 0.5
ycen = ( float(pixy) * 0.5 ) - 0.5
for radius = 1,170 do begin ;{
    dpx = fix ( cos(dp) * radius + xcen + rndr )
    dpy = fix ( sin(dp) * radius + ycen + rndr )
    mask(dpx,dpy) = 0.
endfor ;}

for radius = 171,500 do begin ;{
    dpx = fix ( cos(dp) * radius + xcen + rndr )
    dpy = fix ( sin(dp) * radius + ycen + rndr )
    dpx[where(dpx lt 0)] = 0
    dpy[where(dpy lt 0)] = 0
    dpx[where(dpx gt (pixx-1))] = pixx-1
    dpy[where(dpy gt (pixy-1))] = pixy-1
    mask(dpx,dpy) =  1.3*float(radius)/171.
endfor ;}

for radius = 500,800 do begin ;{
    dpx = fix ( cos(dp) * radius + xcen + rndr )
    dpy = fix ( sin(dp) * radius + ycen + rndr )
    dpx[where(dpx lt 0)] = 0
    dpy[where(dpy lt 0)] = 0
    dpx[where(dpx gt (pixx-1))] = pixx-1
    dpy[where(dpy gt (pixy-1))] = pixy-1
    mask(dpx,dpy) = 0.
endfor ;}

openw,1,filenm & writeu,1,mask & close,1

end
