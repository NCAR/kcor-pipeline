# Release notes

1.0.0 [May 12, 2017]
  initial release
1.0.1 [May 12, 2017]
  default to production config file
  ssh_key config file option
  look for mlso_sgs_insert files in level0/ directory
1.0.2 [May 12, 2017]
  typo in ssh_key usage
1.0.3 [May 12, 2017]
  send relative paths to MLSO_SGS_INSERT
1.0.4 [May 12, 2017]
  raw files are not zipped when dealt with my MLSO_SGS_INSERT
1.1.0
  fix horizontal artifacts in raw files
  better transmission value for opal
  add options for end-of-day actions
1.1.1 [May 16, 2017]
  typo in end-of-day processing
1.2.0 [May 24, 2017]
  camera correction
  turn off horizontal correction for epoch starting 20170522
1.2.1 [May 31, 2017]
  fix for horizontal correction not being applied
  better headers
  better email notications
1.2.2 [Jun 1, 2017]
  typo in end-of-day
1.2.3 [Jun 1, 2017]
  typo in end-of-day
1.2.4 [Jun 2, 2017]
  remove inventory files on reprocessing
  fix for errors listed in email notifications
1.3.0 [Jun 2, 2017]
  after 20121204, use pipeline created calibraton files
  use new distortion file for 20150619 and later
  add totalpB to science database table
1.3.1 [Jun 5, 2017]
  fix for distributing NRGF FITS files
  handle bad occulter IDs in FITS headers better
1.3.2 [Jun 6, 2017]
  full format for totalpB in kcor_sci
1.3.3 [Jun 6, 2017]
  find occulter correctly in NRGF routine
1.3.4 [Jun 6, 2017]
  typo in KCOR_L1 date_dp
1.3.5 [Jun 14, 2017]
  add bias in camera correction
1.4.0 [Jun 28, 2017]
  remove bias to camera correction
  added main kcor script
  add gamma correction for GIFs
  doesn't unzip compress FTS files
  configurable sky polarization correction
1.4.1
  normalize dates in FITS headers to correct for invalid values
  skip first image of the day
1.4.2 [Oct 6, 2017]
  change date that display values changed in 2017
1.4.3
  daily animations of L1/NRGF full/cropped GIFs
  options to do reprocessing vs. updating
1.4.4 [Oct 26, 2017]
  fix for daily animations for observing days across UT midnight
  better interface for kcor script
1.4.5 [[Oct 26, 2017]
  fix for kcor script installation
1.4.6 [Oct 26, 2017]
  fix for trying to change permissions of files not owned
1.4.7 [Oct 30, 2017]
  fix for redundant obs day identifiers in database
1.4.8 [Oct 31, 2017]
  verify script
1.4.9 [Nov 14, 2017]
  more checks for t1.log correctness
  don't create L0 tgz if reprocessing
1.4.10 [Nov 15, 2017]
  remove camera correction config option, corrects when we have corrections
1.4.11 [Nov 15, 2017]
  bug fix
1.4.12 [Jan 5, 2018]
  updated kcor program to produce only calibration (default or from a list of files)
  add kcorcat program
  add kcorlog program
  correct for DIMV
  option for using only a single camera
1.4.13 [Jan 19, 2018]
  rotate logs when reprocessing
  enforce calibration files all have same LYOTSTOP value
  new cal epoch
1.4.14 [Jan 20, 2018]
  bug fix
1.4.15 [Jan 31, 2018]
  log camera correction filename
  run at MLSO, i.e., zip FTS files in raw directory if present
  check machine log against t1.log in verification
  new cal epoch
1.4.16 [Jan 31, 2018]
  bug fix
1.4.17 [Jan 31, 2018
  bug fix
1.4.18 [Feb 9, 2018]
  fix for handling NaN SGS values (specifically for SGSLOOP)
1.4.19 [Feb 9, 2018]
  more fixes for handling NaN SGS values
1.4.20 [Feb 10, 2018]
  fix to handle new L1 GIF names
1.4.21 [Feb 12, 2018]
  fix to distribute new L1 GIF names
1.4.22 [Feb 15, 2018]
  fix for quality check for cloudy images
1.4.23 [Feb 15, 2018]
  making average FITS/GIFs and daily average (but not distributing)
1.4.24 [Mar 5, 2018]
  more verification constants in config file
  distribute average/daily average FITS/GIFs
  redo NRGF files in end-of-day processing using averages
  create daily NRGF file from daily average
  update kcor_sw table
1.4.25 [Mar 5, 2018]
  fixes for filenames of daily average NRGF files
  fix for mlso_numfiles entry for daily average file
