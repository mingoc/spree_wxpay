module SpreeWxpay
  class Engine < Rails::Engine
    engine_name 'spree_wxpay'

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end
    # sets the manifests / assets to be precompiled, even when initialize_on_precompile is false
    initializer "spree.assets.precompile", :group => :all do |app|
      app.config.assets.precompile += %w[
        billing_integrations/wxpay.png
      ]
    end

    config.to_prepare &method(:activate).to_proc

    config.after_initialize do |app|
      app.config.spree.payment_methods += [
        Spree::Gateway::WxpayDualfun,
        Spree::Gateway::WxpayEscrow,
        Spree::Gateway::WxpayDirect,
        Spree::Gateway::WxpayWap
      ]
    end
  end
end
