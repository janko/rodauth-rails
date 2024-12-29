module Rodauth
  module Rails
    module Tasks
      class Routes
        IGNORE = [:webauthn_setup_js, :webauthn_auth_js, :webauthn_autofill_js]
        JSON_POST = [:two_factor_manage, :two_factor_auth]

        attr_reader :auth_class

        def initialize(auth_class)
          @auth_class = auth_class
        end

        def call
          routes = auth_class.route_hash.map do |path, handle_method|
            route_name = handle_method.to_s.delete_prefix("handle_").to_sym
            next if IGNORE.include?(route_name)
            verbs = route_verbs(route_name)

            [
              route_name.to_s,
              verbs.join("|"),
              "#{rodauth.prefix}#{path}",
              "rodauth#{configuration_name && "(:#{configuration_name})"}.#{route_name}_path",
            ]
          end

          routes.compact!
          padding = routes.transpose.map { |string| string.map(&:length).max }

          output_lines = routes.map do |columns|
            [columns[0].rjust(padding[0]), columns[1].ljust(padding[1]), columns[2].ljust(padding[2]), columns[3]].join("  ")
          end

          puts "\n  #{output_lines.join("\n  ")}"
        end

        private

        def route_verbs(route_name)
          file_path, start_line = rodauth.method(:"_handle_#{route_name}").source_location
          lines = File.foreach(file_path).to_a
          indentation = lines[start_line - 1][/^\s+/]
          verbs = []

          lines[start_line..-1].each do |code|
            verbs << :GET if code.include?("r.get") && !rodauth.only_json?
            verbs << :POST if code.include?("r.post")
            break if code.start_with?("#{indentation}end")
          end

          verbs << :POST if rodauth.features.include?(:json) && JSON_POST.include?(route_name)
          verbs
        end

        def rodauth
          auth_class.new(scope)
        end

        def scope
          auth_class.roda_class.new({})
        end

        def configuration_name
          auth_class.configuration_name
        end
      end
    end
  end
end
