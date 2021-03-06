#!/bin/sh -e

#
# init/prepare.sh - Prepares the neubot distribution that should be
# copied in all Measurement Lab slivers.
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

if [ $# -gt 1 ]; then
    echo "usage: $0 [branch]" 1>&2
    exit 1
elif [ $# -eq 1 ]; then
    REMOTEBRANCH=$1
else
    #
    # Simone maintains a branch for deploying into M-Lab (and, yes, he
    # writes comments using the third person :-P)
    #
    REMOTEBRANCH=stable_mlab
fi

umask 022  # Override possibly-stricter user umask

echo "NOTICE: preparing release from ${REMOTEBRANCH}'s HEAD"

BUILDDIR=buildir
GITDIR=neubot
INITDIR=neubot-support/init

[ -d $GITDIR ] || \
    git clone https://github.com/neubot/neubot.git $GITDIR

(
    cd $GITDIR
    DESTDIR=dist/mlab
    TARBALL=$DESTDIR/neubot.tar.gz
    VERSION=$DESTDIR/version

    rm -rf -- $DESTDIR
    mkdir -p $DESTDIR
    git fetch origin
    git checkout $REMOTEBRANCH
    git reset --hard origin/$REMOTEBRANCH
    git archive --format=tar --prefix=neubot/ HEAD|gzip -9 > $TARBALL
    git describe --tags > $VERSION
)

rm -rf $BUILDDIR
mkdir -p $BUILDDIR/init
install $INITDIR/initialize.sh $INITDIR/start.sh $INITDIR/stop.sh \
    $BUILDDIR/init
cp neubot/dist/mlab/* $BUILDDIR

#
# Use '*' rather than '.' because we don't want to include the current
# directory into the archive. If we include it, in fact, and we unpack the
# archive as root, the ownership of the home directory is steal by root; as a
# consequence, the unprivileged user is no longer permitted to write new
# files (unless he/she manages to log in and fixes the ownership).
#
tar -C $BUILDDIR -cvf mlab_neubot.tar `ls $BUILDDIR`
