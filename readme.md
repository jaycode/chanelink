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
    - Check file /container_config/nginx/webapp.conf. (for different server, create a copy of webapp.conf.default and rename it to webapp.conf) Change rails environment here when needed e.g. to change environment from "development" to "production" you may run the following:
    
    ```
    sed -i.bak 's/development/production/g' container_config/nginx/webapp.conf
    ```
    
    Later on when you wish to change configuration environment, in addition to that you need to: `cp container_config/nginx/webapp.conf /etc/nginx/sites-enabled/webapp.conf`.

    - Create MySQL user and database by entering correct information through /Dockerfile.

3. Build docker container:
    ```
    cd /c/Users/Path/to/project && sudo docker build -t chink/main .
    ```

4. Run docker with following command:
    First get host ip, we need this to connect to mysql server, then run the image, as follows:

    **On local environment i.e. host server ports may not be opened to the network.**

    ```
    alias hostip="ip route show 0.0.0.0/0 | grep -Eo 'via \S+' | awk '{ print \$2 }'"
    docker run -d -p 80:80 -p 443:443 --add-host=docker:$(hostip) -v /c/Users/Path/to/project:/home/app chink/main
    ```

    **In Staging and Production Server, run the following:**
    
    ```
    docker run -d -p 80:80 -p 443:443 -v /apps/ChanelinkProduction:/home/app chink/main
    ```

    **Notes:**

    In Staging and Production Server, --add-host=docker:IP somehow does not allow access

    `-v /c/Users/Path/to/project:/home/app` will synchronize (mount) dir `/c/Users/Path/to/project` in host to this path in our container: `/home/app`.

    You may then access the app on http://IP where IP is the value you may get from running this command in a (non-boot2docker) terminal: `boot2docker ip`
    
    `--privileged` option gives complete host access to the container, allowing you to use telnet from within the app to test out email service.

5. Now we need to setup our database. In our docker setup, database is installed at host and the app within
   docker container would access it remotely. To do this, you will need:
   - MySQL Database installed and enabled in your host.
   - A database user for the container's IP created.

   Please refer to [mysql_install.md](https://github.com/jaycode/chanelink/blob/master/mysql_install.md) for detailed info on how to setup mysql and create user in fresh Linux server.

6. Finishing up container setup.

    ```
    # Find the id of running container with this command.
    docker ps
    
    # Run the following to access your container
    # You only need to include the first fiew ID characters e.g. docker exec -i -t f8f bash
    docker exec -i -t [ID] bash
    ```

    Then inside your docker container:
    ```
    # Install all required gems, Run the migration, then seed the database.
    bundle install && bundle exec rake db:migrate && bundle exec rake db:seed

    # Run delayed jobs
    chmod 655 script/delayed_job
    script/delayed_job start

    # OR for different environment:
    # RAILS_ENV=production script/delayed_job start
    ```

    Or in Production:
    ```
        bundle install && bundle exec rake db:migrate RAILS_ENV=production && bundle exec rake db:seed RAILS_ENV=production
    ```

    **Notes:**

    When you get error `* /etc/init.d/mysql: ERROR: The partition with /home/app/data/mysql is too full!`
    copy all files from `/var/lib/mysql` to `/home/app/data/` i.e. following command:

    ```
    sudo cp -r /var/lib/mysql /home/app/data
    ```

    When you get `fail` error when running `sudo service mysql start` you may `cat /var/log/mysql/error.log` to see what went wrong.

7. After initialising for the first time, you may want to store your container as an image,
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

8. Your server should be up and running now.



## Development Notes

This part contains all the useful notes for development of Chanelink app.

### Connecting to server's MySQL server

Use SSH connection to database.

### Seeding the database

Seeding the database is done by running `bundle exec rake db:seed`. This will run the script
`db/seeds.rb`.

### Testing

Testing plays a big part in the development of Chanelink app that it needs
its own page:

[READ THIS PAGE TO LEARN ABOUT TESTING CHANELINK APP](https://github.com/jaycode/chanelink/blob/master/testing.md)

### Testing Emails

Testing if app's emailing feature is working can be done by:

**1. Running rails console app.**

```
bundle exec rails console

# for staging:
bundle exec rails console staging
```

**2. Then send a test message from that console.**
```
Notifier.email_member_password('testpass', Member.find_by_email('email@example.com')).deliver
```

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

### Logging
If anything goes wrong, consult the log files in /var/log. The following log files are especially important:

- /var/log/nginx/error.log
- /var/log/syslog
- Your app's log file in `/apps/ChanelinkProduction/webapp`.

When error not found, sometimes you need to restart your web server by running `service restart nginx` then
try accessing your app from browser again, then consult the log files.

### Delayed Jobs
Delayed jobs are used to move app-related tasks to background process. We need this in this project to work with
emails and xml passing to OTAs.

Before running delayed job script, make sure to `chmod 655 script/delayed_job`.

Some commands:

```
# To check if delayed job is running:
script/delayed_job status

# To destroy delayed job:
script/delayed_job stop
```

Additionally, you can check the database in table `delayed_jobs` for queued jobs.

## Pushing to production / staging

Going outside the development realm and to actually putting things into production does introduce additional complexities e.g. how do we pull the data, What if we have additional rows in the database, among other issues.

There are a couple of things you need to do when pushing to production / staging:

1. Pull data in production / staging server with `git pull origin master`.
2. (Only when you have changed Gemfile) `bundle install`.
3. `rake db:migrate && rake db:seed`.
4. Compress css and javascripts with Jammit compression i.e. run `jammit` on server.
5. Restart the app by running `touch /apps/ChanelinkProduction/webapp/tmp/restart.txt`.
6. (Only initially) make sure delayed_job is running with `script/delayed_job status`.

### How to pull data in production / staging server.

SSH connect to server, then:

```
cd /apps/ChanelinkProduction
git pull origin master
touch webapp/tmp/restart.txt
```

If there are files (accidentally) changed on server, you could either commit the changes and pull in local, or remove those changes.
You would usually notice this when the server is unable to do `git pull origin master`.

To review uncommitted changed, run:
```
git status
```

Then when you are sure the changes were accidental and wish to revert back, run:
```
git reset --hard
```

### How to update table schema and adding new rows.

Add `RAILS_ENV` directive to your rake command i.e.

```
bundle exec rake db:migrate RAILS_ENV=production && bundle exec rake db:seed RAILS_ENV=production
```

Updating table schema must be done via migrations, consult the Rails documentation for this. As far as naming, you can use whatever works for you as long as it explains what you are doing there.

**note:** Do not update old migration files! To fix older migration files, create newer migrations instead.

Adding rows / entities on the other hand, MUST NOT be done via migration files. You need to update `db/seeds.rb` file to include entity creations there. Don't forget to either remove or skip any duplication. Check the file `db/seeds.rb` for examples.

Doing the above would ensure both `bundle exec rake db:migrate` and `bundle exec rake db:seed` are safe to run on production server.

## Useful Resources & Tips

To learn about this application's code, I suggest you start from reviewing test code `test/member_test.rb` as I put all 
detailed comments aimed at Rails beginners there. After learning from that code you may move on to other test files to
understand how the app is structured.

Please add Test code for features you find harder to understand, or to find possible bugs.

Most guides are available at [Rails Guides](http://guides.rubyonrails.org/v3.2.21/). When things are not available, it is most likely
caused by different rails version. In that case Google is your friend.

Don't be afraid to read core code. Rails 3.0.3 is available [here](https://github.com/rails/rails/tree/3-0-stable).

When you find something you want to add later, write `# Todo` comment on it. RubyMine will pick up any todo items and we can view them as list.

---

# Testing Strategy

**Channel**
1. Test if channel can be created.

**Inventory**

1. Test if inventory can be added.
2. Connect to OTA through Storm SOAP to see if it is updated alright.
3. Connect to OTA through app by writing [Channel]RoomTypeFetcher class.
Test out code `CtripChannel.first.room_type_fetcher.retrieve(current_property, false)` with Unit Testing.
4. Setup endpoints in `app_config.yml`.

For prices to be shown in inventories page, following tables must be filled:
- properties
- pools
- room_types
- room_type_master_rate_mappings - Needed so master rate inputs can be edited.
  Todo: maybe make it so master rate inputs can be edited without having to create an
        entry in this table?
- room_type_master_rate_channel_mappings - children of room_type_master_rate_mappings.
  Todo: room_type_id seems redundant here.

With above tables, prices and availabilities for rooms should already be shown,
and now we link them to channels by filling in following tables:
- channels
- room_type_channel_mappings - In here we include room related data from OTAs.
- property_channels

Room linked with another room, i.e. similar Superior rooms, but one with breakfast,
can be added by adding data to this table:
- room_type_inventory_links 

Data is entered at table inventories.

**Sending Rates Data to OTA**
When saving rates, data is sent to OTA via [master or channel]_rate_handler. See
`master_rates_controller.rb`, the part where the code shows `MasterRateChangeSet.create_job(logs, @pool)`.