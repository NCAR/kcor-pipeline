; docformat: 'rst'

pro kcor_cme_det_parameters__define
  compile_opt strictarr

  !null = {kcor_cme_det_parameters, $
           tai: 0.0D, $
           time: '', $
           angle_range: fltarr(2), $
           detected: 0B, $
           leading_edge: 0.0, $
           n_used: 0L, $
           n_thresh: 0L, $
           speed: 0.0, $
           max_time_interval: 0.0, $
           time_range: 0.0, $
           stddev: 0.0, $
           cme_occurring: 0B}
end

