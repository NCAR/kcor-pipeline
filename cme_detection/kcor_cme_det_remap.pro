;+
; Project     :	MLSO - KCOR
;
; Name        :	KCOR_CME_DET_REMAP
;
; Purpose     :	Remap K-cor image data into polar map
;
; Category    :	KCOR, CME, Detection
;
; Explanation :	Takes a K-cor image, and remaps it into helioprojective-radial
;               polar coordinates.
;
; Syntax      :	KCOR_CME_DET_REMAP, HEADER, IMAGE, OUTFILE, HMAP, MAP
;
; Examples    :	See KCOR_CME_DET_EVENT
;
; Inputs      :	HEADER  = FITS header
;               IMAGE   = Original K-cor image
;               OUTFILE = Output filename.  The file is only written if the
;                         parameter STORE is set in the common block.
;
; Opt. Inputs :	None
;
; Outputs     :	HMAP    = FITS header for output file
;               MAP     = Reformatted map
;
; Opt. Outputs:	None
;
; Keywords    :	None
;
; Calls       :	FILE_EXIST, FXREAD, FITSHEAD2WCS, WCS_CONVERT_TO_COORD,
;               WCS_GET_PIXEL, INTERPOLATE, AVERAGE, FXHMAKE, FXADDPAR, FXWRITE
;
; Common      :	KCOR_CME_DETECTION defined in kcor_cme_detection.pro
;
; Restrictions:	None
;
; Side effects:	None
;
; Prev. Hist. :	None
;
; History     :	Version 1, 05-Jan-2017, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
pro kcor_cme_det_remap, header, image, outfile, hmap, map
  compile_opt strictarr
  @kcor_cme_det_common

  ; Define the longitude and latitude arrays.
  lon = reverse((dindgen(navg * nlon) - (navg - 1) / 2.d0) * (360.d0 / navg / nlon))
  lon0 = rebin(reform(lon, navg * nlon, 1), navg * nlon, nrad)
  lon = average(reform(lon, navg, nlon), 1)

  drad = 5.643d0 / 3600
  lat = drad * (195 + dindgen(nrad)) - 90
  lat0 = rebin(reform(lat, 1, nrad), navg * nlon, nrad)
  crpix2 = 90 / drad - 195 + 1

  ; If the output file already exists, then simply read it in.
  if (file_exist(outfile)) then fxread, outfile, map, hmap else begin
    ; Otherwise, generate the map.
    wcs = fitshead2wcs(header)
    wcs_convert_to_coord, wcs, coord, 'hpr', lon0, lat0
    pixel = wcs_get_pixel(wcs, coord)
    map0 = interpolate(image, pixel[0, *, *], pixel[1, *, *], missing=0, /cubic)
    map0 = reform(map0, navg, nlon, nrad, /overwrite)
    map = average(map0, 1, missing=0)

    ; Update the header information.
    hmap = header
    fxhmake, hmap, map
    fxaddpar, hmap, 'bzero', 0.0
    fxaddpar, hmap, 'bscale', 1.0
    fxaddpar, hmap, 'datamin', min(map, max=mmax)
    fxaddpar, hmap, 'datamax', mmax
    fxaddpar, hmap, 'wcsname', 'helioprojective-radial'
    fxaddpar, hmap, 'ctype1', 'HRLN-CAR', '[deg] position angle'
    fxaddpar, hmap, 'crpix1', 1.0, '[pixel] lower-left corner'
    fxaddpar, hmap, 'crval1', 0.0, '[deg]'
    fxaddpar, hmap, 'cdelt1', 360.0 / nlon, '[deg] angular width'
    fxaddpar, hmap, 'cunit1', 'deg'
    fxaddpar, hmap, 'ctype2', 'HRLT-CAR', '[deg] elevation - 90 degrees'
    fxaddpar, hmap, 'crpix2', crpix2, '[pixel] position of equator'
    fxaddpar, hmap, 'crval2', 0.0, '[deg] equator'
    fxaddpar, hmap, 'cdelt2', drad, '[deg] elevation increment'
    fxaddpar, hmap, 'cunit2', 'deg'
    fxaddpar, hmap, 'pc1_1', 1.0
    fxaddpar, hmap, 'pc1_2', 0.0
    fxaddpar, hmap, 'pc2_1', 0.0
    fxaddpar, hmap, 'pc2_2', 1.0
    fxaddpar, hmap, 'history', 'Converted to helioprojective-radial coordinates'

    ; Write the output file.
    if (keyword_set(store)) then begin
      fxwrite, outfile, hmap, map
      gif_filename = filepath(file_basename(outfile, '.fts.gz') + '.gif', $
                              root=file_dirname(outfile))
      kcor_cme_det_hpr_gif, gif_filename, hmap
    endif
  endelse
end
