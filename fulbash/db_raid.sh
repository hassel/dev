#!/bin/bash -u
# derp

ECHO=/bin/echo
PARTED=/sbin/parted
MKDIR=/bin/mkdir
MOUNT=/bin/mount
MKFS=/sbin/mkfs.xfs
ID=/usr/bin/id
CHOWN=/bin/chown
USER="postgres"

function _get_disk_type () {
        if [ -b "/dev/sdb" ]; then
          device="/dev/sdb"
        elif [ -b "/dev/cciss/c0d1p1" ]; then
          device="/dev/cciss/c0d1p1"
        elfi
          $ECHO "Error, devivce not found"
          exit 1
        fi
} 

function _mkfs_and_dir (){
  if [ -x $MKFS ]; then
          $ID -u $USER
    if [ "$?" == "0" ]; then
          DIR="/var/lib/postgresql"
       	  PART="$(echo $device)1"
          $MKDIR $DIR 
          $CHOWN -R $USER:$USER $DIR
          $PARTED -s -a optimal $device mklabel gpt -- mkpart logical xfs 1 -1
	        $MKFS -f $PART
          $ECHO "$PART $DIR   xfs     noatime,defaults        0       0" >> /etc/fstab
    else
          $ECHO "User postgres doesn't exist, please kerberise"
          exit 1
    fi
  else
          $ECHO "xfs not avalible"
          $ECHO "Please : apt-get install xfsprogs"
          exit 1
  fi

}

function _mount () {
       	$MOUNT -a
}

	
function _main () {
        _get_disk_type
        _mkfs_and_dir
        _mount
}

_main
