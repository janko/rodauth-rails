module Rodauth
  module Rails
    module Routing
      def rodauth(name = nil, as: name)
        auth_class = Rodauth::Rails.app.rodauth!(name)
        scope = auth_class.roda_class.new({})
        rodauth = auth_class.new(scope)

        controller = rodauth.rails_controller.controller_name
        namespace = rodauth.rails_controller.module_parent_name&.underscore

        scope controller: controller, module: namespace, as: as do
          auth_class.route_hash.each do |route_path, route_method|
            next if route_method.to_s.end_with?("_js")

            path = "#{rodauth.prefix}/#{route_path}"
            action = route_method.to_s.sub(/\Ahandle_/, "")
            verbs = rodauth_verbs(rodauth, route_method)

            match path, action: action, as: action, via: verbs
          end
        end
      end

      private

      def rodauth_verbs(rodauth, route_method)
        file_path, start_line = rodauth.method(:"_#{route_method}").source_location
        lines = File.foreach(file_path).to_a
        indentation = lines[start_line - 1][/^\s+/]
        verbs = []

        lines[start_line..-1].each do |code|
          verbs << :GET if code.include?("r.get") && !rodauth.only_json?
          verbs << :POST if code.include?("r.post")
          break if code.start_with?("#{indentation}end")
        end

        verbs << :POST if rodauth.features.include?(:json) && route_method.to_s.match?(/two_factor_(manage|auth)$/)
        verbs
      end
    end
  end
end
