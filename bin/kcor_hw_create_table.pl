#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_hw_create_table.pro
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_hw (mysql).
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
