;	(26-feb-92)
pro draw_circle,x0,y0,radius,npts=npts,device=device,data=data,psym=psym,  $
			linestyle=linestyle,color=color,thick=thick,       $
			fill=fill,noclip=noclip
;+
;  Name:
;    draw_circle
;  Purpose:
;    Draw a circle.
;  Calling Sequence:
;    draw_circle, x0, y0, radius [, npts=npts]
;  Input Parameters:
;    x0 =  Central x coordinate
;    y0 =  Central y coordinate
;    radius = Radius
;
;  Optional input keywords:
;    Npts   = Number of points (default = 10000)
;    device = If set, plots will assume device coordinates
;    data   = If set, plots will assume data   coordinates
;    psym   = Plot symbol
;    color  = Color
;    linestyle = Line style
;    fill   = If set, call poly_fill
;    noclip = If noclip=0, circles will be clipped (read the IDL
;		manual on plots to find out why its this way).
;
;  Modification History:
;    Written, 26-feb-92, J. R. Lemen
;    2-feb-95, JRL, Added thick keyword
;   11-apr-96, S.L.Freeland, Add FILL keyword and function
;   25-apr-96, JRL, Added the NOCLIP keyword
;   22-Apr-2001, Kim Tolbert.  In theta calculation, divide by npts-1 so 
;      circle is closed.
;-

if n_elements(psym)      eq 0 then ppsym = 0      else ppsym = psym
if n_elements(color)     eq 0 then ccolor = 255   else ccolor = color
if n_elements(thick)     eq 0 then tthick = 1     else tthick = thick
if n_elements(linestyle) eq 0 then llinestyle = 0 else llinestyle = linestyle
if n_elements(data)      eq 0 then ddata=0        else ddata = data
if n_elements(device)    eq 0 then ddevice=0      else ddevice = device
if n_elements(noclip)    eq 0 then nnoclip=1	  else nnoclip=noclip

if n_elements(npts) eq 0 then npts = 10000L
theta = indgen(npts)*2*!pi / (npts-1)

xx = radius * sin(theta) + x0
yy = radius * cos(theta) + y0

case 1 of
   keyword_set(fill): polyfill,xx,yy, device=ddevice,data=ddata, $
                      color=ccolor,thick=tthick
   else: plots,xx,yy,device=ddevice,data=ddata,psym=ppsym,   $
            linestyle=llinestyle, color=ccolor,thick=tthick,noclip=nnoclip

endcase

return
end
