#!/usr/bin/perl -w

use DBI;
# ------------------------------------------------------------------------------
# kcor_create_mission_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_mission (mysql).
# ------------------------------------------------------------------------------
# Andrew Stanger   MLSO/HAO/NCAR   08 Dec 2015
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

$command = "DROP TABLE kcor_mission IF EXISTS" ;
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
  platescale FLOAT (6, 3),
  fov_min    FLOAT (4, 2),
  fov_max    FLOAT (4, 2),
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

#----------------------------------------
# Terminate connection to mysql database.
#----------------------------------------
$dbh->disconnect ;
