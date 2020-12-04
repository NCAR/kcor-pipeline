; docformat = 'rst'

function kcor_validate_file_checkspec, keyword_name, specline, $
                                       keyword_value, n_found, $
                                       error_list=error_list
  compile_opt strictarr

  required  = 0B
  type      = 7L
  value     = !null
  values    = !null
  tolerance = 0.0

  is_valid  = 1B

  if (size(keyword_value, /type) eq 7) then begin
    keyword_value = strtrim(keyword_value, 2)
  endif

  tokens = strtrim(strsplit(specline, ',', /extract, count=n_tokens), 2)
  for t = 0L, n_tokens - 1L do begin
    parts = strsplit(tokens[t], '=', /extract, count=n_parts)
    case parts[0] of
      'required': required = 1B
      'value': value = parts[1]
      'values': begin
          values = strsplit(strmid(parts[1], 1, strlen(parts[1]) - 2), $
                            '|', $
                            /extract, $
                            count=n_values)
        end
      'tolerance': tolerance = float(parts[1])
      'type': begin
          case strlowcase(parts[1]) of
            'boolean': type = 1
            'int': type = 3
            'float': type = 5
            'str': type = 7
          endcase
        end
    endcase
  endfor

  if (n_elements(value) gt 0L) then begin
    if (type eq 1) then begin
      value = byte(long(value))
    endif else value = fix(value, type=type)
  endif

  if (n_elements(values) gt 0L) then values = fix(values, type=type)

  if ((n_found eq 0) && (required eq 0B)) then return, 1B

  keyword_type = size(keyword_value, /type)
  ;if (keyword_type ne type) then begin
  ;  error_msg = string(keyword_type, type, $
  ;                     format='(%"type of keyword (%d) not spec type (%d)")')
  ;  return, 0B
  ;endif

  if (n_elements(value) gt 0) then begin
    if (n_found eq 0L) then begin
      if (obj_valid(error_list)) then begin
        error_list->add, string(keyword_name, format='(%"%s: no value")')
      endif
      is_valid = 0B
    endif else begin
      if (type eq 4 || type eq 5) then begin
        if (abs(keyword_value - value) gt tolerance) then begin
          if (obj_valid(error_list)) then begin
            error_msg = string(keyword_name, keyword_value, $
                               format='(%"%s: wrong value: %s")')
            error_list->add, error_msg
          endif
          is_valid = 0B
        endif 
      endif else begin
        if (keyword_value ne value) then begin
          if (obj_valid(error_list)) then begin
            error_msg = string(keyword_name, keyword_value, $
                               format='(%"%s: wrong value: %s")')
            error_list->add, error_msg
          endif
          is_valid = 0B
        endif
      endelse
    endelse
  endif

  if (n_elements(values) gt 0L) then begin
    ind = where(keyword_value eq values, count)
    if (count ne 1L) then begin
      if (obj_valid(error_list)) then begin
        error_msg = string(keyword_value, format='(%"not one of possible values: %s")')
        error_list->add, error_msg
      endif
      is_valid = 0B
    endif
  endif

  return, is_valid
end


function kcor_validate_file_checkheader, header, type, spec, $
                                         error_list=error_list
  compile_opt strictarr

  is_valid = 1B

  keywords = mg_fits_keywords(header, count=n_keywords)
  spec_keywords = spec->options(section=type, count=n_spec_keywords)

  if (n_keywords gt n_spec_keywords) then begin
    error_msg = string(n_keywords, n_spec_keywords, $
                       format='(%"more keywords (%d) than spec (%d)")')
    error_list->add, error_msg
    is_valid = 0B
  endif

  for k = 0L, n_spec_keywords - 1L do begin
    specline = spec->get(spec_keywords[k], section=type)
    value = fxpar(header, spec_keywords[k], count=n_found)
    is_valid_keyword = kcor_validate_file_checkspec(spec_keywords[k], $
                                                    specline, value, n_found, $
                                                    error_list=error_list)
    if (~is_valid_keyword) then is_valid = 0B
  endfor

  for k = 0L, n_keywords - 1L do begin
    value = spec->get(keywords[k], section=type, found=found)
    if (~found) then begin
      error_msg = string(keywords[k], $
                         format='(%"keyword %s not found in spec")')
      error_list->add, error_msg
      is_valid = 0B
    endif
  endfor

  return, is_valid
end


function kcor_validate_file_checkdata, data, type, spec, $
                                       error_list=error_list
  compile_opt strictarr

  is_valid = 1B

  _type = size(data, /type)
  specline = spec->get('type', section=type, count=count)
  type_valid = kcor_validate_file_checkspec('type', specline, _type, 1L)
  if (~type_valid) then begin
    error_msg = string(_type, format='(%"wrong type for data: %d")')
    error_list->add, error_msg
    is_valid = 0B
  endif

  _n_dims = size(data, /n_dimensions)
  specline = spec->get('ndims', section=type, count=count)
  ndims_valid = kcor_validate_file_checkspec('ndims', specline, _n_dims, 1L)
  if (~ndims_valid) then begin
    error_msg = string(_n_dims, format='(%"wrong number of dims for data: %d")')
    error_list->add, error_msg
    is_valid = 0B
  endif

  _dims = size(data, /dimensions)
  for d = 0L, _n_dims - 1L do begin
    dim_name = string(d, format='(%"dim%d")')
    specline = spec->get(dim_name, section=type, count=count)
    dim_valid = kcor_validate_file_checkspec(dim_name, specline, _dims[d], 1L)
    if (~dim_valid) then begin
      error_msg = string(strjoin(strtrim(_dims, 2), ', '), $
                         format='(%"wrong dims for data: [%s]")')
      error_list->add, error_msg
      is_valid = 0B
      break
    endif
  endfor

  return, is_valid
end


;+
; Validate a FITS file against the specification.
;
; :Returns:
;   1 if valid, 0 if not
;
; :Params:
;   filename : in, required, type=string
;     FITS file to validate
;   validation_spec : in, required, type=string
;     filename of specification of FITS keyword format
;
; :Keywords:
;   error_msg : out, optional, type=string
;     set to a named variable to retrieve the problem with the file (at least
;     the first problem encountered), empty string if no problem
;-
function kcor_validate_file, filename, validation_spec_filename, $
                             error_msg=error_msg, run=run
  compile_opt strictarr

  error_list = list()
  is_valid = 1B

  catch, error
  if (error ne 0L) then begin
    catch, /cancel
    error_list->add, !error_state.msg
    is_valid = 0B
    goto, done
  endif

  if (~file_test(filename, /regular)) then begin
    error_list->add, 'file does not exist'
    is_valid = 0B
    goto, done
  endif

  unzipped_size = kcor_zipsize(filename, run=run, logger_name=logger_name)
  kcor_raw_size = run->epoch('raw_filesize')   ; bytes
  if (unzipped_size ne kcor_raw_size) then begin
    error_list->add, string(unzipped_size, kcor_raw_size, $
                            format='(%"bad raw file size: %d bytes (should be: %d bytes)")')
    is_valid = 0B
    goto, done
  endif

  fits_open, filename, fcb
  fits_read, fcb, primary_data, primary_header, exten_no=0
  fits_close, fcb

  ; read spec
  spec = mg_read_config(validation_spec_filename)

  ; check primary data
  is_data_valid = kcor_validate_file_checkdata(primary_data, $
                                               'primary-data', $
                                               spec, $
                                               error_list=error_list)
  if (~is_data_valid) then is_valid = 0B

  ; check primary header against header spec
  is_header_valid = kcor_validate_file_checkheader(primary_header, $
                                                   'primary-header', $
                                                   spec, $
                                                   error_list=error_list)
  if (~is_header_valid) then is_valid = 0B

  done:

  error_msg = error_list->toArray()

  ; cleanup
  if (obj_valid(spec)) then obj_destroy, spec
  if (obj_valid(error_list)) then obj_destroy, error_list

  return, is_valid
end


; main-level example program

date = '20190331'
basename = '20190401_012502_kcor.fts.gz'

filename = filepath(basename, $
                    subdir=[date, 'level0'], $
                    root='/hao/mlsodata1/Data/KCor/raw')

spec_filename = 'kcor.l0.validation.cfg'
is_valid = kcor_validate_file(filename, spec_filename, error_msg=error_msg)
print, is_valid ? 'valid' : 'not valid', format='(%"L0 FITS file is %s")'
if (~is_valid) then begin
  print, transpose(error_msg)
endif


date = '20131016'
basename = '20131016_190704_kcor_l1.5.fts.gz'

filename = filepath(basename, $
                    subdir=[date, 'level1'], $
                    root='/hao/twilight/Data/KCor/raw.latest')

validation_spec = 'kcor.l15.validation.cfg'
is_valid = kcor_validate_file(filename, validation_spec, error_msg=error_msg)
print, is_valid ? 'valid' : 'not valid', format='(%"L1.5 FITS file is %s")'
if (~is_valid) then begin
  print, transpose(error_msg)
endif

end
