def case7_creation_response_900066342
  <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <OTA_HotelResRS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" EchoToken="" Version="2.1" xmlns="http://www.opentravel.org/OTA/2003/05">
      <Success />
      <HotelReservations>
        <HotelReservation ResStatus="S">
          <ResGlobalInfo>
            <HotelReservationIDs>
              <HotelReservationID ResID_Type="501" ResID_Value="900066342" />
              <HotelReservationID ResID_Type="502" ResID_Value="CTP-900066342" />
            </HotelReservationIDs>
          </ResGlobalInfo>
        </HotelReservation>
      </HotelReservations>
    </OTA_HotelResRS>
  </soap:Body>
</soap:Envelope>
  EOF
end