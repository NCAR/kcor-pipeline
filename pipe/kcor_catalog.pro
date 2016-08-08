;+
; :Description:
;  procedure to identify type of given KCor data file.
;
; :Params:
; filename        Input KCor level 0 file
;
; :Author: Sitongia
;-

PRO kcor_catalog, filename

common kcor_paths, bias_dir, flat_dir, mask_dir, binary_dir, $
                   raw_basedir, process_basedir, hpss_gateway, $
                   archive_dir, movie_dir, fullres_dir, log_dir
    
COMPILE_OPT IDL2
  
date_dir    = get_date_dir (filename)
process_dir = process_basedir + date_dir

;--- Read FITS header & read selected keyword parameters.

header = headfits (filename)
 
datatype = sxpar (header, "DATATYPE")
diffuser = sxpar (header, "DIFFUSER")
calpol   = sxpar (header, "CALPOL")
calpang  = sxpar (header, "CALPANG")
darkshut = sxpar (header, "DARKSHUT")
 
exposure = sxpar (header, 'EXPTIME', count=nrecords)
IF (nrecords EQ 0) THEN exposure = sxpar (header,'EXPOSURE')
 
;--- datatype = science.

IF (datatype EQ "science") THEN $
BEGIN ;{
   OPENW,  1, process_dir + '/science_files.txt', /APPEND
   PRINTF, 1, $
   format='(a, 3x, f10.4, 2x, "ms", 2x, "Data: ", a, 3x, "Dark: ", a, 3x, "Diff: ", a, 3x, "Cal: ", a, 3x, "Ang: ", f6.1)',$
   filename, exposure, datatype, darkshut, diffuser, calpol, calpang
 
   ;--- Print a measure of every image in the cube.

   image = readfits (filename, /SILENT) 
   FOR camera = 0, 1 DO $
   BEGIN  ;{
      FOR sequence = 0, 3 DO $
      BEGIN  ;{
         PRINTF, 1, format = '(e12.5, "   ", $)', $
	            mean (image[*, *, sequence, camera])
      ENDFOR ;}
   ENDFOR ;}
   PRINTF, 1
   CLOSE,  1
ENDIF
 
;--- datatype = calibration.

IF (datatype EQ "calibration") THEN $
BEGIN  ;{
   OPENW,  1, process_dir + '/calibration_files.txt', /APPEND
   PRINTF, 1, $
   format='(a, 3x, f10.4, 2x, "ms", 2x, "Data: ", a, 3x, "Dark: ", a, 3x, "Diff: ", a, 3x, "Cal: ", a, 3x, "Ang: ", f6.1, "  means: ", $)',$
   filename, exposure, datatype, darkshut, diffuser, calpol, calpang
 
   ;--- Print a measure of every image in the cube.

   image = readfits (filename, /SILENT)
   FOR camera = 0, 1 DO $
   BEGIN  ;{
      FOR sequence = 0, 3 DO $
      BEGIN  ;{
        PRINTF, 1, format='(e12.5, "   ", $)', mean (image[*,*,sequence,camera])
      ENDFOR ;}
   ENDFOR ;}
   PRINTF, 1
   CLOSE,  1
ENDIF ;}
 
;--- datatype = engineering.

IF (datatype EQ "engineering") THEN $
BEGIN ;{
   OPENW,  1, process_dir + '/engineering_files.txt', /APPEND
   PRINTF, 1, $
   format='(a, 3x, f10.4, 2x, "ms", 2x, "Data: ", a, 3x, "Dark: ", a, 3x, "Diff: ", a, 3x, "Cal: ", a, 3x, "Ang: ", f6.1)',$
   filename, exposure, datatype, darkshut, diffuser, calpol, calpang
   CLOSE, 1
ENDIF ;}
 
;--- datatype = unknown.

IF ((datatype NE "science") && (datatype NE "calibration") && $
    (datatype NE "engineering")) THEN $
BEGIN ;{
   OPENW,  1, process_dir + '/misc_files.txt', /APPEND
   PRINTF, 1, $
   format='(a, 3x, f10.4, 2x, "ms", 2x, "Data: ", a, 3x, "Dark: ", a, 3x, "Diff: ", a, 3x, "Cal: ", a, 3x, "Ang: ", f6.1)',$
   filename, exposure, datatype, darkshut, diffuser, calpol, calpang
   CLOSE, 1
ENDIF ;}

END
