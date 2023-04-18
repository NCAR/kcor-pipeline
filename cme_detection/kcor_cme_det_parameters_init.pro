; docformat = 'rst'

function kcor_cme_det_parameters_init
  compile_opt strictarr

  result = {kcor_cme_det_parameters}

  result.tai = !values.f_nan
  result.angle_range = fltarr(2) + !values.f_nan
  result.detected = 0B
  result.leading_edge = !values.f_nan
  result.n_used = 0L
  result.n_thresh = 0L
  result.speed = !values.f_nan
  result.max_time_interval = !values.f_nan
  result.time_range = !values.f_nan
  result.stddev = !values.f_nan
  result.cme_occurring = 0B

  return, result
end
