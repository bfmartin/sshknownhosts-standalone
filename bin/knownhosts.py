#!/usr/bin/python3

"""add and remove entries from an ssh known hosts file."""
# knownhosts.py
#
# maintain the /etc/ssh/ssh_known_hosts file by scanning hosts for
# keys and adding entries to the file.
#
# author:
# Byron F. Martin <https://www.bfmartin.ca/contact/>
#
# tested on:
# - python 3.8.10 on Linux Mint 20.2 (and previous versions)
# - python 3.8.0 on OpenBSD 7.0 (and previous versions)

import argparse
import os
import re
import subprocess

# args:
# - hostname to scan
# - optional string containing results to return. None if not testing
# - the command to use for scanning keys
# - other options to supply to the scan command
#
# returns:
# - a list of strings
def scan_keys(host, scanfile, scanprog, opts):
    """run scanprog (with opts) against host and return the results.

    optionally, if scanfile is supplied, return the contents of that file
    (useful for testing)."""
    if scanfile is None:
        # prepare to run keyscan
        scanargs = [scanprog]
        if not opts is None:
            scanargs.extend(re.split(r"\s+", opts))

        scanargs.append(host)
        # send stderr to /dev/null. does this work everywhere?
        devnull = open('/dev/null', 'w')
        output = subprocess.check_output(scanargs, stderr=devnull)
        return re.split(r"\n", output.decode("utf-8"))[0:-1]

    # testing mode. read the supplied filenames and return the list
    with open(scanfile) as fhandle:
        lines = fhandle.read().splitlines()
        fhandle.close()
        return lines


# args
# - the hostname given to ssh-keyscan (from the command line)
# - name of knownhosts file
# - a list of aliases for the hostname (from the command line)
# - a list of results from ssh-keyscan
#
# returns nothing
def compare_known_hosts(host, file, aliases, scankeys):
    """compare the keys from the scan against keys from the known_hosts file."""
    with open(file) as fhandle:
        lines = fhandle.read().splitlines()
        fhandle.close()
    changed = 0

    for key in scankeys:
        pkey = split_line(key)
        idx = match_host_type(key, lines)
        if idx > -1:
            pline = split_line(lines[idx])
            if pkey['key'] == pline['key'] and \
               pkey['aliases'] == pline['aliases']:
                break  # or should this be continue?

            del lines[idx]
            lines.append(unsplit_line(key, host, aliases))
            changed = 1
        else:
            lines.append(unsplit_line(key, host, aliases))
            changed = 1

    if changed == 0:
        return

    write_knownhosts_file(file, lines)
    return


# removes a host for any type of key from the knownhosts file. the
# supplied hostname can be the hostname in the knownhosts file, or an
# alias of the hostname.
#
# args:
# - the hostname to remove
# - name of knownhosts file
#
# returns nothing
def remove_host(host, file):
    """remove all host key lines matching a hostname or alias."""
    with open(file) as fhandle:
        lines = fhandle.read().splitlines()
        fhandle.close()

    newlines = [line for line in lines if comparehost(line, host)]
    if len(lines) == len(newlines):
        return

    write_knownhosts_file(file, newlines)


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
# the hostname is found. this is because of the logic of the 'for'
# command above.
def comparehost(line, host):
    """return false if a hostname matches hostname or aliases."""
    pline = split_line(line)
    if pline['host'] == host or host in pline['aliases']:
        return False
    return True


# looks for hostname and encryption type and matches against
# the contents of the ssh_known_hosts file
#
# args:
# - line from ssh-keyscan
# - list of lines from knownhosts
#
# returns
# - int index to the match, or -1 if no match found
def match_host_type(scanline, thesekeys):
    """return the line number of a matching hostname and keytype in a list."""
    pscn = split_line(scanline)

    idx = -1
    for key in thesekeys:
        idx += 1
        pkey = split_line(key)
        if pscn['type'] == pkey['type'] and pscn['host'] == pkey['host']:
            return idx
    return -1  # not found


# parses a line from knownhosts or ssh-keyscan and returns a hash with
# these keys:
# - host     host name
# - aliases  list of aliases
# - type     encryption type
# - key      public key for host
#
# args:
# - the line to parse
#
# returns:
# - hash containing parsed line
def split_line(line):
    """split a knownhosts output line into component pieces."""
    i = re.split(r"\s+", line)
    k = re.split(r",", i[0])
    aliases = k[1:]
    return {'host': k[0], 'aliases': aliases, 'type': i[1], 'key': i[2]}


# given a line from either ssh-keyscan or knownhosts, replace the host
# with the supplied hostname and aliases
# args:
# - line from knownhosts or ssh-keyscan
# - hostname
# - list of aliases
#
# returns
# - the line to enter into the ssh_known_hosts file
def unsplit_line(line, host, aliases):
    """combine a hash into a knownhosts output line."""
    pline = split_line(line)
    return " ".join([",".join([host] + aliases)] +
                    [pline['type']] + [pline['key']])


# write a list of lines to the knownhosts file
#
# args:
# - the filename
# - a list of strings
#
# returns nothing
def write_knownhosts_file(file, lines):
    """write an array of knwonhosts lines to a knownhosts file."""
    print("writing to " + file)
    with open(file, 'w') as fhandle:
        fhandle.writelines("%s\n" % line for line in lines)


# start here

PARSER = argparse.ArgumentParser(
    description='A command to maintain the ssh_known_hosts file.',
    epilog='Examples of useful options (--opts) to pass to the ssh-keyscan '
           'program are: port number and encryption type')

PARSER.add_argument('-f', '--file', type=str,
                    default='/etc/ssh/ssh_known_hosts',
                    help='the ssh_known_hosts file to edit. default: '
                    '%(default)s')
PARSER.add_argument('-S', '--SCANFILE', type=str,
                    help='instead of scanning the host with ssh-keyscan, use '
                    'the contents of this file. useful for testing.')
PARSER.add_argument('-o', '--opts', type=str,
                    help='supply this string as options to the ssh-keyscan '
                    'program')
PARSER.add_argument('-c', '--command', default='ssh-keyscan',
                    help='use this command to scan for keys. default: '
                    '%(default)s')
PARSER.add_argument('-r', '--remove', action="store_true", help='remove all '
                    'entries/keytypes of this host from the ssh_known_hosts file.'
                    ' if remove is selected, only the first hostname is processed.'
                    ' other args are ignored.')

PARSER.add_argument('host', type=str, help='the hostname to scan')
PARSER.add_argument('aliases', nargs='*', default=[], help='aliases for host')

ARGS = PARSER.parse_args()

# create file if it doesn't exist
if not os.path.exists(ARGS.file):
    with open(ARGS.file, 'a'):
        os.utime(ARGS.file, None)

if ARGS.remove:
    remove_host(ARGS.host, ARGS.file)
else:
    NEWKEYS = scan_keys(ARGS.host, ARGS.SCANFILE, ARGS.command, ARGS.opts)
    compare_known_hosts(ARGS.host, ARGS.file, ARGS.aliases, NEWKEYS)

# end
