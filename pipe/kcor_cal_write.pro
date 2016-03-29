;+
;-------------------------------------------------------------------------------
; pro kcor_cal_write, data, metadata, $
;  		      pixels, fits, fiterrors, mmat, dmat, outfile
;-------------------------------------------------------------------------------
; :description:
; Writes kcor calibration information into a netcdf file.
;-------------------------------------------------------------------------------
; :params:
; data		in
; metadata	in
; pixels	in
; fits		in
; fiterrors	in
; mmat		in
; dmat		in
; outfile	in, string
;-------------------------------------------------------------------------------
; :history:
; 02 Dec 2015 [ALS] Andrew Stanger
; Same procedure as 'kcor_reduce_calibration_write_data'.
; The only differences are cosmetic.
;-------------------------------------------------------------------------------
;-

pro kcor_cal_write, data, metadata, pixels, fits, fiterrors, mmat, dmat, outfile

dark       = data.dark
gain       = data.gain
vdimref    = metadata.vdimref
date       = metadata.date
file_list  = metadata.file_list
file_types = metadata.file_types

sz = size (data.gain, /dimensions)

cid = ncdf_create (outfile, /clobber, /netcdf4_format)
ncdf_attput, cid, /global, 'title', 'COSMO K-Cor Calibration Data for ' + date

;-------------------
; Define dimensions.
;-------------------

filesdim  = ncdf_dimdef (cid, 'Number of Files', n_elements( file_list))
pixelsdim = ncdf_dimdef (cid, 'Number of Pixels', n_elements (pixels) / 2)
scalardim = ncdf_dimdef (cid, 'scalar', 1)
vectordim = ncdf_dimdef (cid, '2-vector', 2)
paramsdim = ncdf_dimdef (cid, 'Number of Model Parameters', 18)
xdim      = ncdf_dimdef (cid, 'x', sz[0])
ydim      = ncdf_dimdef (cid, 'y', sz[1])
beamdim   = ncdf_dimdef (cid, 'beam', 2)
stokesdim = ncdf_dimdef (cid, 'Stokes IQU', 3)
statedim  = ncdf_dimdef (cid, 'state', 4)

;------------------
; Define variables.
;------------------

filelistvar  = ncdf_vardef (cid, 'Input File List', [filesdim], /string)
filetypesvar = ncdf_vardef (cid, 'Input File Type', [filesdim], /string)
darkvar      = ncdf_vardef (cid, 'Dark', [xdim, ydim, beamdim], /float)
gainvar      = ncdf_vardef (cid, 'Gain', [xdim, ydim, beamdim], /float)
dimrefvar    = ncdf_vardef (cid, 'DIM Reference Voltage', [scalardim], /float)

ncdf_attput, cid, dimrefvar, 'units', 'V'

pixelsvar    = ncdf_vardef (cid, 'Pixels Fit with Model', $
                                 [vectordim,pixelsdim], /short)
fitsvar      = ncdf_vardef (cid, 'Model Fit Parameters', $
                                 [paramsdim,pixelsdim], /float)
fiterrorsvar = ncdf_vardef (cid, 'Model Fit Parameters Formal Errors', $
                                 [paramsdim,pixelsdim], /float)
mmatvar      = ncdf_vardef (cid, 'Modulation Matrix', $
                            [xdim, ydim, beamdim, stokesdim, statedim], /float)
dmatvar      = ncdf_vardef (cid, 'Demodulation Matrix', $
                            [xdim, ydim, beamdim, statedim, stokesdim], /float)

if (filelistvar eq -1 or filetypesvar eq -1 or darkvar eq -1 or $
    gainvar eq -1 or dimrefvar eq -1 or fitsvar eq -1 or $
    fiterrorsvar eq -1 or mmatvar eq -1 or dmatvar eq -1) then $
  message, $
    'Something went wrong while attempting to create the NetCDF output file.'

;-------------------------------------------
; Done defining the NetCDF file, write data.
;-------------------------------------------

ncdf_control, cid, /endef
ncdf_varput,  cid, filelistvar, file_list
ncdf_varput,  cid, filetypesvar, file_types
ncdf_varput,  cid, darkvar, dark
ncdf_varput,  cid, gainvar, gain
ncdf_varput,  cid, dimrefvar, vdimref
ncdf_varput,  cid, pixelsvar, pixels
ncdf_varput,  cid, fitsvar, fits
ncdf_varput,  cid, fiterrorsvar, fiterrors
ncdf_varput,  cid, mmatvar, mmat
ncdf_varput,  cid, dmatvar, dmat

;----------------
; Close the file.
;----------------
ncdf_close, cid
end
