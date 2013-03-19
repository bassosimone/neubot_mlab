#!/bin/sh -e

#
# init/initialize.sh - Prepares the environment for Neubot after it
# has been installed on a sliver.
#
# Written by Stephen Soltesz and Simone Basso.
#
# =======================================================================
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
# =======================================================================
#

if [ `id -u` -ne 0 ]; then
    echo "$0: FATAL: need root privileges" 1>&2
    exit 1
fi

cd /home/mlab_neubot

if [ -f neubot.tar.gz ]; then 
    echo "install neubot"
    tar -xzf neubot.tar.gz
    python -m compileall -q neubot/neubot/

    echo "start new neubot"
    /home/mlab_neubot/neubot/M-Lab/install.sh
    /home/mlab_neubot/init/start.sh

    echo "cleanup"
    rm -rf mlab_neubot.tar neubot.tar.gz

    echo "make sure we've bind all ports"
    netstat -a --tcp -n | grep LISTEN | awk '{print $4}' \
        | sort > neubot/M-Lab/ports.new
    diff -u neubot/M-Lab/ports.txt neubot/M-Lab/ports.new

else
    echo "FATAL: neubot.tar.gz missing" 1>&2
    exit 1
fi
