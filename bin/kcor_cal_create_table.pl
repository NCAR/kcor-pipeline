#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_cal_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_cal (mysql).
# ------------------------------------------------------------------------------
# Andrew Stanger   MLSO/HAO/NCAR   08 Dec 2015
# New edits by Don Kolinski Jan 2017
#	Added new argument containing path/configfile:
#		config file format:
#		username = <value>
#		password = <value>
#		host = <value>
#		dbname = <value>
#	Added/edited database fields
# ------------------------------------------------------------------------------

# Check the arguments for existence of config file
if ($#ARGV != 0 ) {
    print "Usage: $0 <ConfigFile>\n";
    exit;
}

# Warn user of database drop
print "WARNING!!!! This script will drop the table kcor_cal!\nDo you wish to continue? ";
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

#----------------------------
# Create new kcor_cal table.
#----------------------------

$command = "DROP TABLE IF EXISTS kcor_cal_test" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

# Define fields
#	Notes:
#	Removed 'instrument' field
#	Changed level to CHAR (4). May need as FLOAT (4.1)
#	Changed cover, darkshut, diffuser, and calpol to CHAR (3)
$command = "CREATE TABLE kcor_cal_test
  (
  cal_id		INT (10) AUTO_INCREMENT PRIMARY KEY, 
  file_name		CHAR (40) NOT NULL, 
  date_obs		DATETIME NOT NULL, 
  date_end		DATETIME NOT NULL, 
  level			TINYINT (2) NOT NULL, 
  numsum		SMALLINT (4), 
  exptime		FLOAT (7, 4),
  cover			CHAR (3),
  darkshut		CHAR (3),
  diffuser		CHAR (3),
  calpol		CHAR (3),
  calpang		FLOAT (8, 3),
  mean_int_img0	FLOAT (14, 7),
  mean_int_img1	FLOAT (14, 7),
  mean_int_img2	FLOAT (14, 7),
  mean_int_img3	FLOAT (14, 7),
  mean_int_img4	FLOAT (14, 7),
  mean_int_img5	FLOAT (14, 7),
  mean_int_img6	FLOAT (14, 7),
  mean_int_img7	FLOAT (14, 7),
  rcamid		CHAR (18),
  tcamid		CHAR (18),
  rcamlut		CHAR (14),
  tcamlut		CHAR (14),
  rcamxcen		FLOAT (9, 3),
  rcamycen		FLOAT (9, 3),
  tcamxcen		FLOAT (9, 3),
  tcamycen		FLOAT (9, 3),
  rcam_rad		FLOAT (9, 3),
  tcam_rad		FLOAT (9, 3),
  rcamfocs		FLOAT (7, 3),
  tcamfocs		FLOAT (7, 3),
  modltrid		CHAR (1),
  modltrt		FLOAT(7, 2),
  occltrid		CHAR (10),
  o1id			CHAR (14),
  o1focs		FLOAT (8, 3),
  calpolid		CHAR (12) NOT NULL,
  diffsrid		CHAR (8),
  filterid		CHAR (12),
  kcor_sgsdimv	FLOAT (7, 4),
  kcor_sgsdims	FLOAT (8, 5),
  UNIQUE (file_name)  
  )" ;  # TODO: remove _test when in production

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
