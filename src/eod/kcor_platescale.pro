; docformat = 'rst'

function kcor_platescale, run=run, scale_factor=scale_factor
  compile_opt strictarr

  plate_scale = run->epoch('plate_scale')
  plate_scale_stddev = run->epoch('plate_scale_stddev')

  preferred_plate_scale = run->epoch('preferred_plate_scale')
  preferred_plate_scale_stddev = run->epoch('preferred_plate_scale_stddev')

  scale_to_preferred_plate_scale = run->config('realtime/scale_to_preferred_platescale')
  if (scale_to_preferred_plate_scale && abs(plate_scale - preferred_plate_scale) gt (plate_scale_stddev + preferred_plate_scale_stddev)) then begin
    scale_factor = plate_scale / preferred_plate_scale
  endif else begin
    scale_factor = 1.0
    preferred_plate_scale = plate_scale
  endelse

  return, preferred_plate_scale
end
