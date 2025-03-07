#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_sci_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_sci (mysql).
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
print "WARNING!!!! This script will drop the table kcor_sci!\nDo you wish to continue? ";
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
# Create new kcor_sci table.
#-------------------------------

$command = "DROP TABLE IF EXISTS kcor_sci" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

$command = "CREATE TABLE kcor_sci (
  sci_id              INT (10) AUTO_INCREMENT PRIMARY KEY,
  file_name           CHAR (40) NOT NULL,
  date_obs            DATETIME NOT NULL,
  obs_day             MEDIUMINT (5) NOT NULL,
  level               TINYINT (2) NOT NULL,
  totalpB             FLOAT (23, 9),
  intensity           BLOB,
  intensity_stddev    BLOB,

  r111                BLOB,
  r115                BLOB,
  r12                 BLOB,
  r135                BLOB,
  r15                 BLOB,
  r175                BLOB,
  r20                 BLOB,
  r225                BLOB,
  r25                 BLOB,

  enhanced_r111       BLOB,
  enhanced_r115       BLOB,
  enhanced_r12        BLOB,
  enhanced_r135       BLOB,
  enhanced_r15        BLOB,
  enhanced_r175       BLOB,
  enhanced_r20        BLOB,
  enhanced_r225       BLOB,
  enhanced_r25        BLOB,

  FOREIGN KEY (obs_day) REFERENCES mlso_numfiles(day_id),
  FOREIGN KEY (level) REFERENCES kcor_level(level_id)
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
