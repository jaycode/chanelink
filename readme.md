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
2. Setup configuration:
 - Check file /container_config/passenger/webapp.conf. Change rails environment here when needed.
 - Create MySQL user and database by entering correct information through /webapp/Dockerfile.
3. Build docker container:
    ```
    cd /c/Users/Path/to/project
    docker build -t jaycode/chink .
    ```
4. Run docker with following command:
    ```
    docker run -d -p 80:80 -p 3306:3306 -p 587:587 --privileged -v /c/Users/Path/to/project:/home/app jaycode/chink
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
    # Install all required gems, Start mysql sever, Run the migration
    bundle install && service mysql restart && bundle exec rake db:migrate

    # Run delayed jobs
    script/delayed_job start
    ```
6. After initialising for the first time, you may want to store your container as an image,
so you do not need to bundle install everytime you run it. For this, do the following:
    ```
    # You can get container ID from "docker ps".
    docker commit -m "Initialised" ID jaycode/chink:v0.1
    ```

    That command stores your created container into image "jaycode/chink:v0.1". From now on,
    you may run that image to get your app to current stage. To test this, feel free to remove
    the currently running docker container (docker stop ID && docker rm ID) then run the following:
    ```
    docker run -d -p 80:80 -v /c/Users/Path/to/project:/home/app jaycode/chink:v0.1
    ```

    If you get mysql socket connection error, run the following:
    ```
    # You can get container ID from "docker ps".
    docker exec ID bash "service mysql restart"
    ```

7. Your server should be up and running now.


## Development Notes

This part contains all the useful notes for development of Chanelink app.

### Connecting to Docker's MySQL server
```
host: IP
port: 3306
```
Username and password are the same with what you already set in Dockerfile.

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

### Rails Testing

To run tests in Rails, use this command:

```
rake test
```

### Inspecting the status of your web app

---
_Taken from https://github.com/phusion/passenger-docker._

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
