FROM ubuntu:14.04
MAINTAINER Sunchan Lee <sunchanlee@inslab.co.kr>

# Install dependencies
RUN apt-get update
RUN apt-get -y install unzip curl openjdk-7-jre-headless mysql-client
RUN cd /tmp && curl -L -O https://sonarsource.bintray.com/Distribution/sonarqube/sonarqube-5.1.2.zip && unzip sonarqube-5.1.2.zip && mv sonarqube-5.1.2 /opt/sonar

# Update SonarQube configuration
#RUN sed -i 's|#wrapper.java.additional.7=-server|wrapper.java.additional.7=-server|g' /opt/sonar/conf/wrapper.conf
RUN sed -i 's|#sonar.jdbc.username=sonar|sonar.jdbc.username=${env:DB_USERNAME}|g' /opt/sonar/conf/sonar.properties
RUN sed -i 's|#sonar.jdbc.password=sonar|sonar.jdbc.password=${env:DB_PASSWORD}|g' /opt/sonar/conf/sonar.properties
#RUN sed -i 's|sonar.jdbc.url=jdbc:h2|#sonar.jdbc.url=jdbc:h2|g' /opt/sonar/conf/sonar.properties
RUN sed -i 's|#sonar.jdbc.url=jdbc:mysql://localhost:3306/sonar|sonar.jdbc.url=jdbc:mysql://${env:DB_HOST}:${env:DB_PORT}/${env:DB_NAME}|g' /opt/sonar/conf/sonar.properties
# Set context path
RUN sed -i 's/#sonar.web.context=/sonar.web.context=\/sonarqube/g' /opt/sonar/conf/sonar.properties

RUN mkdir -p /tmp/sonar
RUN cp -rf /opt/sonar/extensions /tmp/sonar/
RUN cp -rf /opt/sonar/conf /tmp/sonar/
ADD start.sh /opt/sonar/bin/linux-x86-64/start.sh
RUN chmod 777 /opt/sonar/bin/linux-x86-64/start.sh

EXPOSE 9000

VOLUME ["/opt/sonar/extensions", "/opt/sonar/conf"]
CMD ["/opt/sonar/bin/linux-x86-64/start.sh"]

