# Uses cookie to determine feature state.
module Flip
  class UrlStrategy < AbstractStrategy

    def description
      "Uses url parmeters to apply only to current request."
    end

    def knows? definition
      params.key? param_name(definition)
    end

    def on? definition
      param = params[param_name(definition)]
      param_value = param.is_a?(Hash) ? param['value'] : param
      param_value === 'true'
    end

    def switchable?
      true
    end

    def switch! key, on
      params[param_name(key)] = {
        'value' => (on ? "true" : "false"),
        'domain' => :all
      }
    end

    def delete! key
      params.delete param_name(key)
    end

    def self.params= params
      @params = params
    end

    def param_name(definition)
      definition = definition.key unless definition.is_a? Symbol
      "flip_#{definition}"
    end

    private

    def params
      self.class.instance_variable_get(:@params) || {}
    end

    # Include in ApplicationController to push cookies into CookieStrategy.
    # Users before_filter and after_filter rather than around_filter to
    # avoid pointlessly adding to stack depth.
    module Loader
      extend ActiveSupport::Concern
      included do
        before_filter :flip_param_strategy_before
        after_filter :flip_param_strategy_after
      end
      def flip_param_strategy_before
        UrlStrategy.params = params
      end
      def flip_param_strategy_after
        UrlStrategy.params = nil
      end
    end

  end
end
