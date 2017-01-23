#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# mlso_sgs_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_sgs (mysql).
# ------------------------------------------------------------------------------
# Don Kolinski Jan 2017
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
print "WARNING!!!! This script will drop the table mlso_sgs!\nDo you wish to continue? ";
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
# Create new kcor_sgs table.
#-------------------------------

$command = "DROP TABLE IF EXISTS mlso_sgs_test" ;
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
#	Took out 'file_name'.  The data are in the K-Cor files, so we could add it back later.
#
$command = "CREATE TABLE mlso_sgs_test
  (
  sgs_id    INT (10) AUTO_INCREMENT PRIMARY KEY,
  date_obs  DATETIME NOT NULL,
  sgsdimv   FLOAT (7, 4),
  sgsdims   FLOAT (8, 5),
  sgssumv   FLOAT (7, 4),
  sgsrav    FLOAT (9, 6),
  sgsras    FLOAT (9, 6),
  sgsrazr   FLOAT (7, 2),
  sgsdecv   FLOAT (10, 7),
  sgsdecs   FLOAT (10, 7),
  sgsdeczr  FLOAT (7, 2),
  sgsscint  FLOAT (7, 3),
  sgssums   FLOAT (9, 6)
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
