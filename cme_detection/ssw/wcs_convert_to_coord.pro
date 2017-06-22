;+
; Project     :	STEREO
;
; Name        :	WCS_CONVERT_TO_COORD
;
; Purpose     :	Convert WCS coordinates from other to native system
;
; Category    :	Coordinates, WCS
;
; Explanation :	This routine converts one of the standard solar image
;               coordinate systems into the native solar coordinates of a FITS
;               file using the World Coordinate System.  The supported
;               coordinate systems are:
;
;                       Helioprojective-Cartesian       (HPC)
;                       Helioprojective-Radial          (HPR)
;                       Heliocentric-Cartesian          (HCC)
;                       Heliocentric-Radial             (HCR)
;                       Stonyhurst-Heliographic         (HG)
;                       Carrington-Heliographic         (HG, /CARRINGTON)
;
;               The helioprojective coordinates are angular position as seen by
;               the observer, while heliocentric coordinates are the
;               equivalents in spatial units (e.g. kilometers).
;
;               Stonyhurst and Carrington heliographic coordinates are
;               distinguished by the /CARRINGTON keyword.
;
;               The actual work is done by individual routines such as
;               WCS_CONV_HPC_HPR, which can be called separately if desired.
;
; Syntax      :	WCS_CONVERT_TO_COORD, WCS, COORD, SYSTEM, X, Y  [, Z ]
;
; Examples    :	HGLN = FINDGEN(361) # REPLICATE(1,181)
;               HGLT = REPLICATE(1,361) # (FINDGEN(181) - 90)
;               WCS_CONVERT_TO_COORD, WCS, COORD, 'HG', HGLN, HGLT
;
; Inputs      :	WCS     = World Coordinate System structure
;
;               SYSTEM  = The two or three-letter abbreviation as described
;                         above for the coordinate system that the data should
;                         be converted from.
;
;               X       = The equivalent of X in the source coordinate system.
;                         For angular coordinate systems, this would be the
;                         longitude.  For heliocentric-radial coordinates, this
;                         would be the angle PHI.
;
;               Y       = The equivalent of Y in the source coordinate system.
;                         For angular coordinates, this would be the latitude.
;                         For heliocentric-radial coordinates, this would be
;                         the distance RHO.
;
; Opt. Inputs :	Z       = The equivalent of Z in the source coordinate system.
;                         For angular coordinate systems, this would be the
;                         radial distance.  If insufficient information is
;                         available to derive this parameter, then it will be
;                         returned as undefined.
;
; Outputs     :	COORD   = Array of coordinate values, from WCS_GET_COORD.
;
; Opt. Outputs:	None.
;
; Keywords    :	LENGTH_UNITS = String describing the length units of the input
;                         data.  See WCS_CONV_FIND_DSUN for more information.
;
;               ANG_UNITS = String describing the input angular units.  See
;                         WCS_CONV_FIND_ANG_UNITS for more information.
;
;               CARRINGTON = If set, and SYSTEM is 'HG', then the input
;                         longitude is a Carrington longitude.  The default is
;                         Stonyhurst longitude.
;
;               INDEX_Z = The index of the Z axis data in the COORD array, from
;                         0 to NAXIS-1.  If not passed, then the routine tries
;                         to recognize the axis based on the coordinate system.
;                         Setting INDEX_Z=-1 disables the input Z axis.
;
;               POS_LONG = If set, then force the output longitude to be
;                         positive, i.e. between 0 and 360 degrees.  The
;                         default is to return values between +/- 180 degrees.
;                         Used for HG, HPR, or HCR coordinates
;
;               REF_VALUE = An array containing a reference value for each axis
;                         in the WCS structure.  Must have same dimension as
;                         WCS.CRVAL.  This is used to assign values to
;                         non-spatial axes such as wavelength or time.
;
;               REF_PIXEL = An array containing the reference pixel location to
;                         use for assigning REF_VALUE.  If neither REF_VALUE
;                         nor REF_PIXEL are passed, then WCS.CRVAL is used.
;
;               GET_PIXEL = If set, then return the pixel positions instead of
;                         the coordinates themselves.
;
;               QUICK   = For conversion between HPC and HPR coordinates, if
;                         /QUICK is set, do a quick approximate calculation
;                         rather than a full-blown spherical calculation.  This
;                         is only appropriate for small angular distances close
;                         to the Sun.
;
; Calls       :	DELVARX, VALID_WCS, WCS_CONV_FIND_ANG_UNITS, WCS_CONV_CR_HG,
;               WCS_CONV_HCC_HCR, WCS_CONV_HCC_HG, WCS_CONV_HCC_HPC,
;               WCS_CONV_HCR_HCC, WCS_CONV_HCR_HPR, WCS_CONV_HG_CR,
;               WCS_CONV_HG_HCC, WCS_CONV_HPC_HCC, WCS_CONV_HPC_HPR,
;               WCS_CONV_HPR_HCR, WCS_CONV_HPR_HPC, WCS_CONV_FIND_DSUN,
;               WCS_PARSE_UNITS, WCS_GET_PIXEL
;
; Common      :	None.
;
; Restrictions:	None.
;
; Side effects: None.
;
; Prev. Hist. :	None.
;
; History     :	Version 1, 12-Dec-2008, William Thompson, GSFC
;
; Contact     :	WTHOMPSON
;-
;
pro wcs_convert_to_coord, wcs, coord, type, x_in, y_in, z_in, $
                          carrington=carrington, index_z=index_z, $
                          ref_value=ref_value, ref_pixel=ref_pixel, $
                          get_pixel=get_pixel, _extra=_extra
on_error, 2
;
if n_params() lt 5 then message, $
  'Syntax: WCS_CONVERT_TO_COORD, WCS, COORD, SYSTEM, X, Y,  [, Z ]'
;
;  Make sure that a valid WCS structure was passed.
;
if not valid_wcs(wcs) then message, 'Input not recognized as WCS structure'
;
;  Make sure that X_IN and Y_IN have the same dimensions.
;
if n_elements(x_in) eq 0 then message, 'Input X is not defined'
sz = size(x_in)
ndim = sz[0]
if ndim ge 1 then dim = sz[1:sz[0]] else dim = 1
sz = size(y_in)
ndimy = sz[0]
if ndimy ne ndim then message, 'Inputs X and Y have incompatible dimensions'
if ndimy ge 1 then dimy = sz[1:sz[0]] else dimy = 1
for i=0,ndim-1 do if dim[i] ne dimy[i] then message, $
  'Inputs X and Y have incompatible dimensions'
;
;  If the INDEX_Z keyword was not passed, then look for the output Z array,
;  based on the coordinate type as given by the WCS structure.
;
iz = -1
if n_elements(index_z) eq 1 then iz = index_z else begin
    case wcs.coord_type of
        'Helioprojective-Cartesian': zname = 'DIST'
        'Helioprojective-Radial':    zname = 'DIST'
        'Heliocentric-Cartesian':    zname = 'SOLZ'
        'Heliocentric-Radial':       zname = 'SOLZ'
        'Stonyhurst-Heliographic':   zname = 'HECR'
        'Carrington-Heliographic':   zname = 'HECR'
        else: message, 'Coordinate type ' + wcs.coord_type + ' not supported'
    endcase
;
    ctype = strupcase(strmid(wcs.ctype,0,4))
    w = where(ctype eq zname, count)
    if count gt 0 then iz = w[0]
endelse
;
;  Get the default conversion factors for length and angular units.
;
wcs_conv_find_dsun, dsun, rsun, factor, wcs=wcs, _extra=_extra
wcs_conv_find_ang_units, cx, cy, /to_degrees, _extra=_extra
;
;  Perform the conversion, based on the coordinate type.  Start with
;  Helioprojective-Cartesion.
;
case wcs.coord_type of
    'Helioprojective-Cartesian': begin
        case strupcase(type) of
            'HPC': begin
                x_out = x_in * cx
                y_out = y_in * cy
                if n_elements(z_in) gt 0 then z_out = z_in
            endcase
            'HPR': begin
                wcs_conv_hpr_hpc, x_in, y_in, x_out, y_out, wcs=wcs, $
                  arcseconds=0, _extra=_extra
                if n_elements(z_in) gt 0 then z_out = z_in
            endcase
            'HCC': wcs_conv_hcc_hpc, x_in, y_in, x_out, y_out, z_out, $
              wcs=wcs, solz=z_in, factor=factor, arcseconds=0, _extra=_extra
            'HCR': begin
                wcs_conv_hcr_hcc, x_in, y_in, x_temp, y_temp, _extra=_extra
                wcs_conv_hcc_hpc, x_temp, y_temp, x_out, y_out, z_out, $
                  wcs=wcs, solz=z_in, factor=factor, arcseconds=0, $
                  _extra=_extra
            endcase
            'HG': begin
                wcs_conv_hg_hcc, x_in, y_in, x_temp, y_temp, z_temp, wcs=wcs, $
                  carrington=carrington, hecr=z_in, _extra=_extra
                wcs_conv_hcc_hpc, x_temp, y_temp, x_out, y_out, z_out, $
                  wcs=wcs, solz=z_temp, factor=factor, arcseconds=0, $
                  _extra=_extra
            endcase
            else: message, 'Coordinate type ' + type + ' not supported'
        endcase
    endcase
;
    'Helioprojective-Radial': begin
        case strupcase(type) of
            'HPC': begin
                wcs_conv_hpc_hpr, x_in, y_in, x_out, y_out, wcs=wcs, $
                  _extra=_extra
                if n_elements(z_in) gt 0 then z_out = z_in
            endcase
            'HPR': begin
                x_out = x_in * cx
                y_out = y_in * cy
                if n_elements(z_in) gt 0 then z_out = z_in
            endcase
            'HCC': begin
                wcs_conv_hcc_hcr, x_in, y_in, x_out, y_temp, _extra=_extra
                wcs_conv_hcr_hpr, y_temp, y_out, z_out, wcs=wcs, solz=z_in, $
                  factor=factor, _extra=_extra
                w = where_missing(y_out, count)
                if count gt 0 then flag_missing, x_out, w
            endcase
            'HCR': begin
                wcs_conv_hcr_hpr, y_in, y_out, z_out, wcs=wcs, solz=z_in, $
                  factor=factor, _extra=_extra
                x_out = x_in * cx
                w = where_missing(y_out, count)
                if count gt 0 then flag_missing, x_out, w
            endcase
            'HG': begin
                wcs_conv_hg_hcc, x_in, y_in, x_temp, y_temp, z_temp, wcs=wcs, $
                  carrington=carrington, hecr=z_in, _extra=_extra
                wcs_conv_hcc_hcr, x_temp, y_temp, x_out, y_temp2, _extra=_extra
                wcs_conv_hcr_hpr, y_temp2, y_out, z_out, wcs=wcs, $
                  solz=z_temp, factor=factor, _extra=_extra
                w = where_missing(y_out, count)
                if count gt 0 then flag_missing, x_out, w
            endcase
            else: message, 'Coordinate type ' + type + ' not supported'
        endcase
    endcase
;
    'Heliocentric-Cartesian': begin
        case strupcase(type) of
            'HPC': wcs_conv_hpc_hcc, x_in, y_in, x_out, y_out, z_out, $
              distance=z_in, wcs=wcs, factor=factor, _extra=_extra
            'HPR': begin
                wcs_conv_hpr_hcr, y_in, y_temp, z_out, distance=z_in, $
                  wcs=wcs, factor=factor, _extra=_extra
                wcs_conv_hcr_hcc, x_in, y_temp, x_out, y_out, _extra=_extra
            endcase
            'HCC': begin
                x_out = x_in * cx
                y_out = y_in * cy
                if n_elements(z_in) gt 0 then z_out = z_in
            endcase
            'HCR': begin
                wcs_conv_hcr_hcc, x_in, y_in, x_out, y_out, _extra=_extra
                if n_elements(z_in) gt 0 then z_out = z_in
            endcase
            'HG': wcs_conv_hg_hcc, x_in, y_in, x_out, y_out, z_out, wcs=wcs, $
              carrington=carrington, hecr=z_in, _extra=_extra
            else: message, 'Coordinate type ' + type + ' not supported'
        endcase
    endcase
;
    'Heliocentric-Radial': begin
        case strupcase(type) of
            'HPC': begin
                wcs_conv_hpc_hcc, x_in, y_in, x_temp, y_temp, z_out, $
                  distance=z_in, wcs=wcs, factor=factor, _extra=_extra
                wcs_conv_hcc_hcr, x_temp, y_temp, x_out, y_out, _extra=_extra
            endcase
            'HPR': begin
                wcs_conv_hpr_hcr, y_in, y_out, z_out, distance=z_in, wcs=wcs, $
                  factor=factor, _extra=_extra
                x_out = x_in * cx
                w = where_missing(y_out, count)
                if count gt 0 then flag_missing, x_out, w
            endcase
            'HCC': begin
                wcs_conv_hcc_hcr, x_in, y_in, x_out, y_out, _extra=_extra
                if n_elements(z_in) gt 0 then z_out = z_in
            endcase
            'HCR': begin
                x_out = x_in * cx
                y_out = y_in * cy
                if n_elements(z_in) gt 0 then z_out = z_in
            endcase
            'HG': begin
                wcs_conv_hg_hcc, x_in, y_in, x_temp, y_temp, z_temp, wcs=wcs, $
                  carrington=carrington, hecr=z_in, _extra=_extra
                wcs_conv_hcc_hcr, x_temp, y_temp, x_out, y_out, _extra=_extra
                if n_elements(z_temp) gt 0 then z_out = z_temp
            endcase
            else: message, 'Coordinate type ' + type + ' not supported'
        endcase
    endcase
;
    'Stonyhurst-Heliographic': begin
        case strupcase(type) of
            'HPC': begin
                wcs_conv_hpc_hcc, x_in, y_in, x_temp, y_temp, z_temp, $
                  distance=z_in, wcs=wcs, factor=factor, _extra=_extra
                wcs_conv_hcc_hg, x_temp, y_temp, x_out, y_out, z_out, $
                  wcs=wcs, solz=z_temp, carrington=0, _extra=_extra
            endcase
            'HPR': begin
                wcs_conv_hpr_hcr, y_in, y_temp1, z_temp, distance=z_in, $
                  wcs=wcs, factor=factor, _extra=_extra
                wcs_conv_hcr_hcc, x_in, y_temp1, x_temp, y_temp, _extra=_extra
                wcs_conv_hcc_hg, x_temp, y_temp, x_out, y_out, z_out, $
                  wcs=wcs, solz=z_temp, carrington=0, _extra=_extra
            endcase
            'HCC': wcs_conv_hcc_hg, x_in, y_in, x_out, y_out, z_out, wcs=wcs, $
              solz=z_in, carrington=0, factor=factor, _extra=_extra
            'HCR': begin
                wcs_conv_hcr_hcc, x_in, y_in, x_temp, y_temp, _extra=_extra
                wcs_conv_hcc_hg, x_temp, y_temp, x_out, y_out, z_out, $
                  wcs=wcs, solz=z_in, carrington=0, factor=factor, $
                  _extra=_extra
            endcase
            'HG': begin
                y_out = y_in * cy
                if n_elements(z_in) gt 0 then z_out = z_in
                if keyword_set(carrington) then $
                  wcs_conv_cr_hg, x_in, x_out, wcs=wcs, _extra=_extra else $
                  x_out = x_in * cx
            endcase
            else: message, 'Coordinate type ' + type + ' not supported'
        endcase
    endcase
;
    'Carrington-Heliographic': begin
        case strupcase(type) of
            'HPC': begin
                wcs_conv_hpc_hcc, x_in, y_in, x_temp, y_temp, z_temp, $
                  distance=z_in, wcs=wcs, factor=factor, _extra=_extra
                wcs_conv_hcc_hg, x_temp, y_temp, x_out, y_out, z_out, $
                  wcs=wcs, solz=z_temp, carrington=1, _extra=_extra
            endcase
            'HPR': begin
                wcs_conv_hpr_hcr, y_in, y_temp1, z_temp, distance=z_in, $
                  wcs=wcs, factor=factor, _extra=_extra
                wcs_conv_hcr_hcc, x_in, y_temp1, x_temp, y_temp, _extra=_extra
                wcs_conv_hcc_hg, x_temp, y_temp, x_out, y_out, z_out, $
                  wcs=wcs, solz=z_temp, carrington=1, _extra=_extra
            endcase
            'HCC': wcs_conv_hcc_hg, x_in, y_in, x_out, y_out, z_out, wcs=wcs, $
              solz=z_in, carrington=1, factor=factor, _extra=_extra
            'HCR': begin
                wcs_conv_hcr_hcc, x_in, y_in, x_temp, y_temp, _extra=_extra
                wcs_conv_hcc_hg, x_temp, y_temp, x_out, y_out, z_out, $
                  wcs=wcs, solz=z_in, carrington=1, factor=factor, $
                  _extra=_extra
            endcase
            'HG': begin
                y_out = y_in * cy
                if n_elements(z_in) gt 0 then z_out = z_in
                if keyword_set(carrington) then x_out = x_in * cx else $
                  wcs_conv_hg_cr, x_in, x_out, wcs=wcs, _extra=_extra
            endcase
            else: message, 'Coordinate type ' + type + ' not supported'
        endcase
    endcase
;
    else: message, 'Coordinate type ' + wcs.coord_type + ' not supported'
endcase
;
;  Reformat the positions into a coordinate array.  Start by determining the
;  default values.
;
coord = wcs.crval
if n_elements(ref_value) ne 0 then begin
    if n_elements(ref_value) gt n_elements(coord) then message, /continue, $
      'REF_VALUE has wrong number of elements -- using WCS.CRVAL' else $
      coord[0] = ref_value[*]
end else if n_elements(ref_pixel) ne 0 then begin
    if n_elements(ref_pixel) gt n_elements(coord) then message, /continue, $
      'REF_PIXEL has wrong number of elements -- using WCS.CRVAL' else begin
        ref_value = wcs_get_coord(wcs, ref_pixel)
        coord[0] = ref_value[*]
    endelse
endif
coord = rebin(coord, [n_elements(wcs.crval), dim])
;
cc = 1.d0
case wcs.cunit[wcs.ix] of
    'arcmin': cc = cc / 60.d0
    'arcsec': cc = cc / 3600.d0
    'mas':    cc = cc / 3600.d3
    'rad':    cc = (180.d0 / !dpi)
    'deg':    cc = cc
    else: begin
        wcs_parse_units, wcs.cunit[wcs.ix], base_units, cc
        if base_units eq 'm' then cc = cc / factor else cc = 1
    endcase
endcase
coord[wcs.ix,*,*,*,*,*,*,*] = x_out / cc
;
cc = 1.d0
case wcs.cunit[wcs.iy] of
    'arcmin': cc = cc / 60.d0
    'arcsec': cc = cc / 3600.d0
    'mas':    cc = cc / 3600.d3
    'rad':    cc = (180.d0 / !dpi)
    'deg':    cc = cc
    else: begin
        wcs_parse_units, wcs.cunit[wcs.iy], base_units, cc
        if base_units eq 'm' then cc = cc / factor else cc = 1
    endcase
endcase
coord[wcs.iy,*,*,*,*,*,*,*] = y_out / cc
;
if iz gt 0 then begin
    cc = 1.d0
    case wcs.cunit[iz] of
        'arcmin': cc = cc / 60.d0
        'arcsec': cc = cc / 3600.d0
        'mas':    cc = cc / 3600.d3
        'rad':    cc = (180.d0 / !dpi)
        'deg':    cc = cc
        else: begin
            wcs_parse_units, wcs.cunit[iz], base_units, cc
            if base_units eq 'm' then cc = cc / factor else cc = 1
        endcase
    endcase
    coord[iz,*,*,*,*,*,*,*] = z_out / cc
endif
;
;  If /GET_PIXEL is set, then call WCS_GET_PIXEL
;
if keyword_set(get_pixel) then coord = wcs_get_pixel(wcs, coord, _extra=_extra)
;
return
end
