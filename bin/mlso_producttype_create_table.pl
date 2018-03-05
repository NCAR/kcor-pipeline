#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# mlso_producttype_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: mlso_producttype (mysql).
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
print "WARNING!!!! This script will drop the table mlso_producttype!\nDo you wish to continue? ";
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
# Create new mlso_producttype table.
#-------------------------------

$command = "DROP TABLE IF EXISTS mlso_producttype" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

# Define fields
$command = "CREATE TABLE mlso_producttype
  (
  producttype_id              TINYINT (2) AUTO_INCREMENT PRIMARY KEY,
  producttype                 VARCHAR (32),
  description                 VARCHAR (512)
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
$command = "INSERT INTO mlso_producttype (producttype, description) VALUES ('pB', 'K-Cor level 1 polarization brightness image')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO mlso_producttype (producttype, description) VALUES ('nrgf', 'K-Cor level 1 image with a normalized radially graded filter (nrgf, Morgan et al. 2009, adapted by Silvano Fineschi and Sarah Gibson for KCor use) to maximize image contrast.')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO mlso_producttype (producttype, description) VALUES ('unknown', 'Value entered was not in this table; Check for error.')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO mlso_producttype (producttype, description) VALUES ('nrgfavg', 'K-Cor level 1 averaged images with a normalized radially graded filter (nrgf, Morgan et al. 2009, adapted by Silvano Fineschi and Sarah Gibson for KCor use) to maximize image contrast.')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO mlso_producttype (producttype, description) VALUES ('pbavg', 'Averaged K-Cor level 1 polarized brightness images')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO mlso_producttype (producttype, description) VALUES ('pbdailyavg', 'Daily averaged K-Cor level 1 polarized brightness images')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

$command = "INSERT INTO mlso_producttype (producttype, description) VALUES ('nrgfdailyavg', 'Daily averaged K-Cor level 1 NRGF images')";
$sth = $dbh->prepare ($command) ;
$sth->execute () ;

#----------------------------------------
# Terminate connection to mysql database.
#----------------------------------------
$dbh->disconnect ;
