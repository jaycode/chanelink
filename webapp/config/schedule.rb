every 5.minutes do
  runner "BookingsController.get"
end

every 1.day, :at => '1:00 am' do
  runner "PopulateRackRateController.handle"
end

every 1.day, :at => '2:00 am' do
  runner "PopulateMinStayController.handle"
end

every 1.day, :at => '3:00 am' do
  runner "BookingsController.clean_cc_info"
end