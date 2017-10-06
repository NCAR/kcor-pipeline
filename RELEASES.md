# Release notes

1.0.0 initial release
1.0.1 minor fixes
  default to production config file
  ssh_key config file option
  look for mlso_sgs_insert files in level0/ directory
1.0.2 minor fix
  typo in ssh_key usage
1.0.3 minor fix
  send relative paths to MLSO_SGS_INSERT
1.0.4 minor fix
  raw files are not zipped when dealt with my MLSO_SGS_INSERT
1.1.0
  fix horizontal artifacts in raw files
  better transmission value for opal
  add options for end-of-day actions
1.1.1 minor fix
  typo in end-of-day processing
1.2.0 camera correction
  turn off horizontal correction for epoch starting 20170522
1.2.1 several fixes
  fix for horizontal correction not being applied
  better headers
  better email notications
1.2.2 minor fix
  typo in end-of-day
1.2.3 minor fix
  typo in end-of-day
1.2.4 minor fixes
  remove inventory files on reprocessing
  fix for errors listed in email notifications
1.3.0 several features
  after 20121204, use pipeline created calibraton files
  use new distortion file for 20150619 and later
  add totalpB to science database table
1.3.1 minor fixes
  fix for distributing NRGF FITS files
  handle bad occulter IDs in FITS headers better
1.3.2 minor fix
  full format for totalpB in kcor_sci
1.3.3 minor fix
  find occulter correctly in NRGF routine
1.3.4 minor fix
  typo in KCOR_L1 date_dp
1.3.5
  add bias in camera correction
1.4.0
  remove bias to camera correction
  added main kcor script
  add gamma correction for GIFs
  doesn't unzip compress FTS files
  configurable sky polarization correction
1.4.1
  normalize dates in FITS headers to correct for invalid values
  skip first image of the day
1.4.2
  change date that display values changed in 2017
