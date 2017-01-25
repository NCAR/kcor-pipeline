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

$command = "DROP TABLE IF EXISTS kcor_img_test" ;  # TODO: remove _test when in production
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
# TODO: define other indices.
$command = "CREATE TABLE kcor_img_test
  (
  img_id		INT (10) AUTO_INCREMENT PRIMARY KEY,
  file_name		CHAR (35) NOT NULL, 
  date_obs		DATETIME NOT NULL, 
  date_end		DATETIME NOT NULL, 
  level			CHAR (4) NOT NULL,
  quality		TINYINT (2),
  numsum		SMALLINT (4), 
  exptime		FLOAT (7, 4),
  datatype		VARCHAR (8),
  filetype		VARCHAR (6),
  UNIQUE (file_name),
  INDEX (date_obs),
  INDEX (quality),
  INDEX (datatype)
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
