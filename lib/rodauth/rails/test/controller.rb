require "active_support/concern"

module Rodauth
  module Rails
    module Test
      module Controller
        extend ActiveSupport::Concern

        included do
          setup :setup_rodauth
        end

        def process(*)
          catch_rodauth { super }
        end
        ruby2_keywords(:process) if respond_to?(:ruby2_keywords, true)

        private

        def setup_rodauth
          Rodauth::Rails.app.opts[:rodauths].each do |name, auth_class|
            scope = auth_class.roda_class.new(request.env)
            request.env[["rodauth", *name].join(".")] = auth_class.new(scope)
          end
        end

        def catch_rodauth(&block)
          result = catch(:halt, &block)

          if result.is_a?(Array) # rodauth response
            response.status = result[0]
            response.headers.merge! result[1]
            response.body = result[2]
          end

          response
        end

        def rodauth(name = nil)
          @controller.rodauth(name)
        end
      end
    end
  end
end
