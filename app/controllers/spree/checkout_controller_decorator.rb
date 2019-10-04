#encoding: utf-8
module Spree
  CheckoutController.class_eval do
    before_action :checkout_hook, :only => [:update]

    private

    def checkout_hook
      @wxpay_base_class = Spree::Gateway::WxpayBase
      #all_filters = self.class._process_action_callbacks
      #all_filters = all_filters.select{|f| f.kind == :before}
      #logger.debug "all before filers:"+all_filters.map(&:filter).inspect
      return unless @order.next_step_complete?
      #in confirm step, only param is  {"state"=>"confirm"}
      payment_method = get_payment_method_by_params(  )
      if payment_method.kind_of?( @wxpay_base_class )
        handle_billing_integration
      end
    end

    def aplipay_full_service_url( order, wxpay)
      product_names = order.products.pluck(:name)

      #service partner _input_charset out_trade_no subject payment_type logistics_type logistics_fee logistics_payment seller_email price quantity
      options = { #:_input_charset => "utf-8",
                  :out_trade_no => order.number,
                  #:price => order.item_total,
                  #:quantity => 1,
                  #:logistics_type=> 'EXPRESS',
                  #:logistics_fee => order.shipments.to_a.sum(&:cost),
                  #:logistics_payment=>'BUYER_PAY',
                  #:seller_id => wxpay.preferred_wxpay_pid,
                  :notify_url => url_for(:only_path => false, :controller=>'wxpay_status', :action => 'wxpay_notify'),
                  :return_url => url_for(:only_path => false, :controller=>'wxpay_status', :action => 'wxpay_done'),
                  :body => product_names.join(',').truncate(500),  #char 1000
                  #:payment_type => 1,
                  :subject => product_names.join(',').truncate(128) #char 256
      }

      wxpay.provider.url( order, options )
    end

    # handle all supported billing_integration
    def handle_billing_integration
      if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
        payment_method = get_payment_method_by_order( @order )
        if payment_method.kind_of?(@wxpay_base_class)
          redirect_to aplipay_full_service_url(@order, payment_method)
        end
      else
        render( :edit ) and return
      end
    end

    def get_payment_method_by_params
      payment_method_id = params[:order].try(:[],:payments_attributes).try(:first).try(:[],:payment_method_id).to_i
      Spree::PaymentMethod.find_by_id(payment_method_id)
    end

    def get_payment_method_by_order( order )
      order.unprocessed_payments.last.try(:payment_method)
    end

  end
end
