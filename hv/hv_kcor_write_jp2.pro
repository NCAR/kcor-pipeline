;
;+
; :Description: writes out K-Cor JPEG2000 image files.
;
; :Author:
;   Jack Ireland [JI]
;
; :History
;   18 Jun 2018 initial file that sets up the information for the write.
;
; :Input
; image - 2 dimensional byte-scaled image of a KCor FITS file. The
;         image should be scaled in the same way as the corresponding
;         GIF image.
;
; header - The FITS file header corresponding to the image data.
;
; root_directory - the root directory where the JPEG2000 files are
;                  stored. 
;
; :Notes
; The procedure constructs the filename and subdirectory name
; following Helioviewer conventions.  The subdirectory is made on the
; filesystem if it does not already exist.
;
;-
pro hv_kcor_write_jp2, image, header, root_directory

  ; details file
  details = hvs_kcor()

  ; Define the measurement name as used in Helioviewer. Only one
  ; measurement type from KCor
  measurement = 'white-light'

  ; Nice way to get the times out of the date
  ext = anytim2utc(header.date_obs, /ext)

  ; HV information structure
  hvsi = {dir: '', $
          fitsname: ident_name, $
          header: header, $
          comment: '', $
          yy: string(ext.year, format='(I4.4)'), $
          mm: string(ext.month, format='(I2.2)'), $
          dd: string(ext.day, format='(I2.2)'), $
          hh: string(ext.hour, format='(I2.2)'), $
          mmm: string(ext.minute, format='(I2.2)'), $
          ss: string(ext.second, format='(I2.2)'), $
          milli: string(ext.millisecond, format='(I3.3)')}

  ; Construct the JPEG2000 filename
  jp2_filename_date = hvsi.yy + '_' + hvsi.mm + '_' +  hvsi.dd
  jp2_filename_time = hvsi.hh + '_' + hvsi.mmm + '_' +  hvsi.ss
  jp2_filename_obs = details.observatory + '_' + details.instrument + '_' + details.detector + '_' + measurement
  jp2_filename = jp2_filename_date + '__' + jp2_filename_time + '__' + jp2_filename_obs + '.jp2'

  ; Construct the Helioviewer sub-directory name
  ; and create the subdirectory on the filesystem if required
  subdirectory = root_directory
  subdirectory_ordering = ['jp2', details.nickname, hvsi.yy, hvsi.mm, hvsi.dd, measurement]
  foreach element, subdirectory_ordering do begin
     subdirectory = subdirectory + '/' + element
     if (~file_test(subdirectory, /directory)) then file_mkdir, subdirectory
  endforeach

  ; Construct the full file path
  filepath = subdirectory + '/' + jp2_filename

  ; Write the JPEG2000 file.
  hv_write_jp2_lwg, filepath, image, fitsheader=header, details=details, measurement=measurement

  return
end
