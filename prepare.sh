#!/bin/sh -e

#
# init/prepare.sh - Prepares the tarball that should be installed
# in all Measurement Lab slivers.
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

GITDIR=neubot
BUILDDIR=buildir

[ -d $GITDIR ] || \
    git clone https://github.com/neubot/neubot.git $GITDIR

(
    cd $GITDIR
    destdir=dist/mlab
    tarball=$destdir/neubot.tar.gz
    version=$destdir/version

    rm -rf -- $destdir
    mkdir -p $destdir
    #
    # Simone maintains a branch for deploying into M-Lab (and, yes, he
    # writes comments using the third person :-P)
    #
    git checkout stable_mlab
    git fetch origin
    git reset --hard origin/stable_mlab
    git archive --format=tar --prefix=neubot/ HEAD|gzip -9 > $tarball
    git describe --tags > $version
)

rm -rf $BUILDDIR
mkdir -p $BUILDDIR/init
cp initialize.sh start.sh stop.sh $BUILDDIR/init
cp neubot/dist/mlab/* $BUILDDIR

#
# Spell the list of files we want to install at /home/mlab_neubot because
# we don't want to include the current directory into the archive. If we
# include it, in fact, and we unpack the archive as root, the ownership of
# the home directory is steal by root; as a consequence, the unprivileged
# user is no longer permitted to write new files (unless he/she manages to
# log in and fixes the ownership).
#
tar -C $BUILDDIR -cvf mlab_neubot.tar init neubot.tar.gz version
