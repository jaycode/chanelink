def case2_request_900066320(date, rtcm)
  <<-EOF
<?xml version="1.0" ?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
  <SOAP-ENV:Header/>
  <SOAP-ENV:Body>
		<OTA_HotelResRQ Version="2.1" EchoToken="201408212124" xmlns="http://www.opentravel.org/OTA/2003/05">
			<POS>
				<Source>
					<RequestorID ID="" Type="5" MessagePassword="">
          	<CompanyName Code="C" CodeContext="600" />
          </RequestorID>
        </Source>
      </POS>
      <UniqueID ID="900066320" Type="501" />
      <HotelReservations>
        <HotelReservation>
          <RoomStays>
            <RoomStay>
              <RatePlans>
                <RatePlan RatePlanCode="#{rtcm.ota_room_type_id}">
                  <RatePlanDescription>
                    <Text Language="en-us" TextFormat="PlainText">Deluxe(pay at hotel)</Text>
                  </RatePlanDescription>
                </RatePlan>
              </RatePlans>
              <BasicPropertyInfo HotelCode="#{rtcm.room_type.property.settings(:ctrip_hotel_id)}" HotelName="Grand Park City Hall Singapore(?????????)" />
              <RoomRates>
                <RoomRate RatePlanCode="#{rtcm.ota_room_type_id}" RatePlanCategory="16" NumberOfUnits="20">
                  <Rates>
                    <Rate EffectiveDate="#{date.to_s}" ExpireDate="#{(date + 1.days).to_s}">
                      <Base AmountAfterTax="363" CurrencyCode="SGD" />
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
                        <GivenName>gskl</GivenName>
                        <Surname>sdqtt</Surname>
                      </PersonName>
                      <PersonName>
                        <GivenName>csw</GivenName>
                        <Surname>sdsf</Surname>
                      </PersonName>
                      <PersonName>
                        <GivenName>gkl</GivenName>
                        <Surname>sdsfwq</Surname>
                      </PersonName>
                      <PersonName>
                        <GivenName>csw</GivenName>
                        <Surname>sdsf</Surname>
                      </PersonName>
                      <PersonName>
                        <GivenName>haha</GivenName>
                        <Surname>haha</Surname>
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
              <GuestCount Count="40" />
            </GuestCounts>
            <TimeSpan Start="#{(date).to_s} 0:00:00" End="#{(date + 7.days).to_s} 0:00:00" />
            <SpecialRequests>
              <SpecialRequest>
                <Text Language="en-us" TextFormat="PlainText"></Text>
              </SpecialRequest>
            </SpecialRequests>
            <Guarantee>
              <GuaranteesAccepted>
                <GuaranteeAccepted>
                  <PaymentCard />
                </GuaranteeAccepted>
              </GuaranteesAccepted>
            </Guarantee>
            <Total AmountAfterTax="50820" CurrencyCode="SGD" />
            <TPA_Extensions>
              <IsReserved>false</IsReserved>
            </TPA_Extensions>
            <HotelReservationIDs>
              <HotelReservationID ResID_Type="501" ResID_Value="900066320" />
            </HotelReservationIDs>
          </ResGlobalInfo>
        </HotelReservation>
      </HotelReservations>
    </OTA_HotelResRQ>
   </SOAP-ENV:Body>

</SOAP-ENV:Envelope>
  EOF
end