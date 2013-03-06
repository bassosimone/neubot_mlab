#!/bin/sh -e

#
# init/prepare.sh - Prepares the tarball that should be installed
# in all Measurement Lab slivers.
#
# Written by Stephen Soltesz and Simone Basso.
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
# is steal by root -- as a consequenc the ordinary user `mlab_neubot` is
# not able to write new files (unless he/she logs in and fixes the ownership,
# which is annoying).
#
tar -C $BUILDDIR -cvf mlab_neubot.tar init neubot.tar.gz version
