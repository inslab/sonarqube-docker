FROM ubuntu:14.04
MAINTAINER Sunchan Lee <sunchanlee@inslab.co.kr>

# Install dependencies
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get -y install unzip curl openjdk-7-jre-headless mysql-server-5.5 mysql-client
RUN cd /tmp && curl -L -O https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-5.1.2.zip && unzip sonarqube-5.1.2.zip && mv sonarqube-5.1.2 /opt/sonar

# Update SonarQube configuration
RUN sed -i 's|#sonar.jdbc.username=sonar|sonar.jdbc.username=${env:DB_USER}|g' /opt/sonar/conf/sonar.properties
RUN sed -i 's|#sonar.jdbc.password=sonar|sonar.jdbc.password=${env:DB_PASS}|g' /opt/sonar/conf/sonar.properties
RUN sed -i 's|#sonar.jdbc.url=jdbc:mysql://localhost:3306/sonar|sonar.jdbc.url=jdbc:mysql://localhost:3306/sonar|g' /opt/sonar/conf/sonar.properties
# Set context path
RUN sed -i 's/#sonar.web.context=/sonar.web.context=\/sonarqube/g' /opt/sonar/conf/sonar.properties
# Set java options
RUN sed -i 's/#sonar.web.javaOpts=-Xmx768m -XX:MaxPermSize=160m -XX:+HeapDumpOnOutOfMemoryError/sonar.web.javaOpts=-server -Xms256m -XX:+HeapDumpOnOutOfMemoryError/g' /opt/sonar/conf/sonar.properties
RUN sed -i 's/#sonar.search.javaOpts=-Xmx1G -Xms256m -Xss256k -Djava.net.preferIPv4Stack=true/sonar.search.javaOpts=-server -Xms256m -Xss256k -Djava.net.preferIPv4Stack=true/g' /opt/sonar/conf/sonar.properties
RUN sed -i 's/#  -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=75/  -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=75/g' /opt/sonar/conf/sonar.properties
RUN sed -i 's/#  -XX:+UseCMSInitiatingOccupancyOnly -XX:+HeapDumpOnOutOfMemoryError/  -XX:+UseCMSInitiatingOccupancyOnly -XX:+HeapDumpOnOutOfMemoryError/g' /opt/sonar/conf/sonar.properties

# Remove syslog configuration
RUN rm /etc/mysql/conf.d/mysqld_safe_syslog.cnf

RUN sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
RUN sed -i 's/key_buffer/key_buffer_size/g' /etc/mysql/my.cnf

# Setup mysql character to utf-8
RUN sed -i "/\[client]/a default-character-set=utf8" /etc/mysql/my.cnf
RUN sed -i "/\[mysqld]/a skip-character-set-client-handshake" /etc/mysql/my.cnf
RUN sed -i "/\[mysqld]/a collation-server=utf8_unicode_ci" /etc/mysql/my.cnf
RUN sed -i "/\[mysqld]/a character-set-server=utf8" /etc/mysql/my.cnf
RUN sed -i "/\[mysqld]/a init_connect='SET NAMES utf8'" /etc/mysql/my.cnf
RUN sed -i "/\[mysqld]/a init_connect='SET collation_connection = utf8_unicode_ci'" /etc/mysql/my.cnf
RUN sed -i "/\[mysql]/a default-character-set=utf8" /etc/mysql/my.cnf

RUN mkdir -p /tmp/sonar
RUN cp -rf /opt/sonar/extensions /tmp/sonar/
RUN cp -rf /opt/sonar/conf /tmp/sonar/
ADD start.sh /opt/sonar/bin/linux-x86-64/start.sh
RUN chmod 777 /opt/sonar/bin/linux-x86-64/start.sh

EXPOSE 9000 3306

VOLUME ["/opt/sonar/extensions", "/opt/sonar/conf", "/opt/sonar/logs", "/var/lib/mysql"]

CMD ["/opt/sonar/bin/linux-x86-64/start.sh"]
