#!/bin/bash
# - 2013-03-15
# - Initial script carl.hasselstrom@pwny.se

# Bins

FIND=/usr/bin/find
MKDIR=/bin/mkdir
TAR=/bin/tar
CP=/bin/cp
SCP=/usr/bin/scp
ECHO=/bin/echo
RM=/bin/rm
MD5=/usr/bin/md5sum

# Vars

# Remote

DST="172.16.10.1"	## Remote host that should reciev backups
DST_PATH="~/"    	## Remote host fqpn (ie /var/backup/)
USER="user"		## Remote host user

# Local

KEY="~/.ssh/id_rsa"			## Local ssh key to use
DBG="/var/log/backup.log"		## Logfile to write backup logs to
LOG_PATH="/home/carhas/dev/test" 	## Where logs that should be backedup are located
WORK_DIR="/tmp/backup"			## Where to create a temporary work environment

RND=$RANDOM
AGE="-1"

if [ -z $1 ]; then
	TODAY=$(date +%F)
	else
	TODAY="$1";
fi

# YESTERDAY=$(date --date -day +%F)


## Create tmp dir for work.

$MKDIR -p $WORK_DIR/$RND

## Check exit status and write to log
if [ "$?" -eq "0" ]; then
	$ECHO "`date +%F-%R` -> DBG : MKDIR $WORK_DIR/$RND Success" >> ${DBG}
	else
	$ECHO "`date +%F-%R` -> DBG : MKDIR $WORK_DIR/$RND Was not sucessfull" >> ${DBG}
	exit 1
fi

## Find and compress logs.
if [ -z $($FIND $LOG_PATH -type f -mtime $AGE | wc -c) ]; then
	$ECHO "`date +%F-%R` -> DBG : FIND No logs in $LOG_PATH found" >> ${DBG}
	exit 1
fi

## If logs found, copy logs to tmp dir and compress to backupfile

$FIND $LOG_PATH -type f -mtime $AGE  -exec $CP -a {} $WORK_DIR/$RND \;
$TAR cvfz $WORK_DIR/backup.$TODAY.$RND.tar.gz -C $WORK_DIR/$RND .  >> /dev/null 2>&1


## Check exit status and write to log
if [ "$?" -eq "0" ]; then
	$ECHO "`date +%F-%R` -> DBG : TAR backup.$TODAY.$RND.tar.gz in $WORK_DIR/$RND Created successfully" >> ${DBG}
	else
	$ECHO "`date +%F-%R` -> DBG : TAR backup.$TODAY.$RND.tar.gz in $WORK_DIR/$RND Not created successfully" >> ${DBG}
	exit 1
fi

## Send files to remote dst & create md5 checksum
cd $WORK_DIR && $MD5 backup.$TODAY.$RND.tar.gz > backup.$TODAY.$RND.tar.gz.md5
$SCP -i $KEY $WORK_DIR/backup.$TODAY.$RND.tar.gz $USER@$DST:$DST_PATH
$SCP -i $KEY $WORK_DIR/backup.$TODAY.$RND.tar.gz.md5 $USER@$DST:$DST_PATH

## Check exit status and write to log
if [ "$?" -eq "0" ]; then
	$ECHO "`date +%F-%R` -> DBG : SCP backup.$TODAY.$RND.tar.gz in $WORK_DIR/$RND Moved successfully" >> ${DBG}
	else
	$ECHO "`date +%F-%R` -> DBG : SCP backup.$TODAY.$RND.tar.gz in $WORK_DIR/$RND Not moved successfully" >> ${DBG}
	exit 1
fi

## Clean up
$RM -rf $WORK_DIR/*

exit 0
