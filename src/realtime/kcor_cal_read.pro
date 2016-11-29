;+
;-------------------------------------------------------------------------------
; pro kcor_cal_read, file_list, data, metadata, verbose=verbose
;-------------------------------------------------------------------------------
; :description: Reads in the data for the calibration data reduction.
;-------------------------------------------------------------------------------
; :params:
; file_list   in, string, name of file containing a list of calibration images.
; data        out, 
; metadata    out, 
;-------------------------------------------------------------------------------
; :keywords:
; verbose     in, optional.  Set to print information.
;-------------------------------------------------------------------------------
; :history:
; 02 Dec 2015 [ALS] Andrew Stanger
; Same procedure as kcor_reduce_calibration_read_data.
; The only changes are cosmetic.
;-------------------------------------------------------------------------------
;-

pro kcor_cal_read, file_list, data, metadata, verbose=verbose

;-----------------------------------------------------
; Get diffuser intensity from somewhere in 1E-6 B_sun.
;-----------------------------------------------------

idiff = 13.8	; from Elmore et al, SPIE, 
		;'Polarimetry in Astronomy', V 4843, pp 66-75

;-----------------------------------------------------------
; Read header of the first file to determine image size etc.
;-----------------------------------------------------------

header = fitshead2struct (headfits (file_list [0]))
date   = (strsplit (header.date_obs, 'T', /extract))[0]
dark   = fltarr (header.naxis1, header.naxis2, 2)
clear  = fltarr (header.naxis1, header.naxis2, 2)
calibration = fltarr (header.naxis1,header.naxis2,4,2,n_elements(file_list))
angles = fltarr (n_elements (file_list))

;----------------------------------------
; Read files and populate data structure.
;----------------------------------------

gotdark  = 0
gotclear = 0
gotcal   = 0
vdimref  = 0.
file_types = replicate ('unused', n_elements (file_list))

for f = 0, n_elements (file_list) - 1 do $
begin ;{
  thisdata = readfits (file_list[f], header, /silent)
  header = fitshead2struct (header)
  if strmatch (header.darkshut, '*in*', /fold_case) then $
  begin ;{
    dark += mean (thisdata, dimension=3)
    gotdark++
    file_types [f] = 'dark'
    if (keyword_set (verbose)) then print, 'Found dark, file ' + file_list[f]
  endif $ ;}
  else if (strmatch (header.diffuser, '*in*', /fold_case)) then $
  begin ;{
    if strmatch (header.calpol, '*out*', /fold_case) then $
    begin ;{
      clear += mean (thisdata, dimension=3)
      vdimref += header.sgsdimv
      gotclear++
      file_types [f] = 'clear'
      if (keyword_set (verbose)) then print, 'Found clear, file ' + file_list[f]
    endif $ ;}
    else begin ;{
      calibration [*,*,*,*,gotcal] = thisdata
      angles [gotcal] = header.calpang
      gotcal++
      file_types [f] = 'calibration'
      if (keyword_set (verbose)) then $
        print, 'Found calibration data, file ' + $
               file_list [f] + ', angle ' + string (header.calpang)
    endelse ;}
  endif ;}
endfor ;}

;-----------------------------------------------
; Check that we have all required data products.
;-----------------------------------------------

if (gotdark ne 0) then $
begin ;{
  dark /= float (gotdark)
endif else begin ;{
  message, 'No dark data found!'
endelse ;}

if (gotclear ne 0) then $
begin      ;{
  ;--------------------
  ; Determine the gain.
  ;--------------------

  gain = (clear / float (gotclear) - dark) / idiff

  ;-------------------------------------
  ; Determine the DIM reference voltage.
  ;-------------------------------------

  vdimref /= float (gotclear)
endif $    ;}
else begin ;{
  message, 'No clear data found!'
endelse    ;}

if (gotcal ge 4) then $
begin ;{

  ;----------------------------------------------------
  ; Resize to the actual number of polarizer positions.
  ;----------------------------------------------------

  calibration = calibration [*, *, *, *, 0:gotcal-1]
  angles = angles [0:gotcal-1]
endif $ ;}
else begin ;{
  message, 'Insufficient calibration positions!'
endelse    ;}

data =     { dark:dark, gain:gain, calibration:calibration }
metadata = { angles:angles, idiff:idiff, vdimref:vdimref, date:date, $
             file_list:file_list, file_types:file_types }

end
