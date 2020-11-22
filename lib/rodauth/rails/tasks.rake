namespace :rodauth do
  task routes: :environment do
    app = Rodauth::Rails.app

    puts "Routes handled by #{app}:"
    puts

    app.opts[:rodauths].each do |rodauth_name, rodauth_class|
      route_names = rodauth_class.routes
        .map { |handle_method| handle_method.to_s.sub(/\Ahandle_/, "") }

      rodauth = rodauth_class.allocate

      routes = route_names.map do |name|
        [
          rodauth.public_send(:"#{name}_path"),
          "rodauth#{rodauth_name && "(:#{rodauth_name})"}.#{name}_path",
        ]
      end

      padding = routes.map { |path, _| path.length }.max

      route_lines = routes.map do |path, code|
        "#{path.ljust(padding)}  #{code}"
      end

      puts "  #{route_lines.join("\n  ")}"
      puts
    end
  end
end
