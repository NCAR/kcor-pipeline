; IDL 8.6.0 (darwin x86_64 m64)
; Journal File for mscott@harvey.local
; Working directory: /Users/mscott/Desktop
; Date: Wed Nov  1 21:45:28 2017
 
files = file_search('/Users/mscott/Desktop/kcor/*.gz', count = fc)

for ii = 0, fc-1 do begin 
  f = files[ii]
  spawn, 'gunzip -f '+f
  infile = strmid(f,0,strlen(f)-3)
  tmp = str_sep(infile,'/')
  tmp = tmp[n_elements(tmp)-1]
  ofile = './kcor/out/'+strmid(tmp,0,strlen(tmp)-3)+'sav'

  if file_exist(ofile+'.gz') then goto, skip

  x = clock_angle_remove(infile)
  spawn, 'gzip -f '+infile

  window, 0, xs = 512, ys = 512, retain =2
  plot_map, x[2], /log, grid = 25, /limb, dmin =0.002, dmax = 0.5 
  write_png, './kcor/png/kcor_'+fns('####',ii)+'.png', tvrd(/true)

  save, file = ofile, x

  if ii eq 0 then begin
    aa = size(x[2].data)
    nx = aa[1]
    ny = aa[2]
    cube = fltarr(nx, ny, fc)
    times = strarr(fc)
    tjd = dblarr(fc)
  endif
  cube[*,*,ii] = x[2].data
  times[ii] = x[0].time
  tmp = anytim2jd(x[0].time)
  tjd[ii] = double(tmp.int) + tmp.frac

  spawn, 'gzip -f '+ofile
  skip:
endfor

end