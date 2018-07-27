#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_raw_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_raw (mysql).
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
$command = "create table kcor_raw(
  raw_id           INT (10) AUTO_INCREMENT PRIMARY KEY, 
  file_name        CHAR (40) NOT NULL, 
  date_obs         DATETIME NOT NULL, 
  date_end         DATETIME NOT NULL,
  obs_day          MEDIUMINT (5) NOT NULL,
  level            TINYINT (2) NOT NULL, 
  quality_id       TINYINT (2) NOT NULL,
  mean_int_img0    FLOAT (14, 7),
  mean_int_img1    FLOAT (14, 7),
  mean_int_img2    FLOAT (14, 7),
  mean_int_img3    FLOAT (14, 7),
  mean_int_img4    FLOAT (14, 7),
  mean_int_img5    FLOAT (14, 7),
  mean_int_img6    FLOAT (14, 7),
  mean_int_img7    FLOAT (14, 7),
  median_int_img0  FLOAT (14, 7),
  median_int_img1  FLOAT (14, 7),
  median_int_img2  FLOAT (14, 7),
  median_int_img3  FLOAT (14, 7),
  median_int_img4  FLOAT (14, 7),
  median_int_img5  FLOAT (14, 7),
  median_int_img6  FLOAT (14, 7),
  median_int_img7  FLOAT (14, 7),
  unique(file_name),
  index(date_obs),
  foreign key (level) references kcor_level(level_id),
  foreign key (obs_day) references mlso_numfiles(day_id)
)";

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
