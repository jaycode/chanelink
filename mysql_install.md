# MySQL Installation and setup


## How to Install MYSQL

**Note:** In 512Mb server you need to turn off other services prior to installation.
```
sudo apt-get update
sudo apt-get install mysql-server
sudo sed -i.bak 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
```

Connect to your mysql server with command `mysql -u root -p`.

In publicly viewable servers, rename root user for more security. To do this, first login with `mysql -u root` then run the following commands from within.

```
USE mysql;
UPDATE mysql.user SET User='c_2mcod' WHERE User='root';
```

## User Creation

The better practice in dockerized app is to have app within the container contact to database server in host. To do this, you basically needs to create a user with IP address of your docker container.

To find IP address of your docker container:

```
docker inspect [ID] | grep IPAddress
```

IP address changes when you recreate the docker container, so it may be preferable to have a wildcard in the ip address i.e. if the
ip address is 172.17.0.8 then create a user with IP 172.17.0.%.

Sample of user creation query:

```
MYSQL_PASSWORD=2190j1jsKal && \
MYSQL_DB=chanelink_production && \
MYSQL_USER=c_2mcod && \
MYSQL_IP=172.17.0.% && \
sudo mysql -u c_2mcod -p -e "CREATE USER '$MYSQL_USER'@'$MYSQL_IP' IDENTIFIED BY '"$MYSQL_PASSWORD"'" && \
sudo mysql -u c_2mcod -p -e "GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'$MYSQL_IP' IDENTIFIED BY '"$MYSQL_PASSWORD"'; FLUSH PRIVILEGES;"
```