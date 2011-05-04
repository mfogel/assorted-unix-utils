#!/bin/sh
# to be invoked by rsnapshot
# user this script runs as needs passwordless ssh to remote host
# use to dump & backup a series of mysql db's matching a sql LIKE pattern

USAGE="$0 <remote host> <database name sql LIKE clause>"

if [ $# != 2 ]; then
    echo $USAGE
    exit 1
fi

REMOTE_HOST="$1"
DB_LIKE="$2"
DUMP_DIR="/tmp"
DUMP_EXT="mysqldump"

SSH_BIN="/usr/bin/ssh"
RSYNC_BIN="/usr/bin/rsync -az -e $SSH_BIN"
MYSQL_BIN="/usr/bin/mysql --skip-column-names"
MYSQLDUMP_BIN="/usr/bin/mysqldump"

# get a list of our databases, dump each one
DBS=$($SSH_BIN $REMOTE_HOST "$MYSQL_BIN -e \"SHOW DATABASES LIKE '$DB_LIKE'\"")
for DB in $DBS; do
    DUMP_FILE="$DUMP_DIR/$DB.$DUMP_EXT"
    $SSH_BIN $REMOTE_HOST "$MYSQLDUMP_BIN $DB > $DUMP_FILE"
    $RSYNC_BIN $REMOTE_HOST:$DUMP_FILE .
done
