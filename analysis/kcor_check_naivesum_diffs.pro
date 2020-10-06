; docformat = 'rst'

naivesum_root = '/hao/dawn/Data/KCor/raw.aero-naivesum/20200908/level0'
production_root = '/hao/mlsodata1/Data/KCor/raw/20200908/level0'
basename = '20200908_172438_kcor.fts.gz'
naivesum_filename = filepath(basename, root=naivesum_root)
production_filename = filepath(basename, root=production_root)

naivesum_im = readfits(naivesum_filename)
production_im = readfits(production_filename)

for s = -6, 6 do begin
  d = float(shift(naivesum_im, s, 0, 0, 0)) - float(production_im)
  mg_image, bytscl(d[*, *, 0, 0]), /new, title=s
endfor

end
