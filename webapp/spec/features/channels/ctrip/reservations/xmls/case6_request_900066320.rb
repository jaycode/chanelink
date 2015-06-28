def case6_request_900066320
  <<-EOF
<?xml version="1.0" ?>
  <SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Header/>
  <SOAP-ENV:Body><OTA_CancelRQ Version="2.0" xmlns="http://www.opentravel.org/OTA/2003/05">
    <POS>
      <Source>
        <RequestorID ID="" Type="5" MessagePassword="">
          <CompanyName Code="C" CodeContext="600" />
        </RequestorID>
      </Source>
    </POS>
    <UniqueID ID="900066320" Type="501" />
    <UniqueID ID="54394" Type="10" />
  </OTA_CancelRQ>
 </SOAP-ENV:Body>
   </SOAP-ENV:Envelope>
  EOF
end