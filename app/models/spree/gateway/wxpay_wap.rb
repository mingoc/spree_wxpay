module Spree
  class Gateway::WxpayWap < Gateway::WxpayDirect
    def service
      ServiceEnum.wxpay_wap
    end

  end
end
