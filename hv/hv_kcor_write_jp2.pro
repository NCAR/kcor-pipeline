; docformat = 'rst'

;+
; Writes out K-Cor JPEG2000 image files.
;
; The procedure constructs the filename and subdirectory name following
; Helioviewer conventions.  The subdirectory is made on the filesystem if it
; does not already exist.
;
; :Author:
;   Jack Ireland [JI]
;
; :History
;   18 Jun 2018 initial file that sets up the information for the write.
;
; :Params:
;   image : in, required, type="bytarr(nx, ny)"
;     2 dimensional byte-scaled image of a KCor FITS file. The image should be
;     scaled in the same way as the corresponding GIF image.
;   header : in, required, type=strarr
;     the FITS file header corresponding to the image data
;   root_directory : in, required, type=string
;     the root directory where the JPEG2000 files are stored
;-
pro hv_kcor_write_jp2, image, header, root_directory, log_name=log_name
  compile_opt strictarr

  ; details file
  details = hvs_kcor()

  ; define the measurement name as used in Helioviewer; only one measurement
  ; type from KCor
  measurement = 'white-light-pB'

  ; nice way to get the times out of the date
  ext = anytim2utc(sxpar(header, 'DATE-OBS'), /ext)

  ; construct the JPEG2000 filename
  jp2_filename = string(ext.year, ext.month, ext.day, $
                        ext.hour, ext.minute, ext.second, $
                        details.observatory, details.instrument, details.detector, $
                        measurement, $
                        format='(%"%04d_%02d_%02d__%02d_%02d_%02d__%s_%s_%s_%s.jp2")')

  ; construct the Helioviewer directory name and create the directory on the
  ; filesystem if required
  subdirs = ['jp2', details.nickname, $
             string(ext.year, format='(%"%04d")'), $
             string(ext.month, format='(%"%02d")'), $
             string(ext.day, format='(%"%02d")'), $
             measurement]
  jp2_dir = filepath('', subdir=subdirs, root=root_directory)
  file_mkdir, jp2_dir

  ; write the JPEG2000 file
  hv_write_jp2_lwg, filepath(jp2_filename, root=jp2_dir), image, $
                    fitsheader=header, details=details, measurement=measurement, $
                    log_name=log_name
end


; main-level example program

date = '20181124'

config_basename = 'kcor.mgalloy.mlsodata.production.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', 'config'], $
                           root=mg_src_root())
run = kcor_run(date, config_filename=config_filename)

basename = '20181124_212325_kcor_l1.5.fts.gz'
filename = filepath(basename, $
                    subdir=[date, 'level1'], $
                    root=run.raw_basedir)

corona = readfits(filename, header)

display_factor = 1.0e6
scaled_image = bytscl((display_factor * corona) ^ run->epoch('display_exp'), $
                      min=display_factor * run->epoch('display_min'), $
                      max=display_factor * run->epoch('display_max'))

hv_kcor_write_jp2, scaled_image, header, '.', log_name='kcor/rt'

obj_destroy, run

end

