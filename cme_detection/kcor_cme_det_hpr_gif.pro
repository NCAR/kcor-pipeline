; docformat = 'rst'

;+
; Produce an annotated GIF of the difference map.
;
; :Params:
;   output_filename : in, required, type=string
;     filename to write GIF to
;   mdiff : in, required, type="dblarr(120, 310)"
;     difference map
;-
pro kcor_cme_det_hpr_gif, output_filename, mdiff
  compile_opt strictarr

  n_dims = size(mdiff, /n_dimensions)
  if (n_dims ne 2) then return

  dims = size(mdiff, /dimensions)
  resized_dims = [4 * dims[0], 2 * dims[1]]
  resized_image = rebin(mdiff, resized_dims)

  r = bindgen(256)
  g = r
  b = r

  scaled_image = bytscl(resized_image, min=-5.0e-10, max=3.0e-9)

  ; setup graphics
  original_device = !d.name
  set_plot, 'Z'
  device, get_decomposed=original_decomposed
  tvlct, original_rgb, /get
  device, set_resolution=resized_dims, $
          decomposed=0, $
          set_colors=256, $
          z_buffering=0
  loadct, 0, /silent

  ; reverse color table to get a blue-green-yellow color table
  ; loadct, 64, /silent
  ; tvlct, rgb, /get
  ; rgb = reverse(rgb, 1)
  ; tvlct, rgb

  xgap = 10
  ygap = 5
  line_height = 12
  charsize = 1.1

  tv, scaled_image
  xyouts, xgap, $
          resized_dims[1] - line_height - ygap, $
          /device, $
          file_basename(output_filename), $
          color=255, charsize=charsize

  label_height = 0.92 * resized_dims[1]
  labels = [{label:'N', angle: 0.0}, $
            {label:'W', angle: 90.0}, $
            {label:'S', angle: 180.0}, $
            {label:'E', angle: 270.0}, $
            {label:'N', angle: 360.0}]
  for i = 0L, n_elements(labels) - 1L do begin
    xyouts, labels[i].angle / 360.0 * resized_dims[0], $
            label_height, $
            /device, $
            labels[i].label, $
            alignment=i eq 0 ? 0.0 : (i eq n_elements(labels) - 1 ? 1.0 : 0.5), $
            color=255, $
            charsize=charsize
  endfor
  write_gif, output_filename, tvrd(), r, g, b

  ; restore graphics
  done:
  device, decomposed=original_decomposed
  tvlct, original_rgb
  set_plot, original_device
end


; main-level example program

;f = '20210829_205704_kcor_l2_hpr_rd.fts'
f = '20210507_192030_kcor_l2_hpr_rd.fts'
mdiff = readfits(f, header)
gif_filename = file_basename(f, '.fts') + '.gif'
kcor_cme_det_rdiff_gif, gif_filename, mdiff

end
