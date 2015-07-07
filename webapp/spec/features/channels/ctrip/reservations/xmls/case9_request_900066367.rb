def case9_request_900066367(date, rtcm)
  <<-EOF
<?xml version="1.0" ?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Header/>
  <SOAP-ENV:Body>
    <OTA_HotelResRQ Version="2.1" EchoToken="201408220919" xmlns="http://www.opentravel.org/OTA/2003/05">
      <POS>
        <Source>
          <RequestorID ID="" Type="5" MessagePassword="">
            <CompanyName Code="C" CodeContext="600" />
          </RequestorID>
        </Source>
      </POS>
      <UniqueID ID="900066367" Type="501" />
      <HotelReservations>
        <HotelReservation>
          <RoomStays>
            <RoomStay>
              <RatePlans>
                <RatePlan RatePlanCode="#{rtcm.ota_room_type_id}">
                  <RatePlanDescription>
                    <Text Language="en-us" TextFormat="PlainText">Superior(CNY Promo)</Text>
                  </RatePlanDescription>
                </RatePlan>
              </RatePlans>
              <BasicPropertyInfo HotelCode="#{rtcm.room_type.property.settings(:ctrip_hotel_id)}" HotelName="Grand Park City Hall Singapore(??????)" />
              <RoomRates>
                <RoomRate RatePlanCode="#{rtcm.ota_room_type_id}" RatePlanCategory="501" NumberOfUnits="1">
                  <Rates>
                    <Rate EffectiveDate="#{date.to_s}" ExpireDate="#{(date + 1.days).to_s}">
                      <Base AmountAfterTax="540" CurrencyCode="SGD" />
                    </Rate>
                  </Rates>
                </RoomRate>
              </RoomRates>
            </RoomStay>
          </RoomStays>
          <ResGuests>
            <ResGuest ArrivalTime="14:00">
              <Profiles>
                <ProfileInfo>
                  <Profile>
                    <Customer>
                      <PersonName>
                        <GivenName>cnhdf</GivenName>
                        <Surname>sdsf</Surname>
                      </PersonName>
                      <PersonName>
                        <GivenName>fei</GivenName>
                        <Surname>janny</Surname>
                      </PersonName>
                      <ContactPerson>
                        <PersonName>
                          <GivenName>Ctrip</GivenName>
                        </PersonName>
                        <Telephone PhoneNumber="0086-513-65066224" />
                        <Email>ctriphotelreshk@ctrip.com</Email>
                      </ContactPerson>
                    </Customer>
                  </Profile>
                </ProfileInfo>
              </Profiles>
            </ResGuest>
          </ResGuests>
          <ResGlobalInfo>
            <GuestCounts>
              <GuestCount Count="2" />
            </GuestCounts>
            <TimeSpan Start="#{date.to_s} 0:00:00" End="#{(date + 1.days).to_s} 0:00:00" />
            <SpecialRequests>
              <SpecialRequest>
                <Text Language="en-us" TextFormat="PlainText">Test Reservation</Text>
                <ListItem ListItem="2">try to arrange nonsmoking room</ListItem>
                <ListItem ListItem="8">try to arrange double bed</ListItem>
              </SpecialRequest>
            </SpecialRequests>
            <DepositPayments>
              <GuaranteePayment>
                <AcceptedPayments>
                  <AcceptedPayment>
                    <PaymentCard CardType="VISA" CardCode="223" CardNumber="4392 2500 1234 5670" ExpireDate="1115">
                      <CardHolderName>Yu Jiwei</CardHolderName>
                    </PaymentCard>
                  </AcceptedPayment>
                </AcceptedPayments>
              </GuaranteePayment>
            </DepositPayments>
            <Total AmountAfterTax="1080" CurrencyCode="SGD" />
            <TPA_Extensions>
              <IsReserved>false</IsReserved>
            </TPA_Extensions>
            <HotelReservationIDs>
              <HotelReservationID ResID_Type="501" ResID_Value="900066367" />
              <HotelReservationID ResID_Value="56950d8c0e31889292bcd8e745c7c4c7" ResID_Type="507""/>
           </HotelReservationIDs>
          </ResGlobalInfo>
        </HotelReservation>
      </HotelReservations>
    </OTA_HotelResRQ>
  </SOAP-ENV:Body>
</SOAP-ENV:Envelope>
  EOF
end