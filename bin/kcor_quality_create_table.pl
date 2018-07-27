#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_quality_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_quality (mysql).
# ------------------------------------------------------------------------------
# Don Kolinski April 2017
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
print "WARNING!!!! This script will drop the table kcor_level!\nDo you wish to continue? ";
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
# Create new kcor_level table.
#-------------------------------

$command = "DROP TABLE IF EXISTS kcor_level" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

# Define fields
$command = "CREATE TABLE kcor_quality
  (
  quality_id            TINYINT (2) AUTO_INCREMENT PRIMARY KEY,
  quality               CHAR (5) NOT NULL,
  description           VARCHAR (512)
  )" ; 

$sth = $dbh->prepare ($command) ;
$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

# populate
$command = "INSERT INTO kcor_quality (quality, description) VALUES ('oka', 'OK quality images')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO kcor_quality (quality, description) VALUES ('cal', 'calibration images')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO kcor_quality (quality, description) VALUES ('dev', 'device images')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO kcor_quality (quality, description) VALUES ('brt', 'bright images')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO kcor_quality (quality, description) VALUES ('dim', 'dim images')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO kcor_quality (quality, description) VALUES ('cld', 'cloudy images')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO kcor_quality (quality, description) VALUES ('nsy', 'noisy images')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO kcor_quality (quality, description) VALUES ('sat', 'saturated images')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;


#----------------------------------------
# Terminate connection to mysql database.
#----------------------------------------
$dbh->disconnect ;
