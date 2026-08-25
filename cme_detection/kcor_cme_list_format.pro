; docformat = 'rst'

;+
; This is the format of the CMEs written in the .all and .retracted lists. It
; needs to be followed by the insertions in .toetract as well, though spacing
; and number of decimal places can vary.
;-
function kcor_cme_list_format
  compile_opt strictarr

  return, '%s  %0.2f deg'
end
