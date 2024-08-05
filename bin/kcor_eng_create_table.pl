#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_eng_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_eng (mysql).
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
# Notes:
# Removed sgs fields and moved them to new table, kcor_sgs
#   Added back sgsdimv and sgsdims
# Removed calpang and datatype
# kcor_sw_id is the id number of the entry in the kcor_sw table relevant to this entry
$command = "create table kcor_eng (
  eng_id                int(10) auto_increment primary key,
  file_name             char(40) not null,
  date_obs              datetime not null,
  obs_day               mediumint (5) not null,
  rcamfocs              float(6, 2),
  tcamfocs              float(6, 2),
  modltrt               float(6, 2),
  o1focs                float(8, 3),
  kcor_sgsdimv          float(10, 6),
  kcor_sgsdims          float(10, 6),
  level                 tinyint(2),
  bunit                 varchar(30),
  bzero                 int(10),
  bscale                float(5, 4),
  rcamxcen              float(9, 3),
  rcamycen              float(9, 3),
  tcamxcen              float(9, 3),
  tcamycen              float(9, 3),
  rcam_rad              float(9, 3),
  tcam_rad              float(9, 3),
  image_scale           float(9, 3),
  mean_phase1           float(7, 4),
  l0inthorizmeancam0    float(9, 3),
  l0inthorizmeancam1    float(9, 3),
  l0inthorizmediancam0  float(9, 3),
  l0inthorizmediancam1  float(9, 3),
  l0intazimeancam0      float(9, 3),
  l0intazimeancam1      float(9, 3),
  l0intazimediancam0    float(9, 3),
  l0intazimediancam1    float(9, 3),
  cover                 char(3),
  darkshut              char(3),
  diffuser              char(3),
  calpol                char(3),
  distort               char(75),
  labviewid             varchar(20),
  socketcamid           varchar(20),
  kcor_sw_id            int(10),
  kcor_hw_id            int(10),
  unique(file_name),
  index(date_obs),
  foreign key (level) references kcor_level(level_id),
  foreign key (kcor_sw_id) references kcor_sw(sw_id),
  foreign key (obs_day) references mlso_numfiles(day_id)
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
