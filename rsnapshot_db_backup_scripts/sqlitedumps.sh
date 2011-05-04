#!/bin/sh
# to be invoked by rsnapshot
# user this script runs as needs passwordless ssh to remote host
# use to dump & backup a series of sqlite db's all in the same directory

USAGE="$0 <remote host> <directory holding sqlite databases>"

if [ $# != 2 ]; then
    echo $USAGE
    exit 1
fi

REMOTE_HOST="$1"
DB_DIR="$2"
DB_EXT="sqlite"
DUMP_DIR="/tmp"
DUMP_EXT="sqlitedump"

BASENAME_BIN="/usr/bin/basename"
LS_BIN="/bin/ls"
SQLITE_BIN="/usr/bin/sqlite3"
SSH_BIN="/usr/bin/ssh"
RSYNC_BIN="/usr/bin/rsync -az -e $SSH_BIN"

# get a list of our databases, dump and copy over each one
DBS=$($SSH_BIN $REMOTE_HOST "$LS_BIN $DB_DIR/*.$DB_EXT")
for DB in $DBS; do
    DB_NAME=$($BASENAME_BIN $DB .$DB_EXT)
    DUMP_FILE="$DUMP_DIR/$DB_NAME.$DUMP_EXT"
    $SSH_BIN $REMOTE_HOST "$SQLITE_BIN $DB .dump > $DUMP_FILE"
    $RSYNC_BIN $REMOTE_HOST:$DUMP_FILE .
done
