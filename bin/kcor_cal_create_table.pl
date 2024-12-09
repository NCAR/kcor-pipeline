#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_cal_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_cal (mysql).
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
print "WARNING!!!! This script will drop the table kcor_cal!\nDo you wish to continue? ";
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
# Create new kcor_cal table.
#----------------------------

$command = "DROP TABLE IF EXISTS kcor_cal" ;
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
#	Removed 'instrument' field
#	Changed level to CHAR (4). May need as FLOAT (4.1)
#	Changed cover, darkshut, diffuser, and calpol to char (3)
$command = "create table kcor_cal (
  cal_id          int (10) auto_increment primary key, 
  file_name       char (40) not null, 
  date_obs        datetime not null, 
  date_end        datetime not null,
  obs_day         mediumint (5) not null,
  level           tinyint (2) not null, 
  quality         tinyint (2) not null,
  numsum          smallint (4), 
  exptime         float (7, 4),
  cover           char (3),
  darkshut        char (3),
  diffuser        char (3),
  calpol          char (3),
  calpang         float (8, 3),
  rcam_xcenter    float,
  rcam_ycenter    float,
  rcam_radius     float,
  rcam_dc_xcenter float,
  rcam_dc_ycenter float,
  rcam_dc_radius  float,
  tcam_xcenter    float,
  tcam_ycenter    float,
  tcam_radius     float,
  tcam_dc_xcenter float,
  tcam_dc_ycenter float,
  tcam_dc_radius  float,
  mean_int_img0   float (18, 7),
  mean_int_img1   float (18, 7),
  mean_int_img2   float (18, 7),
  mean_int_img3   float (18, 7),
  mean_int_img4   float (18, 7),
  mean_int_img5   float (18, 7),
  mean_int_img6   float (18, 7),
  mean_int_img7   float (18, 7),
  rcamid          char (18),
  tcamid          char (18),
  rcamlut         char (14),
  tcamlut         char (14),
  rcamfocs        float (7, 3),
  tcamfocs        float (7, 3),
  modltrid        char (1),
  modltrt         float (7, 2),
  occltrid        char (20),
  o1id            char (14),
  o1focs          float (8, 3),
  calpolid        char (12) not nulL,
  diffsrid        char (20),
  filterid        char (12),
  kcor_sgsdimv    float (10, 6),
  kcor_sgsdims    float (10, 6),
  unique (file_name),
  index (date_obs),
  index (obs_day),
  foreign key (level) references kcor_level(level_id),
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
