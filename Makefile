# -*- coding: utf-8 -*-
# These test cases validate the editing of the ssh_known_hosts file.
#
# test cases:
#  1 add new host
#  2 add new host and aliases
#  3 update host with changed key
#  4 update host and aliases with changed key
#  5 update host with new aliases but same key
#  6 update host with new aliases and new key
#  7 update host with removed aliases and same key
#  8 update host with removed aliases and new key
#  9 update host and new many aliases and changed key (similar to 4)
#  10 update host and new many aliases and same key (similar to 5)
#  11 remove a host given the hostname
#  12 remove a host given an alias
#  13 remove a non-existant host, so nothing is added/removed

TMPFILE = /tmp/knownhostsstandalone
.PHONY: test testsuite testrun style count

# run the set of tests for perl and python commands
# remove the -s to see trace messages
test:
	@make -s CMD=${PWD}/bin/knownhosts.pl _testsuite
	@make -s CMD=${PWD}/bin/knownhosts.py _testsuite
	@rm -f ${TMPFILE}

# run the set of tests for this command
_testsuite:
	make TESTNUM=1  CMDARGS="hostnameabc"                      _testrun
	make TESTNUM=2  CMDARGS="hostnameabc alias"                _testrun
	make TESTNUM=3  CMDARGS="hostname123"                      _testrun
	make TESTNUM=4  CMDARGS="hostname123 alias"                _testrun
	make TESTNUM=5  CMDARGS="hostname123 alias"                _testrun
	make TESTNUM=6  CMDARGS="hostname123 alias"                _testrun
	make TESTNUM=7  CMDARGS="hostname123"                      _testrun
	make TESTNUM=8  CMDARGS="hostname123"                      _testrun
	make TESTNUM=9  CMDARGS="hostname123 aliasa aliasb aliasc" _testrun
	make TESTNUM=10 CMDARGS="hostname123 aliasa aliasb aliasc" _testrun
	make TESTNUM=11 CMDARGS="-r hostname123"                   _testrun
	make TESTNUM=12 CMDARGS="-r alias1"                        _testrun
	make TESTNUM=13 CMDARGS="-r nonexistanthostname"           _testrun

# run an individual test.
# requires env vars:
#  - CMD       command to run (either bin/knownhosts.pl or bin/knownhosts.py)
#  - CMDARGS   extra command line options and args for knownhosts command for this test
#  - TESTNUM   test number to use (path in test/)
#  - TMPFILE   knownhostsfile to use. must be writable
#  - PWD       full path to directory containing Makefile (make defines this)
_testrun:
	cp tests/${TESTNUM}/testknownhosts-start ${TMPFILE}
	${CMD} -q -f ${TMPFILE} -S ${PWD}/tests/${TESTNUM}/testscan-start.txt ${CMDARGS}
	diff ${TMPFILE} tests/${TESTNUM}/testknownhosts-result

# housekeeping tasks. only of interest to the author
PLX = bin/*.pl
PYX = bin/*.py
XTRAC = Makefile
sinclude ~/bin/lib/Makefile-global
