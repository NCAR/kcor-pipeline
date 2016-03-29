;+
;  Name: kcor_radial_der
; 
;  Description:
;    procedure to interpolate radial scans in an image, take the derivative, and fit the maximum
;    with a parabola to find the location of a discontinuity. This routine is used to find the
;    location of the solar limb. The variable nscan below determined the number of radial scans.
;    This routine differentiates between positive and negative discontinuities, depending on the
;    input keyword neg_pol. Positive polarity is the default.
;    Modified from the function comp_radial_dr.pro

;  Input Paramaters:
;    data - the data image to analyze
;    xcen, ycen, radius  in pixel - these are the initial guesses  guesses 
;    dr - the region +/- around radius to make the scan (pixels)
;    
;  Keywords:
;    neg_pol - this determines the polarity of the discontinuity, neg_pol=1 for negative polarity
;    nscan - number of radial scans, default = 360
;
;  Output:
;    the the array of radial positions is returned (pixels)
;    theta - the of array of angles used (radians)
;    cent - the of array of inflection points marking the limb
;    debug
;
;  Author: Tomczyk 
;  Modifier: de Toma 
;
;  Example:
;    
;
;  Modification History:
;    added comments, 10/24/14 ST
;    changed from function to procedure and to return full arrays  11/12/2014  GdT
;    changed nscan to keyword  11/12/2014  GdT
;    now requires initial guess  for xcen, ycen and radius   11/12/2014  GdT
;
;- 
pro kcor_radial_der, data, xcen, ycen, radius, dr, theta, cent, nscan=nscan, neg_pol=neg_pol, debug=debug


default, nscan, 180
default, neg_pol, 0 
default, debug, 0 

  theta=dblarr(nscan)
  cent =dblarr(nscan)
  
  data=double(data)

  x0=double(xcen)     ;make initial guess of x and y positions the center of the array
  y0=double(ycen)
  
  nvals=dr*2   ;number of points in interpolated radial scan
  
; if debug eq 1 then tvwin,data
  
  ;  make radial scans
  
  for i=0,nscan-1 do begin
    theta[i]=double(i)*2.d0*!dpi/double(nscan)     ;angle for radial scan
    
    x1=x0+(radius-dr)*cos(theta[i])      ;x1 and y1 are start x and y coords; x2 and y2 are end coords
    y1=y0+(radius-dr)*sin(theta[i])
    x2=x0+(radius+dr)*cos(theta[i])
    y2=y0+(radius+dr)*sin(theta[i])
    
    dx=(x2-x1)/double(nvals-1)          ;dx and dy are spacing in x and y
    dy=(y2-y1)/double(nvals-1)
    
    xx=dindgen(nvals)*dx +x1       ;xx and yy are x and y coords to interpolate onto for radial scan
    yy=dindgen(nvals)*dy +y1
    
;    if debug eq 1 then plots, xx, yy, color=200, /device
    
    rad=interpolate(data,xx,yy,cubic=-0.5,missing=0.0)       ;compute radial intensity scan
    
    rad=deriv(rad)    ;take derivative of radial intensity scan
    if keyword_set(neg_pol) then rad=-1.*rad   ;change sign if negative polarity
    
    mx=max(rad,imax)   ;find position of maximum derivative, imax
    if imax gt nvals-3 then imax=nvals-3
    if imax lt 2 then imax=2
    
    cent[i]=radius-dr+ $
      parabola([double(imax-1.),double(imax),double(imax+1.)],[rad(imax-1),rad(imax),rad(imax+1)])
      
    
endfor

end
