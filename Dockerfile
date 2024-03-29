FROM phusion/passenger-ruby19:0.9.15

# Installing MySql client, but no need for server
#---------------------
RUN sudo apt-get update && \
sudo apt-get -y install mysql-client
#---------------------

# To avoid error "debconf: unable to initialize frontend: Dialog" causing installation to lag.
ENV DEBIAN_FRONTEND noninteractive

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# ...put your own build instructions here...

# Running NGINX Server
#---------------------
RUN rm /etc/nginx/sites-enabled/default && \
    rm -f /etc/service/nginx/down
COPY container_config/nginx/webapp.conf /etc/nginx/sites-enabled/webapp.conf
#---------------------

# Bundle Install
#---------------------
ADD webapp/Gemfile .
RUN bundle install
#---------------------

# Installing Firefox for Selenium module used in Rails testing
#---------------------
# RUN sudo apt-get -y --no-install-recommends install firefox
#---------------------

RUN mkdir -p /home/app/webapp
WORKDIR /home/app/webapp

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# This makes sure mysql can only be accessed locally. See readme.md for adding more IP addresses for remote access.
# But maybe better stop port 3306 from being accessed from outside...

# sudo apt-get update && sudo apt-get -y --no-install-recommends install iptables && /sbin/iptables -A INPUT -p tcp --dport 3306 -j DROP && apt-get clean