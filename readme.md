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
 - Check file /container_config/passenger/webapp.conf. Change rails environment here when needed.
 - Create MySQL user and database by entering correct information through /webapp/Dockerfile.
3. Build docker container:
    ```
    cd /c/Users/Path/to/project
    ```
    ```
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
    # Install all required gems, Start mysql sever, Run the migration, then seed the database.
    bundle install && service mysql restart && bundle exec rake db:migrate && bundle exec rake db:seed

    # Run delayed jobs
    ruby script/delayed_job start
    ```
6. After initialising for the first time, you may want to store your container as an image,
so you do not need to bundle install everytime you run it. For this, do the following:
    ```
    # You can get container ID from `docker ps`.
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

You can connect to MySQL server in Docker container from any MySQL client app by directly
connecting to host `IP` and port `3306` (You can get IP from running `boot2docker ip`).

Username and password are the same with what you already set in Dockerfile.

### Seeding the database

Seeding the database is done by running `bundle exec rake db:seed`. This will run the script
`db/seeds.rb`.

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
bundle exec rake test

# Running only unit tests
bundle exec rake test:units

# Running only functional tests
bundle exec rake test:functionals

# Running only integration tests
bundle exec rake test:integration

# Or to run specific test files:
bundle exec rake test:functionals TEST=test/functional/sessions_controller_test.rb
# I know that is weird, you need to actually specify whether that file is located
# under ":units", ":functionals", or ":integration", otherwise your test will run
# three times.
```

Read more about running specific tests [here](http://flavio.castelli.name/2010/05/28/rails_execute_single_test/)

#### Using cookies in test code

Instead of `cookies[:something]`, use `@request.cookie_jar[:something]`, because the latter allows you
to use permanent and signed featuress (i.e. it is an object instead of hash).

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

### Pushing to production 

## Useful Resources & Tips

To learn about this application's code, I suggest you start from reviewing test code `test/member_test.rb` as I put all 
detailed comments aimed at Rails beginners there. After learning from that code you may move on to other test files to
understand how the app is structured.

Please add Test code for features you find harder to understand, or to find possible bugs.

Most guides are available at [Rails Guides](http://guides.rubyonrails.org/v3.2.21/). When things are not available, it is most likely
caused by different rails version. In that case Google is your friend.

We use fixtures to help us with testing, learn about them [here](http://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html).

Don't be afraid to read core code. Rails 3.0.3 is available [here](https://github.com/rails/rails/tree/3-0-stable).
