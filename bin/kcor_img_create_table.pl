#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_img_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_img (mysql).
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
print "WARNING!!!! This script will drop the table kcor_img!\nDo you wish to continue? ";
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
# Create new kcor_img table.
#----------------------------

$command = "DROP TABLE IF EXISTS kcor_img" ;  # TODO: remove _test when in production
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
#	Removing 'instrument' field for now (unless I hear that VSO needs it in this table)
#	'level' type changed to char(4), but could also be float(4,1) like xxx.x
#	'quality' type changed to tinyint, and will be stored as a number between 0-99
#	Added 'datatype' and 'filetype' fields at end, because VARCHAR slows down queries if there are fields after it
#	Changed field 'datatype' to 'producttype' to avoid confusion with header field (20170213 DJK)
#	Alterting data types of level, producttype, and filetype to normalize with level, producttype, and filetype mysql tables (20170213)
# TODO: define other indices.
$command = "CREATE TABLE kcor_img (
  img_id                INT (10) AUTO_INCREMENT PRIMARY KEY,
  dt_created            timestamp default current_timestamp,
  file_name             CHAR (50) NOT NULL, 
  date_obs              DATETIME NOT NULL, 
  date_end              DATETIME NOT NULL, 
  obs_day               MEDIUMINT (5) NOT NULL,
  carrington_rotation   MEDIUMINT (5),
  level                 TINYINT (2) NOT NULL,
  quality               TINYINT (2),
  producttype           TINYINT (2),
  filetype              TINYINT (2),
  numsum                SMALLINT (4), 
  exptime               FLOAT (7, 4),  
  UNIQUE (file_name),
  INDEX (date_obs),
  INDEX (obs_day),
  INDEX (quality),
  INDEX (producttype),
  FOREIGN KEY (level) REFERENCES kcor_level(level_id),
  FOREIGN KEY (producttype) REFERENCES mlso_producttype(producttype_id),
  FOREIGN KEY (filetype) REFERENCES mlso_filetype(filetype_id),
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
