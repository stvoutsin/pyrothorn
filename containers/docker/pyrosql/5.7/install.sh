#!/bin/bash

# start mysql server as a background process so we can modify it
mysqld --datadir=/var/lib/mysql --user=mysql &

# wait for mysqld to start
counter=0
while (( ${counter} < "30" )); do
    let counter=counter+1
    mysql_status="$(mysql -N -B -uroot -hlocalhost -e "SELECT 'ready';" 2> /dev/null)"
    if [[ ${mysql_status} == "ready" ]]; then break; fi
    sleep 1s
done

# error if db doesn't come up
if [[ ${mysql_status} != "ready" ]]; then 
  echo "Database did not start within 30 seconds"
  exit 1
fi

# Perform custom operations to create and populate database. liquibase or flyway > command line mysql


mysql -hlocalhost -uroot -e "CREATE DATABASE pyrothorn_testing;"
mysql -hlocalhost -uroot -Dpyrothorn_testing -e "CREATE TABLE IF NOT EXISTS queries (
  queryid int(10) unsigned NOT NULL AUTO_INCREMENT,
  queryrunID text NOT NULL,
  query_hash text NOT NULL,
  query_count int(10) unsigned NOT NULL,
  query_timestamp varchar(120) NOT NULL,
  query text NOT NULL,
  direct_sql_rows int(11) NOT NULL,
  firethorn_sql_rows int(11) NOT NULL,
  firethorn_duration varchar(60) NOT NULL,
  sql_duration varchar(60) NOT NULL,
  test_passed tinyint(1) NOT NULL,
  firethorn_version varchar(60) NOT NULL,
  firethorn_error_message text NOT NULL,
  sql_error_message text NOT NULL,
  java_version varchar(120) NOT NULL,
  sys_timestamp varchar(60) NOT NULL,
  firethorn_changeset varchar(60) NOT NULL,
  sys_platform varchar(60) NOT NULL,
  PRIMARY KEY (queryid)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=1 ;"


# shut down mysqld
mysqladmin -uroot shutdown

exit 0
