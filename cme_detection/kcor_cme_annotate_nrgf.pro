; docformat = 'rst'

pro kcor_cme_annotate_nrgf, nrgf_filename, $
                            annotated_filename=annotated_filename, $
                            height=height, position_angle=position_angle, r_photo=r_photo, $
                            run=run
  compile_opt strictarr

  ; read original NRGF filename
  read_gif, nrgf_filename, nrgf_image, r, g, b

  ; put annular box around CME
  original_device = !d.name
  set_plot, 'Z'
  device, get_decomposed=original_decomposed
  device, set_resolution=[1024, 1024], $
          decomposed=0, $
          set_colors=256, $
          set_pixel_depth=8, $
          z_buffering=0
  tvlct, original_rgb, /get

  n_colors = 256
  tvlct, r, g, b
  annotation_color = n_colors - 1

  tv, nrgf_image

  angle_change = 30.0
  height_margins = [0.05, 0.25]  ; Rsun
  theta = !dtor * (position_angle + angle_change * (findgen(10) / 9.0 - 0.5) + 90.0)
  lower_cme_x = 511.5 + (1.0 + height_margins[0]) * r_photo * cos(theta)
  lower_cme_y = 511.5 + (1.0 + height_margins[0]) * r_photo * sin(theta)
  upper_cme_x = 511.5 + (height + height_margins[1]) * r_photo * cos(theta)
  upper_cme_y = 511.5 + (height + height_margins[1]) * r_photo * sin(theta)
  plots, [lower_cme_x, reverse(upper_cme_x), lower_cme_x[0]], $
         [lower_cme_y, reverse(upper_cme_y), lower_cme_y[0]], $
         /device, $
         psym=0, symsize=4.0, thick=2.0, color=annotation_color

  annotated_nrgf_image = tvrd()

  ; write in cme/image_dir
  image_dir = filepath('', $
                       subdir=kcor_decompose_date(run.date), $
                       root=run->config('cme/image_dir'))
  if (~file_test(image_dir, /directory)) then file_mkdir, image_dir

  annotated_basename = file_basename(nrgf_filename)
  annotated_filename = filepath(annotated_basename, root=image_dir)

  write_gif, annotated_filename, annotated_nrgf_image, r, g, b

  done:
  tvlct, original_rgb
  device, decomposed=original_decomposed
  set_plot, original_device
end


; main-level example program

config_basename = 'kcor.cme-test.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', 'kcor-config'], $
                           root=mg_src_root())

date = '20260401'
run = kcor_run(date, config_filename=config_filename)

root_dir = run->config('processing/raw_basedir')

nrgf_basename = '20260401_183602_kcor_l2_nrgf.gif'
subdir = [date, 'level2']
nrgf_filename = filepath(nrgf_basename, subdir=subdir, root=root_dir)

kcor_cme_annotate_nrgf, $
  nrgf_filename, $
  annotated_filename=annotated_filename, $
  height=1.39, position_angle=259.5, rsun=169.987, $
  run=run
print, annotated_filename

obj_destroy, run

end
