; docformat = 'rst'

;+
; Retrieve a global attribute that might not be present from a netCDF file.
;
; :Returns:
;   attribute value
;
; :Params:
;   file_id : in, required, type=integer
;     netCDF file identifier
;   attname : in, required, type=string
;     name of global attribute
;
; :Keywords:
;   error : out, optional, type=long
;     set to named variable to retrieve the error status of the attribute fetch,
;     0 for no error
;   default : in, optional, type=any, default=!null
;     default value if attribute value not found
;-
function kcor_nc_getattribute, file_id, attname, error=error, default=default
  compile_opt strictarr

  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    data = n_elements(default) eq 0L ? !null : default
    goto, done
  endif

  old_quiet = !quiet
  !quiet = 1

  ncdf_attget, file_id, 'epoch_version', data, /global

  done:
  !quiet = old_quiet
  return, data
end
