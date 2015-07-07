def case7_cancellation_response_900066342
  <<-EOF
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soap:Body>
    <OTA_CancelRS xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" EchoToken="" Version="2.1" xmlns="http://www.opentravel.org/OTA/2003/05">
      <Success />
      <UniqueID Type="501" ID="900066342" />
    </OTA_CancelRS>
  </soap:Body>
</soap:Envelope>
  EOF
end