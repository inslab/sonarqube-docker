FROM ubuntu:14.04
MAINTAINER Sunchan Lee <sunchanlee@inslab.co.kr>

# Install dependencies
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get -y install unzip curl openjdk-7-jre-headless mysql-server-5.5 mysql-client
RUN cd /tmp && curl -L -O https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-5.1.2.zip && unzip sonarqube-5.1.2.zip && mv sonarqube-5.1.2 /opt/sonar

# Update SonarQube configuration
#RUN sed -i 's|#wrapper.java.additional.7=-server|wrapper.java.additional.7=-server|g' /opt/sonar/conf/wrapper.conf
RUN sed -i 's|#sonar.jdbc.username=sonar|sonar.jdbc.username=${env:DB_USER}|g' /opt/sonar/conf/sonar.properties
RUN sed -i 's|#sonar.jdbc.password=sonar|sonar.jdbc.password=${env:DB_PASS}|g' /opt/sonar/conf/sonar.properties
#RUN sed -i 's|sonar.jdbc.url=jdbc:h2|#sonar.jdbc.url=jdbc:h2|g' /opt/sonar/conf/sonar.properties
RUN sed -i 's|#sonar.jdbc.url=jdbc:mysql://localhost:3306/sonar|sonar.jdbc.url=jdbc:mysql://${env:DB_HOST}:${env:DB_PORT}/${env:DB_NAME}|g' /opt/sonar/conf/sonar.properties
# Set context path
RUN sed -i 's/#sonar.web.context=/sonar.web.context=\/sonarqube/g' /opt/sonar/conf/sonar.properties

# Remove syslog configuration
RUN rm /etc/mysql/conf.d/mysqld_safe_syslog.cnf

RUN sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
RUN sed -i 's/key_buffer/key_buffer_size/g' /etc/mysql/my.cnf

RUN mkdir -p /tmp/sonar
RUN cp -rf /opt/sonar/extensions /tmp/sonar/
RUN cp -rf /opt/sonar/conf /tmp/sonar/
ADD start.sh /opt/sonar/bin/linux-x86-64/start.sh
RUN chmod 777 /opt/sonar/bin/linux-x86-64/start.sh

EXPOSE 9000 3306

VOLUME ["/opt/sonar/extensions", "/opt/sonar/conf", "/var/lib/mysql"]

CMD ["/opt/sonar/bin/linux-x86-64/start.sh"]