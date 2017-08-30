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
#
# not done yet:
#  - remove host
#  - remove host and aliases

# these options are always used when running knownhosts.p[ly] in the tests
OPTS=-f testknownhosts -S testscan.txt

# start here
all: testperl testpython

testpython:
	@mkdir -p tmp
	@cp bin/knownhosts.py tmp/knownhosts
	make runall

testperl:
	@mkdir -p tmp
	@cp bin/knownhosts.pl tmp/knownhosts
	make runall

runall: t1 t2 t3 t4 t5 t6 t7 t8 t9 t10 t11 t12 t13
	@rm -rf tmp

t1:
	cp tests/1/testscan-start.txt tmp/testscan.txt
	cp tests/1/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) hostnameabc)
	diff tmp/testknownhosts tests/1/testknownhosts-result

t2:
	cp tests/2/testscan-start.txt tmp/testscan.txt
	cp tests/2/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) hostnameabc alias)
	diff tmp/testknownhosts tests/2/testknownhosts-result

t3:
	cp tests/3/testscan-start.txt tmp/testscan.txt
	cp tests/3/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) hostname123)
	diff tmp/testknownhosts tests/3/testknownhosts-result

t4:
	cp tests/4/testscan-start.txt tmp/testscan.txt
	cp tests/4/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) hostname123 alias)
	diff tmp/testknownhosts tests/4/testknownhosts-result

t5:
	cp tests/5/testscan-start.txt tmp/testscan.txt
	cp tests/5/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) hostname123 alias)
	diff tmp/testknownhosts tests/5/testknownhosts-result

t6:
	cp tests/6/testscan-start.txt tmp/testscan.txt
	cp tests/6/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) hostname123 alias)
	diff tmp/testknownhosts tests/6/testknownhosts-result

t7:
	cp tests/7/testscan-start.txt tmp/testscan.txt
	cp tests/7/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) hostname123)
	diff tmp/testknownhosts tests/7/testknownhosts-result

t8:
	cp tests/8/testscan-start.txt tmp/testscan.txt
	cp tests/8/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) hostname123)
	diff tmp/testknownhosts tests/8/testknownhosts-result

t9:
	cp tests/9/testscan-start.txt tmp/testscan.txt
	cp tests/9/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) hostname123 aliasa aliasb aliasc)
	diff tmp/testknownhosts tests/9/testknownhosts-result

t10:
	cp tests/10/testscan-start.txt tmp/testscan.txt
	cp tests/10/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) hostname123 aliasa aliasb aliasc)
	diff tmp/testknownhosts tests/10/testknownhosts-result

t11:
	cp tests/11/testscan-start.txt tmp/testscan.txt
	cp tests/11/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) -r hostname123)
	diff tmp/testknownhosts tests/11/testknownhosts-result

t12:
	cp tests/12/testscan-start.txt tmp/testscan.txt
	cp tests/12/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) -r alias1)
	diff tmp/testknownhosts tests/12/testknownhosts-result

t13:
	cp tests/13/testscan-start.txt tmp/testscan.txt
	cp tests/13/testknownhosts-start tmp/testknownhosts
	(cd tmp && ./knownhosts $(OPTS) -r nonexistanthostname)
	diff tmp/testknownhosts tests/13/testknownhosts-result
