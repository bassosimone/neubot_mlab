#!/bin/sh -e

#
# Copyright (c) 2011-2013
#     Nexa Center for Internet & Society, Politecnico di Torino (DAUIN)
#     and Simone Basso <bassosimone@gmail.com>
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

#
# Deploy Neubot to M-Lab slivers
#

DEBUG=
FORCE=0

# Wrappers for ssh, scp
SCP="$DEBUG $HOME/bin/mlab_scp"
SSH="$DEBUG $HOME/bin/mlab_ssh"

#
# The version of sudo installed by Measurement Lab fails because no ssh askpass
# program is specified and stdin is not a tty.  To avoid this problem, we
# provide both the -A command line argument and the SUDO_ASKPASS environment
# variable, like we do for the master server.
#
SUDO="$DEBUG SUDO_ASKPASS=/usr/bin/ssh-askpass /usr/bin/sudo -A"

usage() {
    echo "usage: $0 [-f] [host... ]" 1>&2
    echo "  -f : Force deployment when it is already deployed" 1>&2
    exit 1
}

# Command line
args=$(getopt f $*) || {
    usage
}
set -- $args
while [ $# -gt 0 ]; do
    if [ "$1" = "-f" ]; then
        FORCE=1
        shift
    elif [ "$1" = "--" ]; then
        shift
        break
    fi
done

TARBALL=mlab_neubot.tar
if [ ! -f $TARBALL ]; then
    echo "FATAL: Missing '$TARBALL'; please run 'prepare.sh'" 1>&2
    exit 1
fi

#
# Note: this function uses two global variables: HOST and COUNT.  We use
# global variables to the script works with both POSIX shells (where `local`
# or `typeset` are available) and ksh93.
#
do_deploy()
{
    COUNT=$(($COUNT + 1))

    # A blank line separates one host's log from another host's log
    echo ""
    echo "$HOST: start deploy"
    echo "$HOST: current host number $COUNT"

    #
    # Run the installation in the subshell with set -e so that
    # the first command that fails "throws an exception" and we
    # know something went wrong looking at $?.
    #
    # Note: We need to reenable errors otherwise the outer shell
    # is going to bail out if the inner one fails.
    #
    set +e
    (
        set -e

        DOINST=1
        if [ $FORCE -eq 0 ]; then
            echo "$HOST: check whether neubot is installed... "
            if $SSH $HOST 'ps auxww|grep -q ^_neubot'; then
                echo "$HOST: neubot is installed; use -f to force reinstall"
                DOINST=0
            fi
        fi

        if [ "$DOINST" = "1" ]; then
            echo "$HOST: copy mlab distribution tarball"
            $SCP $TARBALL $HOST:

            echo "$HOST: stop previous neubot instance (if any)"
            STOP_SH=/home/mlab_neubot/init/stop.sh
            $SSH $HOST $SUDO " $STOP_SH || true "

            echo "$HOST: unpack mlab distribution tarball"
            $SSH $HOST tar -xf mlab_neubot.tar

            echo "$HOST: initialize mlab distribution"
            $SSH $HOST $SUDO /home/mlab_neubot/init/initialize.sh

            echo "$HOST: start new neubot"
            $SSH $HOST $SUDO /home/mlab_neubot/init/start.sh

            echo "$HOST: remove mlab distribution tarball"
            $SSH $HOST rm mlab_neubot.tar
        fi

    #
    # As soon as we exit from the subshell, save the error (if any) and
    # re-enable errors, to catch potential doofus in the remainder of the
    # script.
    #
    )
    ERROR=$?
    set -e

    echo "$HOST: deploy result: $ERROR"
    echo "$HOST: deploy complete"
}

COUNT=0
if [ $# -ne 0 ]; then
    for HOST in $*; do
        do_deploy
    done
else
    while read HOST REMAINDER; do
        do_deploy
    done
fi
