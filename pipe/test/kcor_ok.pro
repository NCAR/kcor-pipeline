;+
; kcor_ok.pro
;-------------------------------------------------------------------------------
; Create list of 'ok' L0 kcor FITS files to process.
;-------------------------------------------------------------------------------
; Andrew L. Stanger   HAO/NCAR
;-------------------------------------------------------------------------------
; 26 Feb 2015
;-------------------------------------------------------------------------------

pro kcor_ok, date

np = n_params ()

IF (np EQ 0) THEN $
BEGIN ;{
   PRINT, "kcor_ok, 'yyyymmdd'"
   RETURN
END   ;}

;-------------------------------------------------------------------------------
; Define directory names.
;-------------------------------------------------------------------------------

l0_base = '/hao/mlsodata1/Data/KCor/raw/'	; base directory.
l0_dir  = l0_base + date + '/'			; L0 files.
q_dir   = l0_dir  + 'q/'			; quality directory.
q_ok    = q_dir   + 'ok/'			; ok gif files.

;--- Move to 'ok' directory.

CD, current=start_dir				; save current directory.
CD, q_ok

;--- Create a list of 'ok' gif files.

spawn, 'ls -1 *.gif > okg.ls'

okg_list = 'okg.ls'
okf_list = 'okf.ls
nfiles   = fix (file_lines (okg_list))		; # files in 'okg.ls'.
IF (nfiles GT 0) THEN $
BEGIN ;{
   gfile = ""
   ffile = ""
   GETLUN, GLUN
   GETLUN, FLUN
   openr, GLUN, okg_list
   openw, FLUN, okf_list
   while ~ EOF (GLUN) DO $
   BEGIN ;{
      readf, GLUN, gfile
      ffile = STRMID (gfile, 0, 15) + '_kcor.fts.gz'
      PRINT, 'ffile: ', ffile
      writef, FLUN, ffile
   END   ;}
   close, GLUN
   close, FLUN
   FREE_LUN, GLUN
   FREE_LUN, FLUN
END $ ;}
ELSE $
BEGIN ;{
   PRINT, 'No ok L0 files to process.'
END   ;}

;FILE_DELETE, okg_list				; Delete 'okg.ls' file.

END
