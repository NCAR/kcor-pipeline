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

# ------------------------------------------------------------------------------
#--- DB name
#--- DB host
#--- DB user
#--- DB password

# Warn user of database drop
print "WARNING!!!! This script will drop the table kcor_img!\nDo you wish to continue? ";
print "Press <Enter> to continue, or 'q' to quit: ";
my $input = <STDIN>;
exit if $input eq "q\n";

# Check the arguments for existence of config file
if ($#ARGV != 0 ) {
    print "Usage: $0 <ConfigFile>\n";
    exit;
}

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

$command = "CREATE TABLE kcor_img_test
  (
  img_id     INT (10) AUTO_INCREMENT PRIMARY KEY,
  file_name  VARCHAR (40) NOT NULL, 
  date_obs   DATETIME NOT NULL, 
  date_end   DATETIME NOT NULL, 
  instrument VARCHAR (24) NOT NULL, 
  level      VARCHAR (2) NOT NULL, 
  quality    VARCHAR (8),
  numsum     SMALLINT (4), 
  exptime    FLOAT (7, 4)  
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
