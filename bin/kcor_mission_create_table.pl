#!/usr/bin/perl -w

use DBI;
# ------------------------------------------------------------------------------
# kcor_create_mission_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_mission (mysql).
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
print "WARNING!!!! This script will drop the table kcor_mission!\nDo you wish to continue? ";
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
# Create new kcor_mission table.
#-------------------------------

$command = "DROP TABLE IF EXISTS kcor_mission" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

# Define fields
$command = "CREATE TABLE kcor_mission (
  mission_id      INT (10) AUTO_INCREMENT PRIMARY KEY, 
  date            DATETIME NOT NULL, 
  mlso_url        CHAR (24),
  doi_url         CHAR (48),
  telescope       CHAR (24),
  instrument      CHAR (24),
  location        CHAR (27),
  origin          CHAR (12),
  object          CHAR (32),
  wavelength      FLOAT (7, 2),
  waveunit        CHAR(2),
  wavefwhm        FLOAT (5, 2),
  cdelt           FLOAT (7, 3),
  fov_min         FLOAT (4, 2),
  fov_max         FLOAT (4, 2),
  bitpix          TINYINT (3),
  xdim            SMALLINT (5),
  ydim            SMALLINT (5),
  wcsname         CHAR (26),
  ctype           CHAR (8),
  timesys         CHAR (3),
  inst_rot        FLOAT (7, 2),
  cam0_modstate1  CHAR (10),
  cam0_modstate2  CHAR (10),
  cam0_modstate3  CHAR (10),
  cam0_modstate4  CHAR (10),
  cam1_modstate1  CHAR (10),
  cam1_modstate2  CHAR (10),
  cam1_modstate3  CHAR (10),
  cam1_modstate4  CHAR (10),
  pc1_1           FLOAT (7, 3),
  pc1_2           FLOAT (7, 3),
  pc2_1           FLOAT (7, 3),
  pc2_2           FLOAT (7, 3),
  UNIQUE (date)
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
