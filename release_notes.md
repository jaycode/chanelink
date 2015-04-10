# Release Notes

## Version 0.1 (latest)

No system changes here, just focusing on adding some very critical test cases and adding Ctrip channel.

property_channels table has been updated to use "settings" field instead where we put in our OTA settings instead of adding new fields everytime. This won't change the system for existing OTAs (Agoda and Booking.com) but will affect Ctrip and future OTAs.

To upgrade, run `bundle exec rake:db migrate` on production server.

List of channel integration tests made:

1. `channel_creation_test`
2. `channel_approval_test`

Most of the work at this version was directed towards system preparation. Admittedly most times went to learning Dockerized environment.