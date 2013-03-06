#!/bin/bash

set -x
set -e

TOPDIR=/home/mlab_neubot
mkdir -p $TOPDIR

rm -rf neubot
[ -d neubot ] || \
    git clone https://github.com/neubot/neubot.git

pushd neubot
    destdir=dist/mlab
    tarball=$destdir/neubot.tar.gz
    version=$destdir/version

    rm -rf -- $destdir
    mkdir -p $destdir
    git archive --format=tar --prefix=neubot/ HEAD|gzip -9 > $tarball
    git describe --tags > $version
popd

cp neubot/dist/mlab/* $TOPDIR/
cp -r init $TOPDIR/

tar -C $TOPDIR -cvf mlab_neubot.tar .

