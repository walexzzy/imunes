#!/bin/sh

. scripts/prepare_vroot_functions.sh

PACKAGES="$PACKAGES_MINIMAL $PACKAGES_COMMON isc-dhcp42-server cone xorp \
firefox wireshark gnome-themes-standard"

checkArgs $*

# Start installation
mkdir -p $WORKDIR
cd $WORKDIR
echo -n "" > $LOG

if [ $mini -eq 1 ]; then
    PKGS=${PACKAGES_MINIMAL}
else
    PKGS=${PACKAGES}
fi

if [ $offline -eq 0 ]; then
    fetchBaseOnline
fi

if [ $zfs -eq 1 ]; then
    prepareZfs
else
    prepareUnionfs
fi

populateFs

if [ $offline -eq 0 ]; then
    cp /etc/resolv.conf $VROOT_MASTER/etc
    chroot $VROOT_MASTER /bin/sh -c 'env ASSUME_ALWAYS_YES=YES pkg bootstrap' >> $LOG 2>&1
fi

preparePackagesPkg
installPackagesPkg

if [ $mini -eq 0 ]; then
    installAdditionalTools install_click.sh
fi

configQuagga
configXorp

wiresharkDialog

rm -fr $VROOT_MASTER/tmp/*
rm -fr $VROOT_MASTER/*.txz

rm $VROOT_MASTER/etc/resolv.conf

if [ $zfs -eq 1 ]; then
    takeZfsSnapshot
fi

log "OUT" "Installation successfully finished. Check the log for more \
information: $LOG"
