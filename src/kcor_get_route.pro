; docformat = 'rst'

function kcor_get_route, routing_file, date, found=found
  compile_opt strictarr

  config = mg_read_config(routing_file)
  date_specs = config->options(section='kcor', count=n_date_specs)

  for s = 0L, n_date_specs - 1L do begin
    if (strmatch(date, date_specs[s])) then begin
      route = config->get(date_specs[s], section='kcor')
      found = 1B
      return, route
    endif
  endfor

  found = 0B
  return, !null
end
