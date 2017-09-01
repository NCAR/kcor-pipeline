;+
;Name: IS_GDL
;
;Purpose: This function is the test to see
;	if you are using GDL and not using IDL
;
;Method: Calls running_gdl
;History: 2-jul-2010 Richard.schwartz@gsfc.nasa.gov,
;-

function is_gdl, x, _extra=_extra

RETURN, running_gdl()

end
