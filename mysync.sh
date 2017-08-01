#!/bin/bash

# Diego Martínez Castañeda <n1mh@n1mh.org>
# vie jul 28 14:18:43 CEST 2017

### VARIABLES
# General
PATH="/bin:/usr/bin:/sbin:/usr/sbin"
LANG="C"
NAME=`basename $0`
# Remote connection
SERVER__URI="idefix.galia.local"
SERVER_PORT="22"
SERVER_USER="bu"
SERVER__KEY="/root/.ssh/id_rsa_idefix"
SERVER_OPTS="ssh -i $SERVER__KEY -p $SERVER_PORT"
SERVER_PATH="/data/backup/`hostname -f`"
SERVER_CONN="$SERVER_USER@$SERVER__URI:$SERVER_PATH"
# Directory sync
DIR_OPTIONS="--delete"
DIR_WHTLIST="/root /etc /home"
#DIR_BLKLIST="--exclude=oc.example.com/data"
# SQL server
SQL__SYSTEM="mysql"
SQL_CNFFILE="/etc/mysql/my.cnf"
SQL_DATADIR="/var/lib/mysql"
SQL_BCKFILE="/root/`hostname -f`_sql_backup.tgz"
SQL_ADMUSER="root"
SQL_PASSWRD="UltraSecretPassword"
SQL_OPTIONS="--all-databases --max-allowed-packet=41M --extended-insert --quick --events --add-drop-database --skip-lock-tables"

### FUNCTIONS

function amIroot() {
    if [ ! $(id -u) = 0 ]; then
        echo 'this script must be run as root.'
        exit 1
    fi  
}

function parsingArgs() {
    for VAR in "$@" ; do
        case $1 in
            '--sql') processingSQL ;;
            '--www') DIR_WHTLIST="$DIR_WHTLIST /var/www/" ;;
            '--dir') DIR_WHTLIST="$DIR_WHTLIST $2"
                     shift ;;
        esac
        shift
    done
}

function processingSQL() {
    case $SQL__SYSTEM in
        'mysql')
            if [ -f $SQL_CNFFILE -a ! -L $SQL_CNFFILE ] ; then
                SQL_DATADIR=`grep ^datadir $SQL_CNFFILE | awk -F '=' '{print $2}' | tr -d ' '`
            fi
            ;;
        'mariadb')
            echo "coming soon"
            ;;
    esac

    /usr/bin/mysqldump -u $SQL_ADMUSER -p$SQL_PASSWRD \
        $SQL_OPTIONS \
        | gzip -9 > $SQL_BCKFILE

    if [ $? -ne '0' ] ; then
        echo "error creating $SQL_BCKFILE"
        exit 3
    fi

    DIR_WHTLIST="$DIR_WHTLIST $SQL_BCKFILE $SQL_DATADIR"
}

################################################################################
###                                   MAIN                                   ###
################################################################################

amIroot

if [ ! $@  ] ; then
    echo "$NAME [ --www | --sql | --dir PATH ]"
    exit 4
fi

parsingArgs "$@"

echo $DIR_WHTLIST

rsync  \
    -a \
    -v \
    -z \
    -e "$SERVER_OPTS" \
    $DIR_OPTIONS \
    $DIR_BLKLIST \
    $DIR_WHTLIST \
    $SERVER_CONN

[ -f $SQL_BCKFILE ] && rm -f $SQL_BCKFILE

exit 0
