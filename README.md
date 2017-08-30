# SSH Known Hosts - Standalone version


## Introduction

This project contains programs to configure the /etc/ssh/ssh_known_hosts file, or whatever it is called on your system.

The concepts are the same as other projects of mine, the ansible-sshknownhosts and ansible-sshknownhosts-role, except these are standalone programs instead of plugin modules for the Ansible project.

These scripts are intended to be used as part of a system configuration tool like Puppet, Chef, and others. The scripts are idempotent, which means they can be run as often as required without side effects.

There are currently two versions of the program, both in the bin directory. One is written in Python, the other in Perl. Both do exactly the same thing.


## License

This project is released under the 2-clause BSD license, which means you can do pretty much anything you want with it.


## Differences

Aside from being a standalone program, this project differs from earlier versions of my Ansible plugin projects, ansible-sshknownkeys and ansible-sshknownhosts-role, in the way encryption types are handled.

In the early versions of the ansible projects, the program would only scan for one encryption type at a time, and defaulted to rsa.

In this project, the programs, by default, do not specify any encryption types. This means the program will process all encryption types returned by the ssh-keyscan program. As of the time of this writing, those types are rsa, ecdsa and ed25519.

If you want to limit the encryption type, to mimic the early behaviour, do the following:

    $ knownhosts.py -o '-t ecdsa' hostname

or

    $ knownhosts.pl -o '-t ecdsa' hostname


## Security

Here is an excerpt from the ssh-keyscan man page:

If an ssh_known_hosts file is constructed using ssh-keyscan without verifying the keys, users will be vulnerable to man in the middle attacks. On the other hand, if the security model allows such a risk, ssh-keyscan can help in the detection of tampered keyfiles or man in the middle attacks which have begun after the ssh_known_hosts file was created.


## Project Goals

To be as portable as possible, including:

- As many operating systems as possible, though I only have a few to use for development and testing. This may be limited to those operating systems where OpenSSH is installed.

- Only the basic language install of Python or Perl is required, never any optional modules. Many operating systems come with one ore more of these languages preinstalled, so hopefully that is enough.

- The Python program should run on version 2 or 3.

- The Perl program should run on most or all modern versions of Perl.

If you see something violating these conditions, please let me know.


## Usage

Run the program to get a summary of usage like this:

    $ knownhosts.pl -h

or

    $ knownhosts.py -h


## Tests

Some unit tests are included. Type the following to run them:

    $ make

or

    $ make test


## To Do

These items should be done, in no particular order:

- Being relatively new to the Python language, I am not sure how to structure scripts for maximum portability. Especially the first line of the script is not very standard, and must be customised for different installations. Any hints or pointers on this would be greatly appreciated.

- The tests section of the Makefile contains a lot of similar statements. Remove some repetition from there.

- Possibly a port to a Posix shell version, though it may be reduced in functionality.
