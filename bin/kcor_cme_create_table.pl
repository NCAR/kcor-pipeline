#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_cme_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_cme (mysql).
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
print "WARNING!!!! This script will drop the table kcor_cme!\nDo you wish to continue? ";
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
# Create new kcor_cme table.
#-------------------------------

$command = "DROP TABLE IF EXISTS kcor_cme_features" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

$command = "DROP TABLE IF EXISTS kcor_cme_alert" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

$command = "DROP TABLE IF EXISTS kcor_cme" ;
$sth     = $dbh->prepare ($command) ;

$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

$command = "create table kcor_cme (
  cme_id                int(10) auto_increment primary key,
  obs_day               mediumint (5) not null,
  dt_created            timestamp default current_timestamp,
)

$sth = $dbh->prepare ($command) ;
$sth->execute () ;
if (! $sth)
  {
  print "$command\n" ;
  print "mysql error: $dbh->errstr\n" ;
  die () ;
  }

$command = "create table kcor_cme_alert (
  cme_alert_id          int(10) auto_increment primary key,
  obs_day               mediumint (5) not null,
  dt_created            timestamp default current_timestamp,

  cme_id                int(10),

  alert_type            enum('initial', 'observer', 'retraction', 'summary', 'analyst'),
  event_type            text,
  cme_type              enum('possible cme', 'cme', 'jet', 'epl', 'outflow'),
  retracted             boolean,

  issue_time            datetime,  -- analyst alerts from event log don't have issue time
  last_data_time        datetime,
  start_time            datetime not null,
  end_time              datetime,
  in_progress           boolean,

  position_angle        float,
  speed                 float,
  height                float,
  time_for_height       datetime,

  -- for observer and retraction alerts only
  comment               text,
  confidence_level      enum('low', 'medium', 'high'),

  -- for summary reports only
  time_history          blob,
  pa_history            blob,
  speed_history         blob,
  height_history        blob,

  kcor_sw_id            int(10),

  foreign key (cme_id) references kcor_cme(cme_id),
  foreign key (kcor_sw_id) references kcor_sw(sw_id),
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

$command = "create table kcor_cme_features (
  cme_feature_id        int(10) auto_increment primary key,

  cme_alert_id          int(10),
  indices               blob,

  -- from a fit for the feature
  feature_speed         blob,
  feature_acceleration  blob,
  feature_width         blob,

  final_height          float,
  final_speed           float,
  final_accelation      float,

  foreign key (cme_alert_id) references kcor_cme_alert(cme_alert_id)
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
