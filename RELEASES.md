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
  after 20121204, use pipeline created calibration files
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
1.4.26 [Mar 6, 2018]
  typo/bug in NRGF code
1.4.27 [Mar 6, 2018]
  more fixes for distribution of averages/daily averages/NRGF daily averages
1.4.28 [Mar 7, 2018]
  fix for scaling of difference GIFs
  fixes for new order of creating animations/averages and redoing NRGFs
  crash notification
  log messages
1.4.29 [Mar 8, 2018]
  make calibration respect process flag in epochs file
1.4.30 [Mar 8, 2018]
  add quality field to kcor_cal table
1.4.31 [Mar 8, 2018]
  fix for using full paths for db files
1.4.32 [Mar 9, 2018]
  fix DATE-OBS/DATE-END in averages
1.4.33 [Mar 12, 2018]
  separate automated, real-time CME detection script for production
1.4.34 [Mar 12, 2018]
  handle days which don't have an extended average
1.4.35 [Mar 13, 2018]
  fix for now creating extended average on many days
1.4.36 [Mar 14, 2018]
  handle days when the extended average time is not the same as any 2 min average
1.4.37 [Mar 14, 2018]
  bug fix in handling days when the extended average time is not the same as 2 min average
1.4.38 [Mar 14, 2018]
  bug fix in handling days when the extended average time is not the same as 2 min average
1.4.39 [Mar 26, 2018]
  new distortion
  indexing fixes for CME detection
  create missing directories in CME detection
  send CME notification from config file "from_email" address
1.4.40 [Apr 25, 2018]
  quality plot
  fixes for putting means/medians in kcor_eng table
  add kcor_hw reference to kcor_eng
  updated distortion in epochs
  epochs for changes on 20180406-20180423
  better ephemeris calculation
1.4.41 [Jun 22, 2018]
  always create quality plot
  send L1 products to HPSS
  update to IDL 8.6
  remove taking absolute value of data
  replaced KCor L1 cropped GIF with fullres BW and no gamma correction
  updated annotations on average GIFS and FITS keywords
  fixes for updating kcor_hw table
  add use_calibration_data flag for marking bad calibration data
  new epochs for bad calibration data on 201806{19,20}
1.4.42 [Jun 22, 2018]
  fix epochs file typo
1.4.43 [Jun 30, 2018]
  fix for standard/cropped mp4s (was showing NRGFs)
  make avg cropped GIFs like standard cropped GIFs
  add "North" and "2 min avg" (avg only) to cropped GIFs
  add CSV file of readings in CME report
1.4.44 [Jul 8, 2018]
  fix for sending L1 tarball to HPSS
  indicate values outside nominal range in param plots
  make extavg cropped GIFs like standard cropped GIFs
  fix for first 2 min average GIF
1.4.45 [Jul 10, 2018]
  return only one latest row for hardware/software changes
  log error messages when reading FITS files for detecting hardware changes
1.4.46
  check L1 tarball on HPSS in verification
