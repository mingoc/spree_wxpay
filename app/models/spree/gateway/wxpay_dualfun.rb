module Spree
    # use NewWxpay instead of BillingIntegration::Wxpay
    # original name would cause 'toplevel constant Wxpay referenced', since we are using https://github.com/chloerei/wxpay
    class Gateway::WxpayDualfun < Gateway::WxpayBase
      #preference :email, :string
      #trade_create_by_buyer
      #attr_accessible :preferred_server, :preferred_test_mode, :preferred_email, :preferred_wxpay_pid, :preferred_wxpay_key

      def provider_class
        Spree::Gateway::WxpayProvider
      end


      def service
        ServiceEnum.trade_create_by_buyer
      end

      def auto_capture?
        #
        return false
      end

    end

end
