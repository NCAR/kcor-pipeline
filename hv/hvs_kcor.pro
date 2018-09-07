;
;+
; :Description: setup file for writing out K-Cor JPEG2000 files.
;
; :Author:
;   Jack Ireland [JI]
;
; :History
;   18 Jun 2018 initial description of parameters required.
;
; : Notes
; Function which defines the KCOR JP2 encoding parameters for each type
; of measurement
;
; Minimum required Helioviewer Setup (HVS) structure tags.
;
; Let us assume there is a device commonly known by its "nickname",
; but is actually a "detector" which is part of an "instrument" on a
; space or ground based "observatory".  There are "N" different
; measurements possible from the device.  The tags below are the
; minimum required.
;
; a = {observatory: 'AAA',$
;      instrument: 'BBB',$
;      detector: 'CCC',$
;      nickname: 'DDD',$
;      hvs_details_filename: 'XXX',$
;      hvs_details_filename_version: 'Y.Z',$
;      details(N)}
;
; For each of the N measurements, there is a details structure.  The
; structure of the details structure is identical for every
; measurement, but the values can be different for each
; measurement. The tags below are the minimum required.
;
;
; details = {measurement: 'EEE',$
;            n_levels: F,$
;            n_laters: G,$
;            idl_bitdepth: H,$
;            bit_rate: [I,J]}
;
;-

FUNCTION HVS_KCOR
;
; Each measurement requires some details to control the creation of
; JP2 files
;
  d = {measurement: "", n_levels: 8, n_layers: 8, idl_bitdepth: 8, bit_rate: [8.0,0.01]}
;
; In this case, each LASCO-C3 measurement requires the same type of details
;
  a = replicate( d , 1 )
;
; Full description
;
  b = {details:a,$  ; REQUIRED
       observatory:'MLSO',$ ; REQUIRED
       instrument:'MLSO',$ ; REQUIRED
       detector:'KCOR',$ ; REQUIRED
       nickname:'KCOR',$ ; REQUIRED
       hvs_details_filename:'hvs_kcor',$ ; REQUIRED
       hvs_details_filename_version:'1.0',$ ; REQUIRED
       rocc_inner:1.05,$                    ; in solar radii
       rocc_outer:3.0}                       ; in solar radii

;
; white-light
;
  b.details[0].measurement = 'white-light'; REQUIRED
  b.details[0].n_levels = 8 ; REQUIRED
  b.details[0].n_layers = 8 ; REQUIRED
  b.details[0].idl_bitdepth = 8 ; REQUIRED
  b.details[0].bit_rate = [8.0,0.01] ; REQUIRED

  return,b
end 
