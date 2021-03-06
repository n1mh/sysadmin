#!/bin/bash

# Diego Martínez Castañeda <n1mh@n1mh.org>
# mié ene 24 12:10:17 CET 2018
#
# Syncronization with google drive, although it work with several cloud
# platforms.
#
# Before use this script must install rclone and configure it. Remote volume is
# called 'gdrive' here but you'll probably have to change it.
#   $ sudo apt-get install -y rclone
#   $ rclone config
#   $ vi ~/bin/sync_gdrive.sh
#   $ bash ~/bin/sync_gdrive.sh
#
# In case you want to execute it every day (as it should be), add it to your
# crontab. In this example it is executed every working day (Mon-Fri) at 14:30.
#   $ crontab -l > /tmp/crontab0
#   $ echo "30 14 * * 1-5 $HOME/bin/sync_gdrive.sh" >> /tmp/crontab0
#   $ crontab /tmp/crontab0
#   $ rm -f /tmp/crontab0

DIRS="$HOME/documents/important $HOME/documents/hobbies"
REMOTE_DRIVE="gdrive"
REMOTE_DIR="sync"

if [ `rclone lsd $REMOTE_DRIVE:$REMOTE_DIR | grep -ci 'directory not found'` = '1' ] ; then
    echo "W: remote directory not found $REMOTE_DIR. Creating it..."
    rclone mkdir $REMOTE_DRIVE:$REMOTE_DIR
fi

for DIR in $DIRS ; do

    if [ ! -d $DIR ] ; then
        echo "W: local directory $DIR not found. Skipping..."
    else
        REMOTE_DIR_NAME=`basename $DIR`
        if [ `rclone lsd $REMOTE_DRIVE:$REMOTE_DIR/$REMOTE_DIR_NAME | grep -ci 'directory not found'` = '1' ] ; then
            echo "W: remote directory not found $REMOTE_DIR/$REMOTE_DIR_NAME. Creating it..."
            rclone mkdir $REMOTE_DRIVE:$REMOTE_DIR/$REMOTE_DIR_NAME
        fi

        echo "Sync: $DIR --> $REMOTE_DIR/$REMOTE_DIR_NAME... "
        rclone copy --update $DIR $REMOTE_DRIVE:$REMOTE_DIR/$REMOTE_DIR_NAME
    fi
done

exit 0
