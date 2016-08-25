#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_cal_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_cal (mysql).
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

#----------------------------------------
# Terminate connection to mysql database.
#----------------------------------------
$dbh->disconnect ;
