#!/usr/bin/perl

# knownhosts.pl
#
# maintain the /etc/ssh/ssh_known_hosts file by scanning hosts for
# keys and adding entries to the file.
#
# author:
# Byron F. Martin <https://www.bfmartin.ca/contact/>
#
# tested on:
# - perl 5.30 on Linux Mint 20.2 (and previous versions)
# - perl 5.32 on OpenBSD 7.0 (and previous versions)

use 5.004;
use strict;
use warnings;
use autodie;
use Carp;
use English qw(-no_match_vars);
use Getopt::Long;
use utf8;                            # Source code is UTF-8
use open ':std', ':encoding(UTF-8)'; # STDIN,STDOUT,STDERR are UTF-8.

# args:
# - hostname to scan
# - optional string containing results to return. empty string if not testing
# - the command to use for scanning keys
# - other options to supply to the scan command
#
# returns:
# - an array of strings
sub scan_keys {
  my ($host, $scanout, $scancmd, $scanopts) = @_;

  if ($scanout eq '') {
    # run keyscan
    return qx($scancmd $scanopts $host 2>/dev/null);
  } else {
    # testing mode. read the supplied filename and return an array
    open my $handle, '<', $scanout or croak "cant open file $scanout: $ERRNO";
    my @lines = <$handle>;
    close $handle or croak "cant close scan.txt: $ERRNO";
    return @lines;
  }
}


# args
# - the hostname given to ssh-keyscan (from the command line)
# - name of knownhosts file
# - an array of aliases for the hostname (from the command line)
# - an array of results from ssh-keyscan
#
# returns nothing
sub compare_known_hosts {
  my ($host, $file, $aliases, $scankeys) = @_;
  my @aliases = @{$aliases};
  my @scankeys = @{$scankeys};

  open my $handle, '<', $file or croak "cant open knownhosts file $file: $ERRNO";
  my @lines = <$handle>;
  close $handle or croak "cant close $file: $ERRNO";
  my $changed = 0;

  # loop for each key returned by ssh-keyscan
  foreach my $key (@scankeys) {
    my %pkey = split_line($key);
    my $idx = match_host_type($key, $host, @lines);
    if ($idx > -1) {
      my %pline = split_line($lines[$idx]);

      # skip if key matches and aliases match
      next if $pkey{'key'} eq $pline{'key'} and
	  join("-", sort @{$pline{'aliases'}}) eq join("-", sort @aliases);

      splice @lines, $idx, 1; # remove old line
      push @lines, unsplit_line($key, $host, @aliases);
      $changed = 1;
    } else {
      push @lines, unsplit_line($key, $host, @aliases);
      $changed = 1;
    }
  }

  return if $changed == 0;
  write_knownhosts_file($file, @lines);
  return 0;
}


# removes a host for any type of key from the knownhosts file. the
# supplied hostname can be the hostname in the knownhosts file, or an
# alias of the hostname.
#
# args:
# - the hostname to remove
# - name of knownhosts file
#
# returns nothing
sub remove_host {
  my ($host, $file) = @_;

  open my $handle, '<', $file or croak "cant open knownhosts file $file: $ERRNO";
  my @lines = <$handle>;
  close $handle or croak "cant close $file: $ERRNO";

  my @new = grep { comparehost($_, $host) } @lines;

  if ($#new != $#lines) {
    write_knownhosts_file($file, @new);
  }
  return;
}


# does the hostname match the hostname or an alias from a line of the
# knownhosts file?
#
# args:
# - a line from the knownhosts file
# - the hostname to match
#
# returns true or false.
#
# NOTE that the return value is backward from what you probably
# expect. it returns true if the hostname is not found, and false if
# the hostname is found. this is because of the logic of the 'grep'
# command above.
sub comparehost {
  my ($line, $host) = @_;
  my %line = split_line($line);

  return 0 if (grep { /^$host$/ } @{$line{'aliases'}}) || ($host eq $line{'host'});
  # return undef if (grep(/^$host$/, @{$line{'aliases'}}) || ($host eq $line{'host'}));
  return 1; # not found
}


# looks for hostname and encryption type and matches against
# the contents of the ssh_known_hosts file
#
# args:
# - line from ssh-keyscan
# - hostname that was scanned
# - array of lines from knownhosts
#
# returns
# - int index to the match, or -1 if no match found
sub match_host_type {
  my ($scanline, $host, @newkeys) = @_;
  my %pscn = split_line($scanline);

  my $idx = -1;
  foreach my $key (@newkeys) {
    $idx++;
    my %pkey = split_line($key);
    next unless $pscn{'type'} eq $pkey{'type'} && $pscn{'host'} eq $pkey{'host'};
    return $idx;
  }
  return -1; # not found
}


# parses a line from knownhosts or ssh-keyscan and returns a hash with
# these keys:
# - host     host name
# - aliases  array of aliases
# - type     encryption type
# - key      public key for host
#
# args:
# - the line to parse
#
# returns:
# - hash containing parsed line
sub split_line {
  my $line = shift;

  my @i = split /\ +/msx, $line;
  my @k = split /,/msx, $i[0];
  my @aliases = @k[1 .. $#k];
  return (host => $k[0], aliases => \@aliases, type => $i[1], key => $i[2]);
}


# given a line from either ssh-keyscan or knownhosts, replace the host
# with the supplied hostname and aliases
# args:
# - line from knownhosts or ssh-keyscan
# - hostname
# - array of aliases
#
# returns
# - the line to enter into the ssh_known_hosts file
sub unsplit_line {
  my ($line, $host, @aliases) = @_;
  my %pline = split_line($line);
  return join q{ }, join(q{,}, ($host, @aliases)), $pline{'type'},
    $pline{'key'};
}


# write an array of lines to the knownhosts file
#
# args:
# - the filename
# - an array of strings
#
# returns nothing
sub write_knownhosts_file {
  my ($file, @lines) = @_;

  print "writing to $file\n";
  open my $hdle, '>', $file or croak "cant open $file for writing: $ERRNO";
  print {$hdle} @lines or croak "cant print to $file: $ERRNO";
  close $hdle or croak "can't close $file: $ERRNO";
  return;
}


### start

my $file = '/etc/ssh/ssh_known_hosts';
my $scancmd = 'ssh-keyscan';
my $scanout = '';
my $scanopts = '';
my $removehost = 0;
my $usage = <<'TEXT';
usage: knownhosts.pl [-h] [-f FILE] [-S SCANFILE] [-o OPTS] [-c COMMAND] [-r]
                     host [aliases [aliases ...]]

A command to maintain the ssh_known_hosts file.

positional arguments:
  host                  the hostname to scan
  aliases               aliases for host

optional arguments:
  -h, --help            show this help message and exit
  -f FILE, --file FILE  the ssh_known_hosts file to edit. default:
                        /etc/ssh/ssh_known_hosts
  -S SCANFILE, --SCANFILE SCANFILE
                        instead of scanning the host with ssh-keyscan, use the
                        contents of this file. useful for testing.
  -o OPTS, --opts OPTS  supply this string as options to the ssh-keyscan
                        program
  -c COMMAND, --command COMMAND
                        use this command to scan for keys. default: ssh-
                        keyscan
  -r, --remove          remove all entries/keytypes of this host from the
                        ssh_known_hosts file. if remove is selected, only the
                        first hostname is processed. other args are ignored.

Examples of useful options (--opts) to pass to the ssh-keyscan program are:
port number and encryption type
TEXT

my $help = 0;
GetOptions('help|?' => \$help,
           'file=s' => \$file,
           'SCANFILE=s' => \$scanout,
           'opts=s' => \$scanopts,
           'command=s' => \$scancmd,
           'remove' => \$removehost
    ) or croak $usage;

croak $usage if $help;
croak $usage if $#ARGV < 0;

# get info from command line
my $host = shift;
my @aliases = @ARGV;

# create file if it doesn't exist
if (! -f $file) {
  open my $handle, '>', $file or croak "Error creating $file: $ERRNO";
  close $handle or croak "Error closing $file: $ERRNO";
}

if ($removehost) {
  remove_host($host, $file);
} else {
  my @newkeys = scan_keys($host, $scanout, $scancmd, $scanopts);
  compare_known_hosts($host, $file, \@aliases, \@newkeys);
}

### end
