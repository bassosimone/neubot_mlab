#!/bin/bash

cd /home/mlab_neubot
SUDO="/usr/bin/sudo"

set -e
set -x

if [ -f neubot.tar.gz ] ; then 
    echo "install neubot"
    tar -xzf neubot.tar.gz
    python -m compileall -q neubot/neubot/

    echo "start new neubot"
    /home/mlab_neubot/neubot/M-Lab/install.sh
    /etc/rc.d/rc.local

    echo "cleanup"
    #rm -rf neubot.tar.gz
    echo "make sure we've bind all ports"
    netstat -a --tcp -n | grep LISTEN | awk '{print $4}' | sort > neubot/M-Lab/ports.new
    diff -u neubot/M-Lab/ports.txt neubot/M-Lab/ports.new
else
    echo "neubot.tar.gz missing"
    echo "really shouldn't happen, but you never know."
    exit 1
fi
