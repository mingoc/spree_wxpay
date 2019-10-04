# coding: utf-8
#inspired by https://github.com/spree-contrib/spree_skrill
module Spree
  class WxpayStatusController < StoreController
    #fixes Action::Controller::InvalidAuthenticityToken error on wxpay_notify
    skip_before_action :verify_authenticity_token

    def wxpay_done
      # wxpay acount could vary in each store.
      # get order_no from query string -> get payment -> initialize Wxpay -> verify ailpay callback
      order = retrieve_order params["out_trade_no"]
      #wxpay_payment = get_wxpay_payment( order )
      
      #if wxpay_payment.payment_method.provider.verify?( request.query_parameters )
      if $wxpayclient.verify?(request.query_parameters) 
        # 担保交易的交易状态变更顺序依次是:
        #  WAIT_BUYER_PAY→WAIT_SELLER_SEND_GOODS→WAIT_BUYER_CONFIRM_GOODS→TRADE_FINISHED。
        # 即时到账的交易状态变更顺序依次是:
        #  WAIT_BUYER_PAY→TRADE_FINISHED。
        wxpay_para={'trade_no'=> request.query_parameters['trade_no'],
                     'trade_status' => 'completed'
                    }

        complete_order( order, wxpay_para )
        if order.complete?
          #copy from spree/frontend/checkout_controller
          session[:order_id] = nil
          flash.notice = Spree.t(:order_processed_successfully)
          flash['order_completed'] = true
          redirect_to spree.order_path( order )
        else
          #Strange
          redirect_to checkout_state_path(order.state)
        end
      else
        redirect_to checkout_state_path(order.state)
      end

    end

    def wxpay_notify
      order = retrieve_order params["out_trade_no"]
      #wxpay_payment = get_wxpay_payment( order )
      if $wxpayclient.verify?(request.query_parameters)    #wxpay_payment.payment_method.provider.verify?( request.request_parameters )
        complete_order( order, request.request_parameters )
        render text: "success"
      else
        render text: "fail"
      end

    end

    private

    def retrieve_order(order_number)
      @order = Spree::Order.find_by_number!(order_number)
    end

    def get_wxpay_payment( order )
      #use payment instead of unprocessed_payments, order may be completed.
      order.payments.last
    end

    def complete_order( order, wxpay_parameters )
      unless order.complete?
        wxpay_payment = get_wxpay_payment( order )
        wxpay_payment.update_attribute :state, "completed"
        wxpay_payment.update_attribute :response_code, "#{wxpay_parameters['trade_no']},#{wxpay_parameters['trade_status']}"
        # it require pending_payments to process_payments!
        order.next
      end
    end
  end
end
