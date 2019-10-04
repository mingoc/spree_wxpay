module Spree
    # start from Spree 3.0, class Gateway is removed
    class Gateway::WxpayBase < PaymentMethod
      preference :wxpay_pid, :string
      preference :wxpay_key, :string

      ServiceEnum = Struct.new( :trade_create_by_buyer,
        :create_direct_pay_by_user,
        :create_partner_trade_by_buyer,
        :wxpay_wap)[ 'trade_create_by_buyer', 'create_direct_pay_by_user', 'create_partner_trade_by_buyer', 'wxpay.wap.create.direct.pay.by.user']

      def service
        raise 'You must implement service method for wxpay service'
      end
      
      def provider
        provider_class.new( partner: preferred_wxpay_pid, sign: preferred_wxpay_key, service: self.service )
      end

      # disable source for now
      def source_required?
        false
      end

    end

end
