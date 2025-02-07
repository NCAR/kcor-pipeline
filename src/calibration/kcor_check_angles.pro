; docformat = 'rst'

;+
; Determine if all of the required angles are present in the given angles (mod
; 180 degrees) to a given tolerance. Optionally, determine the allowable angles
; in the given angles, i.e., the ones that are in the set of required or
; optional angles.
;
; :Returns:
;   1B if required angles are present, 0B if not
;
; :Params:
;   required_angles : in, required, type=fltarr
;     the required angles
;   optional_angles : in, required, type=fltarr
;     the optional angles
;   angles : in, required, type=fltarr(n)
;     angles measured
;
; :Keywords:
;   tolerance : in, optional, type=float, default=0.1
;     allowable difference between required angle and measured angle
;   mask : out, optional, type=bytarr(n)
;     boolean mask of the allowable angles (in the required or optional sets)
;-
function kcor_check_angles, required_angles, optional_angles, $
                            angles, $
                            tolerance=tolerance, $
                            mask=mask, $
                            logger_name=logger_name
  compile_opt strictarr

  _tolerance = n_elements(tolerance) eq 0L ? 0.1 : tolerance  ; degrees

  n_angles = n_elements(angles)
  mask = bytarr(n_angles)

  for a = 0L, n_elements(required_angles) - 1L do begin
    valid_angles = kcor_angles_mod(required_angles[a], angles) lt _tolerance
    !null = where(valid_angles, n_valid_angles)
    if (n_valid_angles eq 0L) then begin
      mg_log, 'missing required angle %0.2f in pol files', $
              required_angles[a], $
              name=logger_name, /warn
      return, 0B
    endif
  endfor

  for a = 0L, n_angles - 1L do begin
    if (n_elements(optional_angles) gt 0L) then begin
      !null = where(kcor_angles_mod(angles[a], optional_angles) lt _tolerance, n_optional_angles)
    endif else n_optional_angles = 0L
    !null = where(kcor_angles_mod(angles[a], required_angles) lt _tolerance, n_required_angles)
    mask[a] = (n_optional_angles gt 0L) || (n_required_angles gt 0L)
    if ((n_optional_angles eq 0L) && (n_required_angles eq 0L)) then begin
      mg_log, 'cal angle %0.2f not required or optional, removing...', $
              angles[a], $
              name=logger_name, /warn
    endif
  endfor

  return, 1B
end


; main-level example program
required_angles = [0.0, 45.0, 90.0, 135.0]

; angles = [-0.02, 0.0, 0.02, 22.48, 22.5, 22.52, 44.98, 45.0, 45.02, $
;           89.98, 90.0, 90.02, 134.98, 135.0, 135.02, 179.98, 180.0, 180.01]
; print, kcor_check_angles(required_angles, $
;                          required_angles + 22.5, $
;                          angles, $
;                          mask=mask)
; print, mask
; 
; angles = [0.0, 22.5, 45.0, 90.0, 135.0, 22.4]
; print, kcor_check_angles(required_angles, $
;                          required_angles + 22.5, $
;                          angles, $
;                          mask=mask)
; print, mask

date = '20140102'
config_basename = 'kcor.latest.cfg'
config_filename = filepath(config_basename, $
                           subdir=['..', '..', '..', 'kcor-config'], $
                           root=mg_src_root())

run = kcor_run(date, config_filename=config_filename)

file_list = kcor_read_calibration_text(date, $
                                       run->config('processing/process_basedir'), $
                                       exposures=exposures, $
                                       n_files=n_files, $
                                       run=run)

catalog_dir = filepath('level0', subdir=date, $
                       root=run->config('processing/raw_basedir'))
kcor_reduce_calibration_read, file_list, catalog_dir, $
                              data=data, $
                              metadata=metadata, $
                              run=run
valid = kcor_check_angles(required_angles, $
                          required_angles + 22.5, $
                          metadata.angles, $
                          mask=angle_mask)

obj_destroy, run

end
