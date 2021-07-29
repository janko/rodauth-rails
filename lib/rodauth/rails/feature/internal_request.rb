module Rodauth
  module Rails
    module Feature
      module InternalRequest
        def post_configure
          super
          return unless internal_request?

          self.class.define_singleton_method(:internal_request) do |route, opts = {}, &blk|
            url_options = ::Rails.application.config.action_mailer.default_url_options || {}

            scheme = url_options[:protocol]
            port = url_options[:port]
            port||= Rack::Request::DEFAULT_PORTS[scheme] if Rack.release < "2"
            host = url_options[:host]
            host_with_port = host && port ? "#{host}:#{port}" : host

            env = {
              "HTTP_HOST" => host_with_port,
              "rack.url_scheme" => scheme,
              "SERVER_NAME" => host,
              "SERVER_PORT" => port,
            }.compact

            opts = opts.merge(env: env) { |k, v1, v2| v2.merge(v1) }

            super(route, opts, &blk)
          end
        end

        private

        def rails_controller_around
          return yield if internal_request?
          super
        end

        def rails_instrument_request
          return yield if internal_request?
          super
        end

        def rails_instrument_redirection
          return yield if internal_request?
          super
        end
      end
    end
  end
end
