module Spree
  class Gateway::WxpayDirect < Gateway::WxpayDualfun
    def service
      ServiceEnum.create_direct_pay_by_user
    end

    def auto_capture?
      return true
    end

  end
end
