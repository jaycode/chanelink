def case10_response_900066252
  <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <OTA_HotelResRS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" EchoToken="" Version="2.1" xmlns="http://www.opentravel.org/OTA/2003/05">
      <Errors>
        <Error ShortText="MD5 string check fails in reservation" Type="3" Code="242"/>
      </Errors>
      <HotelReservations>
        <HotelReservation ResStatus="R">
          <ResGlobalInfo>
            <HotelReservationIDs>
              <HotelReservationID ResID_Value="900066252" ResID_Type="501"/>
            </HotelReservationIDs>
          </ResGlobalInfo>
        </HotelReservation>
      </HotelReservations>
    </OTA_HotelResRS>
  </soap:Body>
</soap:Envelope>
  EOF
end