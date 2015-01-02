#!/bin/bash

echo '=============================='
echo 'create database '${DB_NAME} > /opt/sonar/bin/linux-x86-64/createdb.sql
cat /opt/sonar/bin/linux-x86-64/createdb.sql

mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USERNAME} -p${DB_PASSWORD} < /opt/sonar/bin/linux-x86-64/createdb.sql

if [ ! -d "/opt/sonar/extensions/plugins" ]; then
	mv /tmp/sonar/* /opt/sonar/extensions
fi

/opt/sonar/bin/linux-x86-64/sonar.sh console

