PRO kcorqa_test, l0_file

;print, 'l0_file: ', l0_file

img = readfits (l0_file, hdu, /SILENT)

iq = 'unknown'
iq = kcorqa (img, hdu, l0_file, /gif, /debug)

print, 'l0_file: ', l0_file, ' iq: ', iq

END
