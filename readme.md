# Chanelink App

Feel free to update this document as you found new things worth documenting.

## Directories
- webapp:
 - Our application resides here.
- data:
 - Database of our application is stored here.
- container_config:
 - Configurations for our container are stored here.

## Setup Direction

1. Install Docker to your server.
   Now, installing Docker is not as simple as it may sound. Here is what we did:
   1. Uninstall Git
   2. Install Docker, tick both Git and VM.
   3. If you're on Windows machine, [enable Intel VT and V Virtualization hardware extensions in BIOS](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Virtualization_Administration_Guide/sect-Virtualization-Troubleshooting-Enabling_Intel_VT_and_AMD_V_virtualization_hardware_extensions_in_BIOS.html) and [disable Hyper V feature](https://pricklytech.wordpress.com/2014/02/25/windows-8-1-vmware-player-and-hyper-v-are-not-compatible/).
2. Setup configuration:
    - Check file /container_config/passenger/webapp.conf. (for different server, create a copy of webapp.conf.default and rename it to webapp.conf) Change rails environment here when needed e.g. to change environment from "development" to "production" you may run the following:
    
    ```
    sed -i.bak 's/development/production/g' container_config/passenger/webapp.conf
    ```
    
    - Create MySQL user and database by entering correct information through /Dockerfile.

3. Build docker container:
    ```
    cd /c/Users/Path/to/project && sudo docker build -t chink/main .
    ```
4. Run docker with following command:
    ```
    docker run -d -p 80:80 -p 3306:3306 -p 587:587 --privileged -v /c/Users/Path/to/project:/home/app chink/main
    ```

    **Notes:**

    `-v /c/Users/Path/to/project:/home/app` will synchronize (mount) dir `/c/Users/Path/to/project` in host to this path in our container: `/home/app`.

    You may then access the app on http://IP where IP is the value you may get from running this command in a (non-boot2docker) terminal: `boot2docker ip`

    `-p 3306:3306` links the container's mysql database port `3306` with host's. `docker ps` can be used to view if the ports are correctly linked.
    
    `-p 587:587` is needed to open port to Zoho's email server so the app can send emails from within container.
    
    `--privileged` option gives complete host access to the container, allowing you to use telnet from within the app to test out email service.

5. Now we need to setup our database. First, connect to container's bash in (boot2docker) terminal:

    ```
    # Find the id of running container with this command.
    docker ps
    
    # Run the following to access your container
    # You only need to include the first fiew ID characters e.g. docker exec -i -t f8f bash
    docker exec -i -t [ID] bash
    ```

    Then inside your docker container:
    ```
    # Install all required gems, Start mysql sever, Run the migration, then seed the database.
    bundle install && sudo service mysql restart && bundle exec rake db:migrate && bundle exec rake db:seed

    # Run delayed jobs
    mkdir tmp && ruby script/delayed_job start
    ```

    **Notes:**

    When you get error `* /etc/init.d/mysql: ERROR: The partition with /home/app/data/mysql is too full!`
    copy all files from `/var/lib/mysql` to `/home/app/data/` i.e. following command:

    ```
    sudo cp -r /var/lib/mysql /home/app/data
    ```

    When you get `fail` error when running `sudo service mysql start` you may `cat /var/log/mysql/error.log` to see what went wrong.

6. After initialising for the first time, you may want to store your container as an image,
so you do not need to bundle install everytime you run it. For this, do the following:
    ```
    # You can get container ID from `docker ps`.
    docker commit -m "Initialised" ID chink/main:v0.1
    ```

    That command stores your created container into image "chink/main:v0.1". From now on,
    you may `run` that image to get your app to current stage.

    If you get mysql socket connection error, run the following:
    ```
    # You can get container ID from "docker ps".
    docker exec ID bash "service mysql restart"
    ```

7. Your server should be up and running now.



## Development Notes

This part contains all the useful notes for development of Chanelink app.

### Connecting to Docker's MySQL server

You can connect to MySQL server in Docker container from any MySQL client app by directly
connecting to host `IP` and port `3306` (You can get IP from running `boot2docker ip`).

#### Connecting to local Docker container's MySQL server

Since it is local anyway, you may allow any connection to your Docker container. Run the following:

```
iptables -F
```

Then you can connect with username `root` without password.

#### Connecting to remote Docker container's MySQL server

Username and password are the same with what you already set in Dockerfile.

You need to include your ip in the whitelist of iptables before the container will allow you to connect.

To create new remote client access, do all the commands below (in that order)

```
/sbin/iptables -A INPUT -p tcp -s 139.192.80.71 --dport 3306 -j ACCEPT
/sbin/iptables -A INPUT -p tcp -s 139.195.126.19 --dport 3306 -j ACCEPT
## Block all connections to 3306 ##
/sbin/iptables -A INPUT -p tcp --dport 3306 -j DROP
```

To drop all rules, e.g. before adding a new ip:

```
iptables -F
```

To see all clients:

```
echo -e "target     prot opt source               destination\n$(iptables -L INPUT -n | grep 3306)"
```

### Seeding the database

Seeding the database is done by running `bundle exec rake db:seed`. This will run the script
`db/seeds.rb`.

### Testing

Testing plays a big part in the development of Chanelink app that it needs
its own page:

[READ THIS PAGE TO LEARN ABOUT TESTING CHANELINK APP](https://github.com/jaycode/chanelink/blob/master/testing.md)

### Routing

All routes must be defined at `config/routes.rb`.

Read more about Routing in Rails [here](http://guides.rubyonrails.org/v3.2.21/routing.html).

### Logging

Log files are available in directory log/[environment].log.

To write to log files, use this in your code:

```
logger.debug "some message"
```

If you need separate log file you could use like this:

```
# You only need to do it once across all code.
# @ means this object is globally available through our app (after it is initialized, that is).
@logger = Logger.new("#{Rails.root}/log/custom.log")
@logger.error("some message")
```

### Asset Packaging

Chanelink uses the Jammit gem (http://documentcloud.github.io/jammit/) to pre-package its assets.
By packaging assets, all css and javascripts are compressed, improving overall site's speed.

To pack assets, run the following:

```
jammit
```

inside the container, or from outside the container it can be run as follows:
```
docker exec ID bash -c "jammit"
```
---

### Inspecting the status of your web app

---
*This note and everything underneath were shamelessly taken from https://github.com/phusion/passenger-docker.*

---

If you use Passenger to deploy your web app, run:
```
passenger-status
passenger-memory-stats
```

### Logs
If anything goes wrong, consult the log files in /var/log. The following log files are especially important:

- /var/log/nginx/error.log
- /var/log/syslog
- Your app's log file in /home/app.

## Pushing to production

Going outside the development realm and to actually putting things into production does introduce additional complexities e.g. how do we pull the data, What if we have additional rows in the database, among other issues.

### How to update table schema and adding new rows.

Updating table schema must be done via migrations, consult the Rails documentation for this. As far as naming, you can use whatever works for you as long as it explains what you are doing there.

**note:** Do not update old migration files! To fix older migration files, create newer migrations instead.

Adding rows / entities on the other hand, MUST NOT be done via migration files. You need to update `db/seeds.rb` file to include entity creations there. Don't forget to either remove or skip any duplication. Check the file `db/seeds.rb` for examples.

Doing this guide would ensure both `bundle exec rake db:migrate` and `bundle exec rake db:seed` are safe to run on production server.

## Useful Resources & Tips

To learn about this application's code, I suggest you start from reviewing test code `test/member_test.rb` as I put all 
detailed comments aimed at Rails beginners there. After learning from that code you may move on to other test files to
understand how the app is structured.

Please add Test code for features you find harder to understand, or to find possible bugs.

Most guides are available at [Rails Guides](http://guides.rubyonrails.org/v3.2.21/). When things are not available, it is most likely
caused by different rails version. In that case Google is your friend.

Don't be afraid to read core code. Rails 3.0.3 is available [here](https://github.com/rails/rails/tree/3-0-stable).

When you find something you want to add later, write `# Todo` comment on it. RubyMine will pick up any todo items and we can view them as list.
