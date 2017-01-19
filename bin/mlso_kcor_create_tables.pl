#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# Create MLSO db tables (mysql).
# ------------------------------------------------------------------------------
# Andrew Stanger   MLSO/HAO/NCAR   24 Sep 2015
# NOTE (from DJK): This script to create all KCOR table at once is now deprecated.
# 		Use the individual scripts to create each table, such as kcor_img_create_table.pl
# ------------------------------------------------------------------------------
#--- DB name
#--- DB host
#--- DB user
#--- DB password

$db   = "MLSO" ;
$host = "databases.hao.ucar.edu" ;
$user = "stanger" ;
$pass = "mml4so14" ;

#---------------------
# Connect to database.
#---------------------

$dbh = DBI->connect ("DBI:mysql:$db:$host", $user, $pass) ;

if (! $dbh)
  {
  print "DB connection failed.\n" ;
  die () ;
  }
else
  {
  print "DB connection successful.\n" ;
  }

#-------------------------------
# Create new kcor_mission table.
#-------------------------------

$command = "DROP TABLE kcor_mission" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

$command = "CREATE TABLE kcor_mission 
  (
  mission_id INT (10) AUTO_INCREMENT PRIMARY KEY, 
  date       DATETIME NOT NULL, 
  mlso_url   VARCHAR (24),
  doi_url    VARCHAR (48),
  telescope  VARCHAR (24),
  instrument VARCHAR (24),
  location   VARCHAR (12),
  origin     VARCHAR (12),
  object     VARCHAR (14),
  wavelength FLOAT (6, 1),
  wavefwhm   FLOAT (4, 1),
  resolution FLOAT (6, 3),
  fov_min    FLOAT (4, 2),
  fov_max    FLOAT (4, 2),
  bitpix     TINYINT (3),
  xdim       SMALLINT (5),
  ydim       SMALLINT (5)
  )"; 

$sth = $dbh->prepare ($command) ;
$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

#----------------------------
# Create new kcor_img table.
#----------------------------

$command = "DROP TABLE kcor_img" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

$command = "CREATE TABLE kcor_img 
  (
  img_id     INT (10) AUTO_INCREMENT PRIMARY KEY, 
  file_name  VARCHAR (40) NOT NULL, 
  date_obs   DATETIME NOT NULL, 
  date_end   DATETIME NOT NULL, 
  instrument VARCHAR (24) NOT NULL, 
  level      VARCHAR (2) NOT NULL, 
  datatype   VARCHAR (12),
  quality    VARCHAR (8),
  numsum     SMALLINT (4), 
  exptime    FLOAT (7, 4),  
  rsun       FLOAT (8, 3),
  solar_p0   FLOAT (8, 3),
  carr_lat   FLOAT (8, 3),
  carr_lon   FLOAT (8, 3),
  carr_rot   FLOAT (7, 1),
  solar_ra   FLOAT (7, 3),
  solardec   FLOAT (7, 3)
  )" ;

$sth = $dbh->prepare ($command) ;
$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

#----------------------------
# Create new kcor_cal table.
#----------------------------

$command = "DROP TABLE kcor_cal" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

$command = "CREATE TABLE kcor_cal 
  (
  img_id     INT (10) AUTO_INCREMENT PRIMARY KEY, 
  file_name  VARCHAR (40) NOT NULL, 
  date_obs   DATETIME NOT NULL, 
  date_end   DATETIME NOT NULL, 
  instrument VARCHAR (24) NOT NULL, 
  level      VARCHAR (2) NOT NULL, 
  numsum     SMALLINT (4), 
  exptime    FLOAT (7, 4),
  cover      VARCHAR (4),
  darkshut   VARCHAR (4),
  diffuser   VARCHAR (4),
  calpol     VARCHAR (4),
  calpang    FLOAT (8, 3)
  )" ;

$sth = $dbh->prepare ($command) ;
$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

#-------------------------------
# Create new kcor_eng table.
#-------------------------------

$command = "DROP TABLE kcor_eng" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

$command = "CREATE TABLE kcor_eng 
  (
  eng_id    INT (10) AUTO_INCREMENT PRIMARY KEY,
  file_name VARCHAR (32) NOT NULL,
  date      DATETIME NOT NULL,
  rcamfocs  FLOAT (6, 2),
  tcamfocs  FLOAT (6, 2),
  modltrt   FLOAT (5, 1),
  o1focs    FLOAT (8, 3),
  sgsdimv   FLOAT (7, 4),
  sgsdims   FLOAT (8, 5),
  sgssumv   FLOAT (7, 4),
  sgsrav    FLOAT (9, 6),
  sgsras    FLOAT (9, 6),
  sgsrazr   FLOAT (5, 1),
  sgsdecv   FLOAT (10, 7),
  sgsdecs   FLOAT (10, 7),
  sgsdeczr  FLOAT (5, 1),
  sgsscint  FLOAT (7, 3),
  sgssums   FLOAT (8, 5)
  )" ;

$sth = $dbh->prepare ($command) ;
$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

#-----------------------------
# Create new kcor_dp table.
#-----------------------------

$command = "DROP TABLE kcor_dp" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

$command = "CREATE TABLE kcor_dp 
  (
  dp_id     INT (10) AUTO_INCREMENT PRIMARY KEY,
  date       DATETIME NOT NULL,
  dmodswid   VARCHAR (24),
  calfile    VARCHAR (52),
  distort    VARCHAR (28),
  dpswid     VARCHAR (24),
  bunit      VARCHAR (12),
  bzero      FLOAT (4, 1),
  bscale     FLOAT (6, 3)
  )" ;

$sth = $dbh->prepare ($command) ;
$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

#-----------------------------
# Create new kcor_hw table.
#-----------------------------

$command = "DROP TABLE kcor_hw" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

$command = "CREATE TABLE kcor_hw 
  (
  hw_id    INT (10) AUTO_INCREMENT PRIMARY KEY,
  date      DATETIME NOT NULL,
  diffsrid  VARCHAR (8),
  rcamid    VARCHAR (18),
  tcamid    VARCHAR (18),
  rcamlut   VARCHAR (14),
  tcamlut   VARCHAR (14),
  modltrid  VARCHAR (1),
  o1id      VARCHAR (4),
  occltrid  VARCHAR (9),
  filterid  VARCHAR (12),
  sgsloop   TINYINT (1)
  )" ;

$sth = $dbh->prepare ($command) ;
$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

#----------------------------------------
# Terminate connection to mysql database.
#----------------------------------------
$dbh->disconnect ;
