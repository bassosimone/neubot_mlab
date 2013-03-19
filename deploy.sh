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
# XXX The version of sudo installed by Measurement Lab fails because no ssh
# askpass program was specified and stdin is not a tty (even if it is not
# configured to ask for a password).  To work around this check, we provide
# both the -A command line argument and the SUDO_ASKPASS environment variable.
# It does not matter that SUDO_ASKPASS does not exist, since sudo is not
# configured to use a password; thus, it won't invoke that command.
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

HOSTS=$*

COUNT=0
for HOST in $HOSTS; do
    COUNT=$(($COUNT + 1))

    # Blank line before to separate each host logs
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
            echo "$HOST: stop and remove old neubot"
            STOP_SH='/home/mlab_neubot/init/stop.sh'
            $SSH $HOST "if test -x $STOP_SH; then $SUDO $STOP_SH || true; fi"
            $SSH $HOST $SUDO rm -rf -- init neubot version

            echo "$HOST: copy mlab distribution"
            $SCP $TARBALL $HOST:

            echo "$HOST: unpack mlab distribution"
            $SSH $HOST tar -xf mlab_neubot.tar

            echo "$HOST: initialize mlab distribution"
            $SSH $HOST $SUDO /home/mlab_neubot/init/initialize.sh

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
done
