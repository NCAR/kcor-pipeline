#!/usr/bin/perl -w

use DBI;

# ------------------------------------------------------------------------------
# kcor_sw_create_table.pl
# ------------------------------------------------------------------------------
# Create MLSO db table: kcor_sw (mysql).
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
print "WARNING!!!! This script will drop the table kcor_sw!\nDo you wish to continue? ";
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

# Connect to database.
$dbh = DBI->connect ("DBI:mysql:$db:$host", $user, $pass);

if (! $dbh) {
  print "DB connection failed.\n";
  die();
} else {
  print "DB connection successful.\n";
}

# Create new kcor_dp table
$command = "DROP TABLE IF EXISTS kcor_sw";
$sth     = $dbh->prepare ($command);

$sth->execute();
if (! $sth) {
  print "$command\n";
  print "mysql error: $dbh->errstr\n";
  die();
}

# Define fields
#	Notes:
#   If a lot of queries are done, it is best to have VARCHARS at the end of
#   field list, but this table will not get a lot of queries. I left 'labviewid'
#   and 'socketcamid' as varchars due to not knowing their actual length
$command = "create table kcor_sw (
  sw_id             int(10) auto_increment primary key,
  date              datetime not null,
  proc_date         datetime not null,
  dmodswid          char(24),
  distort           char(50),
  sw_version        char(24),
  sw_revision       varchar(20),
  sky_pol_factor    float(6, 3),
  sky_bias          float(7, 4),
  bunit             varchar(12),
  bzero             float(6, 3),
  bscale            float(6, 3),
  labviewid         varchar(20),
  socketcamid       varchar(20)
)";

$sth = $dbh->prepare($command);
$sth->execute();
if (! $sth) {
  print "$command\n";
  print "mysql error: $dbh->errstr\n";
  die();
}

# Terminate connection to mysql database
$dbh->disconnect;
