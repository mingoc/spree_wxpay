Spree::Order.class_eval do
  register_update_hook :send_goods_confirm_for_wxpay
  
  def next_step_complete?
    available_steps = checkout_steps
    available_steps[ available_steps.index( self.state ).succ ] == 'complete'
  end
  
  
  # it is update_hook for wxpay, it is called when order.update!
  def send_goods_confirm_for_wxpay
    #TODO consider partial shipped
    if shipped?
      payments_by_wxpay = payments.completed.select(&:method_wxpay?)
      
      if payments_by_wxpay.present?
        payments_by_wxpay.each{|pba|
          pba.source.send_goods_confirm
        }
      end
    end
  end
  
end
