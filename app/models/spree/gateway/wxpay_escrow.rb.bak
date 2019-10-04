module Spree
  class Gateway::WxpayEscrow < Gateway::WxpayDualfun

    def service
      ServiceEnum.create_partner_trade_by_buyer
    end

    def auto_capture?
      return false
    end

  end
end
