namespace :rodauth do
  task routes: :environment do
    app = Rodauth::Rails.app

    puts "Routes handled by #{app}:"

    app.opts[:rodauths].each do |configuration_name, auth_class|
      rodauth = auth_class.allocate

      routes = auth_class.routes.map do |handle_method|
        path_method = "#{handle_method.to_s.sub(/\Ahandle_/, "")}_path"

        [
          rodauth.public_send(path_method),
          "rodauth#{configuration_name && "(:#{configuration_name})"}.#{path_method}",
        ]
      end

      padding = routes.map { |path, _| path.length }.max

      route_lines = routes.map do |path, code|
        "#{path.ljust(padding)}  #{code}"
      end

      puts "\n  #{route_lines.join("\n  ")}" unless route_lines.empty?
    end
  end
end
