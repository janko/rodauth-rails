module Rodauth
  module Rails
    class App
      # Roda plugin that extends middleware plugin by propagating response headers.
      module Middleware
        def self.configure(app)
          handle_result = -> (env, res) do
            if headers = env.delete("rodauth.rails.headers")
              res[1] = headers.merge(res[1])
            end
          end

          app.plugin :middleware, handle_result: handle_result do |middleware|
            middleware.plugin :hooks

            middleware.after do
              if response.empty? && response.headers.any?
                env["rodauth.rails.headers"] = response.headers
              end
            end

            middleware.class_eval do
              def self.inspect
                "#{superclass}::Middleware"
              end

              def inspect
                "#<#{self.class.inspect} request=#{request.inspect} response=#{response.inspect}>"
              end
            end
          end
        end
      end
    end
  end
end
