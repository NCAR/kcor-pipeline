function kcor_reduce_calibration_read_data, file
	cid = ncdf_open(file)

	; define variables
	filelistvar = ncdf_varid(cid, 'Input File List')
	filetypesvar = ncdf_varid(cid, 'Input File Type')
	darkvar = ncdf_varid(cid, 'Dark')
	gainvar = ncdf_varid(cid, 'Gain')
	dimrefvar = ncdf_varid(cid, 'DIM Reference Voltage')
	pixelsvar = ncdf_varid(cid, 'Pixels Fit with Model')
	fitsvar = ncdf_varid(cid, 'Model Fit Parameters')
	fiterrorsvar = ncdf_varid(cid, 'Model Fit Parameters Formal Errors')
	mmatvar = ncdf_varid(cid, 'Modulation Matrix')
	dmatvar = ncdf_varid(cid, 'Demodulation Matrix')

	; done defining the NetCDF file, write data
	ncdf_varget, cid, filelistvar, file_list
	ncdf_varget, cid, filetypesvar, file_types
	ncdf_varget, cid, darkvar, dark
	ncdf_varget, cid, gainvar, gain
	ncdf_varget, cid, dimrefvar, vdimref
	ncdf_varget, cid, pixelsvar, pixels
	ncdf_varget, cid, fitsvar, fits
	ncdf_varget, cid, fiterrorsvar, fiterrors
	ncdf_varget, cid, mmatvar, mmat
	ncdf_varget, cid, dmatvar, dmat

	; close the file
	ncdf_close, cid

	return, {file_list:file_list, file_types:file_types, $
		dark:dark, gain:gain, $
		vdimref:vdimref, $
		pixels:pixels, fits:fits, fiterrors:fiterrors, $
		mmat:mmat, dmat:dmat}
end
