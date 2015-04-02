FROM phusion/passenger-ruby19:0.9.15

# To avoid error "debconf: unable to initialize frontend: Dialog" causing installation to lag.
ENV DEBIAN_FRONTEND noninteractive

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# ...put your own build instructions here...

# MySQL
# ---------------------
# Install MYSQL

RUN echo "setting up MySQL..." && \
    sudo apt-get update && \
    sudo -E bash -c "apt-get -y --no-install-recommends install mysql-server > /dev/null" && \
    sudo sed -i.bak 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf && \
    # sudo chmod -R 755 /var/run/mysqld/ && \
    sudo service mysql restart && \
    sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'; FLUSH PRIVILEGES;" && \
    echo "MySQL setup completed!"
 
EXPOSE 3306
 
# Create MySQL user and database, and start it
#---------------------
RUN sudo service mysql restart && \
    CODENVY_MYSQL_PASSWORD=20jxX-9_ && \
    CODENVY_MYSQL_DB=c_development && \
    CODENVY_MYSQL_USER=c_0dlak && \
    echo "MySQL password: $CODENVY_MYSQL_PASSWORD" >> /home/app/.mysqlrc && \
    echo "MySQL user    : $CODENVY_MYSQL_USER" >> /home/app/.mysqlrc && \
    echo "MySQL Database:$CODENVY_MYSQL_DB" >> /home/app/.mysqlrc && \
    sudo mysql -uroot -e "CREATE USER '$CODENVY_MYSQL_USER'@'%' IDENTIFIED BY '"$CODENVY_MYSQL_PASSWORD"'" && \
    sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '$CODENVY_MYSQL_USER'@'%' IDENTIFIED BY '"$CODENVY_MYSQL_PASSWORD"'; FLUSH PRIVILEGES;" && \
    sudo mysql -uroot -e "CREATE DATABASE $CODENVY_MYSQL_DB;"
#---------------------

#---------------------
RUN sudo service mysql restart && \
    CODENVY_MYSQL_PASSWORD=2-dklm- && \
    CODENVY_MYSQL_DB=c_test && \
    CODENVY_MYSQL_USER=c_190kd && \
    echo "MySQL password: $CODENVY_MYSQL_PASSWORD" >> /home/app/.mysqlrc && \
    echo "MySQL user    : $CODENVY_MYSQL_USER" >> /home/app/.mysqlrc && \
    echo "MySQL Database:$CODENVY_MYSQL_DB" >> /home/app/.mysqlrc && \
    sudo mysql -uroot -e "CREATE USER '$CODENVY_MYSQL_USER'@'%' IDENTIFIED BY '"$CODENVY_MYSQL_PASSWORD"'" && \
    sudo mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO '$CODENVY_MYSQL_USER'@'%' IDENTIFIED BY '"$CODENVY_MYSQL_PASSWORD"'; FLUSH PRIVILEGES;" && \
    sudo mysql -uroot -e "CREATE DATABASE $CODENVY_MYSQL_DB;"
#---------------------

# Running NGINX Server
#---------------------
RUN rm /etc/nginx/sites-enabled/default && \
    rm -f /etc/service/nginx/down
COPY container_config/passenger/webapp.conf /etc/nginx/sites-enabled/webapp.conf
#---------------------

# Email Setup
#---------------------

# Port 587 must be opened to enable mail services.
EXPOSE 587

RUN sudo apt-get -y --no-install-recommends install telnet-ssl iptables

#---------------------

RUN mkdir -p /home/app/webapp
WORKDIR /home/app/webapp

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*