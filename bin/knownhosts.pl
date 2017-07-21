#!/usr/bin/perl
# -*- coding: utf-8 -*-

# knownhosts.pl
#
# maintain the /etc/ssh/ssh_known_hosts file by scanning hosts for
# keys and adding entries to the file.
#
# author:
# Byron F. Martin <https://www.bfmartin.ca/contact/>
#
# tested on:
# - perl 5.22.1 on Linux Mint 18.1
# - perl 5.24.1 on OpenBSD 6.1
# - perl 5.22.4 on Cygwin

use strict;
use warnings;
use Carp;
use English qw(-no_match_vars);
use Getopt::Long;
use utf8;

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
    qx($scancmd $scanopts $host 2>/dev/null);
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
          $pkey{'aliases'} == $pline{'aliases'};

      splice @lines, $idx, 1; # remove old line
      push @lines, unsplit_line($key, $host, @aliases);
      $changed = 1;
    } else {
      push @lines, unsplit_line($key, $host, @aliases);
      $changed = 1;
    }
  }

  return if $changed == 0;
  open my $hdle, '>', $file or croak "cant open $file for writing: $ERRNO";
  print {$hdle} @lines or croak "cant print to $file: $ERRNO";
  close $hdle or croak "can't close $file: $ERRNO";
  return 0;
}


# looks for hostname and encryption type and matches against
# the contents of the ssh_known_hosts file
#
# args:
# - line from ssh-keyscan
# - hostname that was scanned
# - array of lines from known_hosts
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
  my @aliases = @k[1, -1];
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


### start

my $file = '/etc/ssh/ssh_known_hosts';
my $scancmd = 'ssh-keyscan';
my $scanout = '';
my $scanopts = '';
my $removehost = 0;
my $usage = <<'TEXT';
usage: knownhosts.pl [-h] [-f FILE] [-S SCANFILE] [-o OPTS] [-c COMMAND]
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
  -r REMOVE, --remove REMOVE
                        remove all entries of this host from the
                        ssh_known_hosts file. Not implemented yet

Examples of useful options to pass to the ssh-keyscan program are: port number
and encryption type
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

my @newkeys = scan_keys($host, $scanout, $scancmd, $scanopts);
compare_known_hosts($host, $file, \@aliases, \@newkeys);

### end
