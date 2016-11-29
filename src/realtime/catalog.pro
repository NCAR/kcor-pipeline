;+
; :Description:
;  procedure to identify type of given KCor data file.
;
; :Params:
;   filename        Input KCor level 0 file
;
; :Author: Sitongia
;-
pro catalog, filename

  common kcor_paths, bias_dir, flat_dir, mask_dir, binary_dir, $
    raw_basedir, process_basedir, hpss_gateway, $
    archive_dir, movie_dir, fullres_dir, log_dir
    
  COMPILE_OPT IDL2
  
  date_dir = get_date_dir(filename)
  process_dir = process_basedir + date_dir

  header = headfits(filename)
 
  datatype = sxpar(header, "DATATYPE")
  diffuser = sxpar(header, "DIFFUSER")
  calpol =   sxpar(header, "CALPOL")
  calpang =  sxpar(header, "CALPANG")
  darkshut = sxpar(header, "DARKSHUT")
 
  exposure=sxpar(header,'EXPTIME', count=nrecords)
  if nrecords eq 0 then exposure=sxpar(header,'EXPOSURE')
 
  if (datatype eq "science") then begin
    openw,1, process_dir+'/science_files.txt', /APPEND
    printf, 1, $
      format='(a, 3x, f10.4, 2x, "ms", 2x, "Data: ", a, 3x, "Dark: ", a, 3x, "Diff: ", a, 3x, "Cal: ", a, 3x, "Ang: ", f6.1)',$
      filename, exposure, datatype, darkshut, diffuser, calpol, calpang
 
    ; Print a measure of every image in the cube
    image = readfits(filename)
    for camera = 0,1 do begin
      for sequence = 0,3 do begin
        printf, 1, format='(e12.5, "   ", $)', mean(image[*,*,sequence,camera])
      endfor
    endfor
    printf, 1
    close,1
  endif
 
  if (datatype eq "calibration") then begin
    openw,1, process_dir+'/calibration_files.txt', /APPEND
    printf, 1, $
      format='(a, 3x, f10.4, 2x, "ms", 2x, "Data: ", a, 3x, "Dark: ", a, 3x, "Diff: ", a, 3x, "Cal: ", a, 3x, "Ang: ", f6.1, "  means: ", $)',$
      filename, exposure, datatype, darkshut, diffuser, calpol, calpang
 
    ; Print a measure of every image in the cube
    image = readfits(filename)
    for camera = 0,1 do begin
      for sequence = 0,3 do begin
        printf, 1, format='(e12.5, "   ", $)', mean(image[*,*,sequence,camera])
      endfor
    endfor
    printf, 1
    close,1
  endif
 
  if (datatype eq "engineering") then begin
    openw,1, process_dir+'/engineering_files.txt', /APPEND
    printf, 1, $
      format='(a, 3x, f10.4, 2x, "ms", 2x, "Data: ", a, 3x, "Dark: ", a, 3x, "Diff: ", a, 3x, "Cal: ", a, 3x, "Ang: ", f6.1)',$
      filename, exposure, datatype, darkshut, diffuser, calpol, calpang
    close,1
  endif
 
  if ((datatype ne "science") && (datatype ne "calibration") && (datatype ne "engineering")) then begin
    openw,1, process_dir+'/misc_files.txt', /APPEND
    printf, 1, $
      format='(a, 3x, f10.4, 2x, "ms", 2x, "Data: ", a, 3x, "Dark: ", a, 3x, "Diff: ", a, 3x, "Cal: ", a, 3x, "Ang: ", f6.1)',$
      filename, exposure, datatype, darkshut, diffuser, calpol, calpang
    close,1
  endif

end
