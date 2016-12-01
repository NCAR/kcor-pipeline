; docformat = 'rst'

;+
; Execute the "kcor_catalog.pro" procedure for all kcor L0 fits files
; for a specified date.
;
; syntax: dokcor_catalog, 'yyyymmdd'
; yyyymmdd: observation date.  Example: '20150527' (27 May 2015).
;
; :Author:
;   Andrew L. Stanger   HAO/NCAR	MLSO K-coronagraph
;   18 March 2015
;-
pro dokcor_catalog, date
  compile_opt strictarr

  common kcor_paths, bias_dir, flat_dir, mask_dir, binary_dir, $
                     raw_basedir, process_basedir, hpss_gateway, $
                     archive_dir, movie_dir, fullres_dir, log_dir

;--- Set up directory paths.

kcor_paths

l0_dir = raw_basedir + '/' + date + '/level0'

;--- If date directory does not exist in 'process_basedir', create it.

process_datedir = process_basedir + '/' + date

IF (NOT FILE_TEST (process_datedir, /DIRECTORY)) THEN $
   FILE_MKDIR, process_datedir

;--- Move to kcor L0 directory.

CD, l0_dir

;--- Create a list of L0 fits files.

listfile = 'list'
spawn, 'ls -1 *.fts* > list'

;--- Read L0 file list and invoke 'kcor_catalog.pro' procedure.

fits_file = ''
num_img   = 0
GET_LUN, ULIST
OPENR,   ULIST, listfile

WHILE (NOT EOF (ULIST)) DO $
BEGIN ;{
   num_img += 1
   num_str = string (format='(i4)', num_img)
   READF, ULIST, fits_file
   print, num_img, ' ', fits_file
   kcor_catalog, fits_file
END   ;}

END

