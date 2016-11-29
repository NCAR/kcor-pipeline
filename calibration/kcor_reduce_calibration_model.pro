function kcor_reduce_calibration_model, p, data=data, angles=angles, synth=synth
	if not keyword_set(data) then data = 1.
	if not keyword_set(angles) then angles = findgen(4)*45

	; p[1-12]: modulation matrix
	mmat = dblarr(4,4)
	mmat[0,*] = p[1:4]
	mmat[1,*] = p[1:4]*p[5:8]*cos(p[9:12])
	mmat[2,*] = p[1:4]*p[5:8]*sin(p[9:12])

	; set up some storage
	nangles = n_elements(angles)
	synth = fltarr(4,nangles)
	rmat = identity(4) ; rotation matrix

	; We're going to combine a bunch of stuff here. In principe, we should
	; calculate:
	;   mmat##rmat(-1*angles[i])##pmat##rmat(angles[i])##ss
	; where rmat(x) is the rotation matrix over x, pmat is the mueller matrix
	; of the polarizer, and ss is the input Stokes vector.
	; Because we assume that ss is unpolarized, we don't need the right
	; rotation matrix. Then we have: 
	;   mmat##rmat(-1*angles[i])##pmat##ss
	; We can simplify further:
	;   pmat##ss = 0.5*p[15]*[a,b,0,0]^T*p[0]
	; where p[0] is the intensity component of the Stokes vector, p[15] is the
	; polarizer transmission, and a and b are given by:
	; pr = (1.-pol)/(1.+pol)
	; b = 1-pr
	; a = 1+pr
	; where pol is the fractional polarization of the polarizer. We assume
	; pol = 1 so pr = 0 and a = b = 1.
	pmatss = 0.5*p[15]*transpose([1,1,0,0])*p[0]

	; loop over all angles
	for i=0, nangles-1 do begin
		; calculate the inverse rotation matrix
		sa = sin(2d*!dtor*angles[i]*p[16])
		ca = cos(2d*!dtor*angles[i]*p[16])
		rmat[1:2,1:2] = [[ca,sa],[-1*sa,ca]]
		; calculate the intensity
		synth[*,i] = p[14]*(mmat##rmat##pmatss) + p[13]
	endfor

	diff = data - synth

	; data > 1 to avoid blow-up when data = 0
	return, reform(diff/sqrt(data > 1), n_elements(diff))
end
