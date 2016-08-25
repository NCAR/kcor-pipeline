pro kcor_reduce_calibration_setup_lm, data, metadata, pixel, beam, parinfo, functargs
	common kcor_random, seed

	; this procedure creates the parinfo and functargs structs for mpfit

	; 18 parameters go into the model, but 7 are fixed, so there are 11 free parameters
	parinfo = replicate({value:0d, fixed:0, limited:[0,0], limits:[0D,0]}, 18)

	parinfo[0].value = metadata.idiff ; I is normalized to metadata.idiff
	parinfo[1:4].value = [1,1,1,1] ; initial guess for I modulation
	parinfo[5:8].value = [1,1,1,1]*0.95 ; initial guess for Q&U modulation amplitude
	parinfo[9:12].value = randomu(seed,4)*2*!dpi ; random Q&U phase
	parinfo[13].value = data.dark[pixel.x,pixel.y,beam] ; initial guess for dark current
	parinfo[14].value = data.gain[pixel.x,pixel.y,beam] ; initial guess for gain
	parinfo[15].value = [0.9] ; initial guess for cal pol transmission

	parinfo[0].fixed = 1 ; I is fixed at the known diffuser intensity
	parinfo[1:4].fixed = 1 ; fix the (0,*) elements
	parinfo[5:8].limited = [1,1] ; modulation matrix amplitude for Q&U is limited
	parinfo[5:8].limits = [0.5,1.] ; between 0.5 and 1
	parinfo[9:12].limited = [1,1] ; modulation matrix angle for Q&U is limited
	parinfo[9:12].limits = [-1,3]*!dpi ; angle
	parinfo[13].fixed = 1 ; dark current is deterministic
	parinfo[14].fixed = 1 ; gain current is deterministic
	parinfo[15].limited = [1,1] ; polarizer transmission is between 0 and 1
	parinfo[15].limits = [0,1.]

	parinfo[16].value = 1. ; angle fudge factor
	parinfo[16].limited = [1,1]
	parinfo[16].limits = [0.9,1.1]
	parinfo[17].value = 0. ; angle offset
	parinfo[17].limited = [1,1]
	parinfo[17].limits = [-1,1]

	cal = reform(data.calibration[pixel.x,pixel.y,*,beam,*])

	functargs = { data:cal, angles:metadata.angles, pixel:pixel, beam:beam }
end
