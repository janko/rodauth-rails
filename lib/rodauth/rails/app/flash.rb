module Rodauth
  module Rails
    class App
      # Sets up Rails' flash integration.
      module Flash
        def self.load_dependencies(app)
          app.plugin :hooks
        end

        def self.configure(app)
          app.before { request.flash }        # load flash
          app.after  { request.commit_flash } # save flash
        end

        module InstanceMethods
          def flash
            request.flash
          end
        end

        module RequestMethods
          def flash
            rails_request.flash
          end

          def commit_flash
            rails_request.commit_flash
          end

          private

          def rails_request
            ActionDispatch::Request.new(env)
          end
        end
      end
    end
  end
end
