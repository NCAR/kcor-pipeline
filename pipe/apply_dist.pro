pro apply_dist,dat1,dat2,dx1_c,dy1_c,dx2_c,dy2_c

;  procedure to apply distortion correction to the sub-images
;  dat1 and dat2 given the distortion coefficients.

s=size(dat1)
nx=s(1)

x=rebin(findgen(nx),nx,nx)
y=transpose(x)

dat1=interpolate(dat1,x+eval_surf(dx1_c,x,y),y+eval_surf(dy1_c,x,y), $
 cubic=-0.5,missing=0.)
dat2=interpolate(dat2,x+eval_surf(dx2_c,x,y),y+eval_surf(dy2_c,x,y), $
 cubic=-0.5,missing=0.)

end