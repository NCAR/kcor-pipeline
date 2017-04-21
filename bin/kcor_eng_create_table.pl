#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_eng_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_eng (mysql).
# ------------------------------------------------------------------------------
# Andrew Stanger   MLSO/HAO/NCAR   08 Dec 2015
# New edits by Don Kolinski Jan 2017
# Added new argument containing path/configfile:
#   config file format:
#   username = <value>
#   password = <value>
#   host = <value>
#   dbname = <value>
# Added/edited database fields
# ------------------------------------------------------------------------------

# Check the arguments for existence of config file
if ($#ARGV != 0 ) {
    print "Usage: $0 <ConfigFile>\n";
    exit;
}

# Warn user of database drop
print "WARNING!!!! This script will drop the table kcor_eng!\nDo you wish to continue? ";
print "Press <Enter> to continue, or 'q' to quit: ";
my $input = <STDIN>;
exit if $input eq "q\n";

# Read config file
$configfile = $ARGV[0];
open (CONFIG, "$configfile") or die "ERROR: Config file not found : $configfile";
while (<CONFIG>) {
    chomp;                  # no newline
    s/#.*//;                # no comments
    s/^\s+//;               # no leading white
    s/\s+$//;               # no trailing white
    next unless length;     # anything left?
    my ($var, $value) = split(/\s*=\s*/, $_, 2);
    $configvar{$var} = $value;
} 
$user = $configvar{"username"};
$pass = $configvar{"password"};
$host = $configvar{"host"};
$db = $configvar{"dbname"};

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

$command = "DROP TABLE IF EXISTS kcor_eng" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

# Define fields
# Notes:
# Removed sgs fields and moved them to new table, kcor_sgs
#   Added back sgsdimv and sgsdims
# Removed calpang and datatype
# kcor_sw_id is the id number of the entry in the kcor_sw table relevant to this entry
$command = "CREATE TABLE kcor_eng
  (
  eng_id    INT (10) AUTO_INCREMENT PRIMARY KEY,
  file_name   CHAR (32) NOT NULL,
  date_obs    DATETIME NOT NULL,
  obs_day   MEDIUMINT (5) NOT NULL,
  rcamfocs    FLOAT (6, 2),
  tcamfocs    FLOAT (6, 2),
  modltrt   FLOAT (6, 2),
  o1focs    FLOAT (8, 3),
  kcor_sgsdimv  FLOAT (7, 4),
  kcor_sgsdims  FLOAT (8, 5),
  level     TINYINT (2),
  bunit     VARCHAR (15),
  bzero     INT (10),
  bscale    FLOAT (5, 4),
  rcamxcen    FLOAT(9, 3),
  rcamycen    FLOAT(9, 3),
  tcamxcen    FLOAT(9, 3),
  tcamycen    FLOAT(9, 3),
  rcam_rad    FLOAT(9, 3),
  tcam_rad              FLOAT(9, 3),
  mean_phase1           FLOAT (7, 4),
  l0inthorizmeancam0    FLOAT (9, 3),
  l0inthorizmeancam1    FLOAT (9, 3),
  l0inthorizmediancam0  FLOAT (9, 3),
  l0inthorizmediancam1  FLOAT (9, 3),
  l0intazimeancam0      FLOAT (9, 3),
  l0intazimeancam1      FLOAT (9, 3),
  l0intazimediancam0    FLOAT (9, 3),
  l0intazimediancam1    FLOAT (9, 3),
  cover     CHAR (3),
  darkshut    CHAR (3),
  diffuser    CHAR (3),
  calpol    CHAR (3),
  kcor_sw_id    INT (10),
  UNIQUE (file_name),
  INDEX (date_obs),
  FOREIGN KEY (level) REFERENCES kcor_level(level_id),
  FOREIGN KEY (kcor_sw_id) REFERENCES kcor_sw(sw_id),
  FOREIGN KEY (obs_day) REFERENCES mlso_numfiles(day_id)
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
