; docformat = 'rst'

function kcor_validate_l0_file_checkspec, keyword_name, specline, $
                                          keyword_value, n_found, $
                                          error_list=error_list
  compile_opt strictarr

  required = 0B
  type     = 0L
  value    = !null
  values   = !null

  is_valid = 1B

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
      error_list->add, string(keyword_name, format='(%"%s: no value")')
      is_valid = 0B
    endif else begin
      if (keyword_value ne value) then begin
        error_msg = string(keyword_name, keyword_value, $
                           format='(%"%s: wrong value: %s")')
        error_list->add, error_msg
        is_valid = 0B
      endif
    endelse
  endif

  if (n_elements(values) gt 0L) then begin
    ind = where(keyword_value eq values, count)
    if (count ne 1L) then begin
      error_msg = string(keyword_value, format='(%"not one of possible values: %s")')
      error_list->add, error_msg
      is_valid = 0B
    endif
  endif

  return, is_valid
end


function kcor_validate_l0_file_checkheader, header, type, spec, $
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
    is_valid_keyword = kcor_validate_l0_file_checkspec(spec_keywords[k], $
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


function kcor_validate_l0_file_checkdata, data, $
                                          type=type, $
                                          n_dimensions=n_dimensions, $
                                          dimensions=dimensions, $
                                          error_list=error_list
  compile_opt strictarr

  is_valid = 1B

  _type = size(data, /type)
  if (_type ne type) then begin
    error_msg = string(_type, format='(%"wrong type for data: %d")')
    error_list->add, error_msg
    is_valid = 0B
  endif

  _n_dims = size(data, /n_dimensions)
  if (_n_dims ne n_dimensions) then begin
    error_msg = string(_n_dims, format='(%"wrong number of dims for data: %d")')
    error_list->add, error_msg
    is_valid = 0B
  endif

  if (_n_dims ne 0L) then begin
    _dims = size(data, /dimensions)
    if (~array_equal(_dims, dimensions)) then begin
      error_msg = string(strjoin(strtrim(_dims, 2), ', '), $
                         format='(%"wrong dims for data: [%s]")')
      error_list->add, error_msg
      is_valid = 0B
    endif
  endif

  return, is_valid
end


;+
; Validate an L0 file against the specification.
;
; :Returns:
;   1 if valid, 0 if not
;
; :Params:
;   filename : in, required, type=string
;     L0 file to validate
;   validation_spec : in, required, type=string
;     filename of specification of L0 keyword format
;
; :Keywords:
;   error_msg : out, optional, type=string
;     set to a named variable to retrieve the problem with the file (at least
;     the first problem encountered), empty string if no problem
;-
function kcor_validate_l0_file, filename, validation_spec, $
                                error_msg=error_msg
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

  fits_open, filename, fcb
  fits_read, fcb, primary_data, primary_header, exten_no=0
  fits_close, fcb

  ; check primary data
  is_data_valid = kcor_validate_l0_file_checkdata(primary_data, $
                                                  type=12, $
                                                  n_dimensions=4, $
                                                  dimensions=[1024, 1024, 4, 2], $
                                                  error_list=error_list)
  if (~is_data_valid) then is_valid = 0B

  ; read spec
  l0_header_spec = mg_read_config(validation_spec)

  ; check primary header against header spec
  is_header_valid = kcor_validate_l0_file_checkheader(primary_header, $
                                                      'primary', $
                                                      l0_header_spec, $
                                                      error_list=error_list)
  if (~is_header_valid) then is_valid = 0B

  done:

  error_msg = error_list->toArray()

  ; cleanup
  if (obj_valid(l0_header_spec)) then obj_destroy, l0_header_spec
  if (obj_valid(error_list)) then obj_destroy, error_list

  return, is_valid
end


; main-level example program

date = '20190227'
basename = '20190228_015841_kcor.fts.gz'
;date = '20181201'
;basename = '20181201_230127_kcor.fts.gz'

filename = filepath(basename, $
                    subdir=[date, 'level0'], $
                    root='/hao/mlsodata1/Data/KCor/raw')
;                    root='/hao/sunrise/Data/KCor/raw/2018')

validation_spec = 'kcor.l0.validation.cfg'
is_valid = kcor_validate_l0_file(filename, validation_spec, error_msg=error_msg)
print, is_valid ? 'Valid' : 'Not valid'
if (~is_valid) then begin
  print, transpose(error_msg)
endif

end
