module Rodauth
  module Rails
    class App
      # Roda plugin that extends middleware plugin by propagating response headers.
      module Middleware
        def self.load_dependencies(app)
          app.plugin :hooks
        end

        def self.configure(app)
          app.after do
            if response.empty? && response.headers.any?
              env["rodauth.rails.headers"] = response.headers
            end
          end

          app.plugin :middleware, handle_result: -> (env, res) do
            if headers = env.delete("rodauth.rails.headers")
              res[1] = headers.merge(res[1])
            end
          end
        end
      end
    end
  end
end
