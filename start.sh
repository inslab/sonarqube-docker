#!/bin/bash

mysql_install_db --user mysql > /dev/null

cat > /opt/sonar/bin/linux-x86-64/createdb.sql <<EOF
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
UPDATE user SET password=PASSWORD("$DB_PASS") WHERE user='root';

CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER' IDENTIFIED BY '$DB_PASS';
GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASS';
FLUSH PRIVILEGES;
EOF

mysqld --bootstrap --verbose=0 < /opt/sonar/bin/linux-x86-64/createdb.sql

mysqld_safe --user=mysql &

if [ ! -d "/opt/sonar/extensions/plugins" ]; then
    echo "Copying plugins..."
    cp -rf /tmp/sonar/extensions /opt/sonar/
    rm -rf /tmp/sonar/extensions
    cd /opt/sonar/extensions/plugins && \
        curl -O http://downloads.sonarsource.com/plugins/org/codehaus/sonar-plugins/sonar-ldap-plugin/1.4/sonar-ldap-plugin-1.4.jar
fi

if [ ! -f "/opt/sonar/conf/sonar.properties" ]; then
    echo "Copying configuration..."
    cp -rf /tmp/sonar/conf /opt/sonar/
fi

if [ -n "$LDAP_URI" ] && [ -n "$LDAP_BASE_DN" ]
then
    echo "--> LDAP setting..."
    CONF_FILE=/opt/sonar/conf/sonar.properties
    sed -i '/^sonar.security.realm/d' $CONF_FILE
    sed -i '/^sonar.security.savePassword/d' $CONF_FILE
    sed -i '/^ldap.url/d' $CONF_FILE
    sed -i '/^ldap.user/d' $CONF_FILE
    sed -i '/^ldap.group/d' $CONF_FILE
    echo -e "\n\n" >> $CONF_FILE
    echo "sonar.security.realm=LDAP" >> $CONF_FILE
    echo "sonar.security.savePassword=false" >> $CONF_FILE
    echo "ldap.url=$LDAP_URI" >> $CONF_FILE
    echo "ldap.user.baseDn=$LDAP_BASE_DN" >> $CONF_FILE
    echo "ldap.user.request=(&(objectClass=PosixAccount)(uid={login}))" >> $CONF_FILE
    echo "ldap.user.realNameAttribute=cn" >> $CONF_FILE
    echo "ldap.user.emailAttribute=mail" >> $CONF_FILE
else
    echo "Skip LDAP setting..."
fi

/opt/sonar/bin/linux-x86-64/sonar.sh console