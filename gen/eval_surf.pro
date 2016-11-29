function eval_surf,coef,coord_x,coord_y

;  function to use coefficients from surf_fit and create polynomial surface

;          initialize

fit=coord_x
fit[*]=0.

s=size(coef)
degree=s[1]-1     ;determine degree of fit

;          compute fit surface from coefficients

fit = fit + coef[0,0]   ;constant term.
FOR ix = 1,degree DO fit = fit + coef [ix,0]*coord_x^ix
FOR iy = 1,degree DO fit = fit + coef [0,iy]*coord_y^iy
; changed index order (GdT)
FOR iy = 1,degree DO $
   FOR ix = 1,degree DO $
     fit = fit + coef [ix,iy]*coord_x^ix*coord_y^iy

;          return fit surface

RETURN, fit
END
