#!/bin/sh
# to be invoked by rsnapshot
# user this script runs as needs passwordless ssh to remote host
# use to dump & backup a series of postgres db's matching a sql LIKE pattern

# PERMISSONS NOTE:
#   Ideally, you'd like the user running this to be read-only for at least
#   all databases it's dumping. (And perhaps the whole server - to avoid
#   forgetting to grant read permissions to the backup user for new db's.)
#   There's no easy way to do this in postgres... permissions are granted
#   per-table in <9.0, and in 9.0 there's a ALL TABLES IN SCHEMA option but
#   still no way to account for future db's.
#
#   As such, the best way to this as of now is to grant the backups user
#   user superuser status.
#
#   http://archives.postgresql.org/pgsql-novice/2002-10/msg00081.php
#   http://www.ruizs.org/archives/89
#   http://www.microhowto.info/howto/dump_a_complete_postgresql_database_as_sql.html#id2550261
#   http://www.postgresql.org/docs/8.4/static/sql-grant.html
#   http://www.postgresql.org/docs/9.0/static/sql-grant.html

USAGE="$0 <remote host> <database name sql LIKE clause>"

if [ $# != 2 ]; then
    echo $USAGE
    exit 1
fi

REMOTE_HOST="$1"
DB_LIKE="$2"
DUMP_DIR="/tmp"
DUMP_EXT="postgresdump"

SSH_BIN="/usr/bin/ssh"
RSYNC_BIN="/usr/bin/rsync -az -e $SSH_BIN"
POSTGRES_BIN="/usr/bin/psql -t postgres"
POSTGRESDUMP_BIN="/usr/bin/pg_dump"

# get a list of our databases, dump each one
SELECT_DBS_SQL="SELECT datname FROM pg_database WHERE datname like E'$DB_LIKE'"
DBS=$($SSH_BIN $REMOTE_HOST "$POSTGRES_BIN -c \"$SELECT_DBS_SQL\"")
for DB in $DBS; do
    DUMP_FILE="$DUMP_DIR/$DB.$DUMP_EXT"
    $SSH_BIN $REMOTE_HOST "$POSTGRESDUMP_BIN $DB > $DUMP_FILE"
    $RSYNC_BIN $REMOTE_HOST:$DUMP_FILE .
done
