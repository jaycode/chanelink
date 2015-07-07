require 'features/channels/ctrip/reservations/xmls/case1_request_900066242'
require 'features/channels/ctrip/reservations/xmls/case1_response_900066242'
require 'features/channels/ctrip/reservations/xmls/case2_request_900066320'
require 'features/channels/ctrip/reservations/xmls/case2_response_900066320'
require 'features/channels/ctrip/reservations/xmls/case3_request_900066321'
require 'features/channels/ctrip/reservations/xmls/case3_response_900066321'
require 'features/channels/ctrip/reservations/xmls/case4_request_900066362'
require 'features/channels/ctrip/reservations/xmls/case4_response_900066362'
require 'features/channels/ctrip/reservations/xmls/case5_request_900066366'
require 'features/channels/ctrip/reservations/xmls/case5_response_900066366'
require 'features/channels/ctrip/reservations/xmls/case6_request_900066320'
require 'features/channels/ctrip/reservations/xmls/case6_response_900066320'
require 'features/channels/ctrip/reservations/xmls/case7_cancellation_request_900066342'
require 'features/channels/ctrip/reservations/xmls/case7_cancellation_response_900066342'
require 'features/channels/ctrip/reservations/xmls/case7_creation_request_900066342'
require 'features/channels/ctrip/reservations/xmls/case7_creation_response_900066342'
require 'features/channels/ctrip/reservations/xmls/case7_creation_request_900066345'
require 'features/channels/ctrip/reservations/xmls/case7_creation_response_900066345'
require 'features/channels/ctrip/reservations/xmls/case8_request_900066249'
require 'features/channels/ctrip/reservations/xmls/case9_request_900066367'
require 'features/channels/ctrip/reservations/xmls/case10_request_900066252'
require 'features/channels/ctrip/reservations/xmls/case10_response_900066252'

class CtripTestXmls
  def creation_request_900066242(date, rtcm)
    case1_request_900066242(date, rtcm)
  end
  def creation_response_900066242
    case1_response_900066242
	end

  def creation_request_900066320(date, rtcm)
    case2_request_900066320(date, rtcm)
  end

  def creation_response_900066320
    case2_response_900066320
  end

  def cancellation_request_900066320
    case6_request_900066320
  end

  def cancellation_response_900066320
    case6_response_900066320
  end

  def creation_request_900066321(date, rtcm)
    case3_request_900066321(date, rtcm)
  end

  def creation_response_900066321
    case3_response_900066321
  end

  def creation_request_900066362(date, rtcm)
    case4_request_900066362(date, rtcm)
  end

  def creation_response_900066362
    case4_response_900066362
  end

  def creation_request_900066366(date, rtcm)
    case5_request_900066366(date, rtcm)
  end

  def creation_response_900066366
    case5_response_900066366
  end

  def creation_request_900066342(date, rtcm)
    case7_creation_request_900066342(date, rtcm)
  end

  def creation_request_900066345(date, rtcm)
    case7_creation_request_900066345(date, rtcm)
  end

  def cancellation_request_900066342
    case7_cancellation_request_900066342
  end

  def cancellation_response_900066342
    case7_cancellation_response_900066342
  end

  def creation_response_900066342
    case7_creation_response_900066342
  end

  def creation_response_900066345
    case7_creation_response_900066345
  end

  def request_900066249(date, rtcm)
    case8_request_900066249(date, rtcm)
  end

  def request_900066367(date, rtcm)
    case9_request_900066367(date, rtcm)
  end

  def request_900066252(date, rtcm)
    case10_request_900066252(date, rtcm)
  end

  def response_900066252
    case10_response_900066252
  end

end