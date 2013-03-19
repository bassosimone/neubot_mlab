#!/usr/bin/env python

#
# Copyright (c) 2011 Simone Basso <bassosimone@gmail.com>,
#  NEXA Center for Internet & Society at Politecnico di Torino
#
# This file is part of Neubot <http://www.neubot.org/>.
#
# Neubot is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Neubot is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Neubot.  If not, see <http://www.gnu.org/licenses/>.
#

''' Lists the hostname of all the nodes within a slice '''

#
# This file is invoked by various shell scripts to get
# a list of all the M-Lab nodes in our slice.
#

import ConfigParser
import asyncore
import getopt
import os
import sys
import time
import xmlrpclib

def lsmain():

    ''' Lists the hostname of all nodes within a slice '''

    try:
        options, arguments = getopt.getopt(sys.argv[1:], 'h')
    except getopt.error:
        sys.exit('usage: M-Lab/ls.py [-h]')
    if arguments:
        sys.exit('usage: M-Lab/ls.py [-h]')

    noheader = 1
    for opt in options:
        if opt[0] == '-h':
            noheader = 0

    config = ConfigParser.RawConfigParser()
    config.read(os.sep.join([os.environ['HOME'], '.planet-lab']))

    auth_info = {
        'AuthMethod': 'password',
        'Username': config.get('planet-lab', 'user'),
        'AuthString': config.get('planet-lab', 'password'),
        'Role': 'user'
    }

    proxy = xmlrpclib.ServerProxy('https://www.planet-lab.org/PLCAPI/')

    ids = proxy.GetSlices(auth_info, config.get('planet-lab', 'slice'),
                          ['node_ids'])[0]['node_ids']

    hostnames = [
        entry['hostname'] for entry in
            proxy.GetNodes(auth_info, ids, ['hostname'])
    ]

    # Header mode is needed to generate the static known-hosts table
    if not noheader:
        sys.stdout.write("STATIC_TABLE_TIME = '%s'\n" % time.ctime())
        sys.stdout.write('\n')
        sys.stdout.write('STATIC_TABLE = [\n')
    for hostname in hostnames:
        if not noheader:
            sys.stdout.write("    'neubot.mlab.%s',\n" % hostname)
        else:
            sys.stdout.write('%s\n' % hostname)
    if not noheader:
        sys.stdout.write(']\n')

def main():
    ''' Wrapper for the real main '''
    try:
        lsmain()
    except:
        sys.stderr.write('%s\n' % str(asyncore.compact_traceback()))
        sys.exit(1)

if __name__ == '__main__':
    main()
