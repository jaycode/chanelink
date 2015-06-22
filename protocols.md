## Protocol 1X
*Development Preparations*

**Protocol 1-1:**
*Preparations*
1. Download and install following apps:
  - Markdown viewer
  - Docker
  - Mysql server
  - Mysql client (HeidySQL for Windows is recommended)
2. Read `readme.md` and `testing.md`

## Protocol 2X
*Development Procedures*

**Protocol 2-1:**
*Password for my username not working after running `db:seed` on server*.

Check your email, new passwords are made and sent there when you run `db:seed`.
If emails are no good, update database directly from SQL client.

**Protocol 2-2:**
*Need to update seed data?*

The seed data (`config/seeds.sql`) can be reproduced easily by exporting sql from any sql client.

**Protocol 2-3:**
*Importing data to staging or production*

1. Export all the INSERTS (no need for DROPS and CREATE TABLES) into a file to back them up first.
2. Truncate all tables.
3. Import data.

This process takes 5 - 10 minutes.

**Protocol 2-4:**
*Updating site styles*

Run `jammit` locally before pushing the update to update css files.

## Protocol 3X
*Error Handling*

**Protocol 3-1:**
*Site shows error*
View following files: `log/staging.log`, `/var/log/nginx/error.log` and `/var/log/syslog`
by going into docker container, and running `tail -f [logfile]`

**Protocol 3-10:**
*Staging site shows "We're sorry, but something went wrong." `but log/staging.log`, `/var/log/nginx/error.log` and
`/var/log/syslog` shows nothing.*

1. Make sure site is running staging version: `cat /etc/nginx/sites-enabled/webapp.cnf` and find `passenger_app_env staging`.
2. Restart nginx: `service nginx restart` (don't worry if you see 'fail' message) while keep tailing `/var/log/nginx/error.log`
   (preferably in another terminal window).

General causes:
1. `log/staging.log` does not exist or not having right permission to write: `chmod 0666 log/staging.log`.
2. Phusion Passenger cannot allocate memory: `Cannot allocate memory - fork(2)`: See **Protocol 3-11**.

**Protocol 3-11:**
*Staging or development server shows `Cannot allocate memory - fork(2)` error in `/var/log/nginx/error.log`.*

First, find out where the memory leak happens:

`ps --sort -rss -eo rss,pid,command | head`

1. It is usually caused by `delayed_job`, so clean that process: `kill -9 [PID]`.
2. Restart NGINX: `service nginx restart`