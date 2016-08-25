#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_dp_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_dp (mysql).
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

#----------------------------------------
# Terminate connection to mysql database.
#----------------------------------------
$dbh->disconnect ;
