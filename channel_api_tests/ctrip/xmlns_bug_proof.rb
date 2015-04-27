# This script proves bug within xml returned from http://58.221.127.196:8090/Hotel/OTAReceive/HotelRatePlan.asmx
# Basically the attribute xmlns within OTA_HotalRatePlanRS node caused the entire XML unreadable,
# at least from the popular Ruby module Nokogiri.
require 'rubygems'
require 'nokogiri'

# x1 contains xml with OTA_HotelRatePlanRS node having all attributes.
# With this, Nokogiri can't reach Test node with xpath.
x1 = '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body>
<OTA_HotelRatePlanRS xmlns="http://www.opentravel.org/OTA/2003/05" TimeStamp="2015-04-27T11:30:54.3677172+08:00" Version="2.1" PrimaryLangID="en-us">
<Test value="testvalue" /></OTA_HotelRatePlanRS></soap:Body></soap:Envelope>'
xdoc1 = Nokogiri::XML(x1)
puts xdoc1.xpath("//OTA_HotelRatePlanRS").inspect # Should return empty.

# x2 contains xml with OTA_HotelRatePlanRS node not given any attribute.
# With this, Nokogiri managed to reach Test node with xpath.
x2 = '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body>
<OTA_HotelRatePlanRS>
<Test value="testvalue" /></OTA_HotelRatePlanRS></soap:Body></soap:Envelope>'
xdoc2 = Nokogiri::XML(x2)
puts xdoc2.xpath("//OTA_HotelRatePlanRS").inspect # Should return empty.

# x3 contains xml with OTA_HotelRatePlanRS node have all attributes except for xmlns.
# With this, Nokogiri still able to reach Test node with xpath so it can be concluded
# that xmlns attribute caused this issue.
x3 = '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body>
<OTA_HotelRatePlanRS TimeStamp="2015-04-27T11:30:54.3677172+08:00" Version="2.1" PrimaryLangID="en-us">
<Test value="testvalue" /></OTA_HotelRatePlanRS></soap:Body></soap:Envelope>'
xdoc3 = Nokogiri::XML(x3)
puts xdoc3.xpath("//OTA_HotelRatePlanRS").inspect # Should return empty.
