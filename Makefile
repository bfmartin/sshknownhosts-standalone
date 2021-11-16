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
	@make -s CMD=${PWD}/bin/knownhosts.pl testsuite
	@make -s CMD=${PWD}/bin/knownhosts.py testsuite
	@rm -f ${TMPFILE}

# run the set of tests for this command
testsuite:
	make TESTNUM=1  CMDARGS="hostnameabc"                      testrun
	make TESTNUM=2  CMDARGS="hostnameabc alias"                testrun
	make TESTNUM=3  CMDARGS="hostname123"                      testrun
	make TESTNUM=4  CMDARGS="hostname123 alias"                testrun
	make TESTNUM=5  CMDARGS="hostname123 alias"                testrun
	make TESTNUM=6  CMDARGS="hostname123 alias"                testrun
	make TESTNUM=7  CMDARGS="hostname123"                      testrun
	make TESTNUM=8  CMDARGS="hostname123"                      testrun
	make TESTNUM=9  CMDARGS="hostname123 aliasa aliasb aliasc" testrun
	make TESTNUM=10 CMDARGS="hostname123 aliasa aliasb aliasc" testrun
	make TESTNUM=11 CMDARGS="-r hostname123"                   testrun
	make TESTNUM=12 CMDARGS="-r alias1"                        testrun
	make TESTNUM=13 CMDARGS="-r nonexistanthostname"           testrun

# run an individual test.
# requires env vars:
#  - CMD       command to run (either bin/knownhosts.pl or bin/knownhosts.py)
#  - CMDARGS   extra command line options and args for knownhosts command for this test
#  - TESTNUM   test number to use (path in test/)
#  - TMPFILE   knownhostsfile to use. must be writable
#  - PWD       full path to directory containing Makefile (make defines this)
testrun:
	cp tests/${TESTNUM}/testknownhosts-start ${TMPFILE}
	${CMD} -q -f ${TMPFILE} -S ${PWD}/tests/${TESTNUM}/testscan-start.txt ${CMDARGS}
	diff ${TMPFILE} tests/${TESTNUM}/testknownhosts-result

# "pylint -s no" = disable score
style:
	-@perlcritic -4 -q bin/knownhosts.pl
	-@pylint -s no bin/knownhosts.py
# perlcritic version 1.138
# pylint version 2.4.4

# housekeeping task to count lines of code
# outputs: date, linecount, filecount, avg-lines-per-file
count:
	@FCOUNT=$$(ls bin/knownhosts.* Makefile | wc -l) && \
		LCOUNT=$$(cat bin/knownhosts.* Makefile | sed "s/#.*//" | awk NF | wc -l) && \
		AVG=$$(echo "scale=1;$$LCOUNT/$$FCOUNT" | bc -l) && \
		echo $$(date +%Y-%m-%d), "$$LCOUNT", "$$FCOUNT", "$$AVG"
