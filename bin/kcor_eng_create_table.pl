#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_eng_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_eng (mysql).
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
# Create new kcor_eng table.
#-------------------------------

$command = "DROP TABLE kcor_eng IF EXISTS" ;
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

#----------------------------------------
# Terminate connection to mysql database.
#----------------------------------------
$dbh->disconnect ;
