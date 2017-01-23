#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_hw_create_table.pro
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_hw (mysql).
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
print "WARNING!!!! This script will drop the table kcor_hw!\nDo you wish to continue? ";
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

#-----------------------------
# Create new kcor_hw table.
#-----------------------------

$command = "DROP TABLE IF EXISTS kcor_hw_test" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

# Define fields
$command = "CREATE TABLE kcor_hw_test 
  (
  hw_id    INT (10) AUTO_INCREMENT PRIMARY KEY,
  date      	DATETIME NOT NULL,
  diffsrid  	CHAR (8),
  bopal			FLOAT (11, 7),
  rcamid    	CHAR (18),
  tcamid    	CHAR (18),
  rcamlut   	CHAR (14),
  tcamlut   	CHAR (14),
  modltrid  	CHAR (1),
  o1id      	CHAR (14),
  occltrid  	CHAR (10),
  filterid  	CHAR (12),
  calpolid		CHAR (12)
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
