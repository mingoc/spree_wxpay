# coding: utf-8
require 'wxpay'

module Spree
  class Gateway::WxpayProvider
    attr_accessor :service

    def initialize( options = {})
      ::Wxpay.pid = options[:partner]
      ::Wxpay.key = options[:sign]
      #::Wxpay.seller_email = options[:email]
      self.service =  options[:service]
    end

    def verify?( notify_params )
      ::Wxpay::Notify.verify?(notify_params)
    end

    # * params
    #   * options - notify_url, return_url, body, subject
    def url( order, options = {} )
      pc_direct_params = {
        total_fee:  order.total
      }
      pc_escrow_params = {
        :price => order.item_total,
        :quantity => 1,
        :logistics_type=> 'EXPRESS',
        :logistics_fee => order.shipments.to_a.sum(&:cost),
        :logistics_payment=>'BUYER_PAY' }
      wap_params =  {
        total_fee:  order.total
        }

      case service
      when Gateway::WxpayBase::ServiceEnum.wxpay_wap
        options.merge!( wap_params )
        #::Wxpay::Service.create_direct_pay_by_user_wap_url( options )
#        binding.pry
        $wxpayclient.page_execute_url(
          method: 'wxpay.trade.wap.pay',
          return_url: options[:return_url],
          notify_url: options[:notify_url],
          biz_content: JSON.generate({
                                       out_trade_no: options[:out_trade_no], 
                                       product_code: 'QUICK_WAP_WAY',
                                       total_amount: options[:total_fee],
                                       subject: options[:subject],
                                       quit_url: options[:return_url], #todo change
                                     }, ascii_only: true)
        )

        
      when Gateway::WxpayBase::ServiceEnum.create_direct_pay_by_user
        options.merge!( pc_direct_params )
        
        #create_direct_pay_by_user
        binding.pry
        $wxpayclient.page_execute_url(
          method: 'wxpay.trade.page.pay',
          biz_content: {
            out_trade_no: options[:out_trade_no],
            product_code: 'FAST_INSTANT_TRADE_PAY',
            total_amount: options[:total_fee],
            subject: options[:subject]
          }.to_json(ascii_only: true),
          return_url: options[:return_url],
          notify_url: options[:notify_url],
        )
        
        #::Wxpay::Service.create_direct_pay_by_user_url( options )
      when Gateway::WxpayBase::ServiceEnum.create_partner_trade_by_buyer
        # escrow service
        options.merge!( pc_escrow_params )
        ::Wxpay::Service.create_partner_trade_by_buyer_url( options )
      when Gateway::WxpayBase::ServiceEnum.trade_create_by_buyer
        options.merge!( pc_escrow_params )
        ::Wxpay::Service.trade_create_by_buyer_url( options )
      end
    end

    def send_goods_confirm( wxpay_transaction )
      options = {  :trade_no  => wxpay_transaction.trade_no,
        :logistics_name => 'dalianshops.com',
        :transport_type => 'EXPRESS'
      }
      if trade_create_by_buyer? || create_partner_trade_by_buyer?
        wxpay_return = ::Wxpay::Service.send_goods_confirm_by_platform(options)
        wxpay_xml_return = WxpayXmlReturn.new( wxpay_return )
        if wxpay_xml_return.success?
          wxpay_transaction.update_attributes( :trade_status => wxpay_xml_return.trade_status )
        end
      end
    end

    # 标准双接口
    def trade_create_by_buyer?
      self.service == Gateway::WxpayBase::ServiceEnum.trade_create_by_buyer
    end

    # 即时到帐
    def create_direct_pay_by_user?
      self.service == Gateway::WxpayBase::ServiceEnum.create_direct_pay_by_user
    end

    # 担保交易,  escrow
    def create_partner_trade_by_buyer?
      self.service == Gateway::WxpayBase::ServiceEnum.create_partner_trade_by_buyer
    end

    def wxpay_wap?
      self.service == Gateway::WxpayBase::ServiceEnum.wxpay_wap
    end


    # * description - before order transition to: :complete
    # *   call spree/payment#gateway_action
    # * params
    #   * options - gateway_options
    # * return - pingpp_response
    def purchase(money, credit_card, options = {})
      # since pingpp is offsite payment, this method is placehodler only.
      # in this way, we could go through spree payment process.
      return Gateway::WxpayResponse.new
    end

  end
end
