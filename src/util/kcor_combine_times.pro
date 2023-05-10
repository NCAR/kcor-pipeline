; docformat = 'rst'

function kcor_combine_times, times
  compile_opt strictarr

  time_indices = where(times ne '', count)
  if (count eq 0L) then return, '' else begin
    return, strjoin(times[time_indices], ', ')
  endelse
end
