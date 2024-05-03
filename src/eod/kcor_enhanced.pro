; docformat = 'rst'

;+
; Create an enhanced image, i.e., an unsharp mask, with the given parameters.
;
; For example::
;
;   enhanced_im = kcor_enhanced(im, $
;                               radius=run->epoch('enhanced_radius'), $
;                               amount=run->epoch('enhanced_amount'))
;
; :Params:
;   im : in, required, type="fltarr(nx, ny)"
;     image to enhance
;
; :Keywords:
;   radius : in, optional, type=float, default=5.0
;     `radius` parameter to `UNSHARP_MASK`
;   amount : in, optional, type=float, default=3.0
;     `amount` parameter to `UNSHARP_MASK`
;-
function kcor_enhanced, im, radius=radius, amount=amount
  compile_opt strictarr

  return, unsharp_mask(im, $
                       radius=n_elements(radius) eq 0L ? 5.0 : radius, $
                       amount=n_elements(amount) eq 0L ? 3.0 : amount)
end
