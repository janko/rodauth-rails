namespace :rodauth do
  task routes: :environment do
    app = Rodauth::Rails.app

    puts "Routes handled by #{app}:"

    app.opts[:rodauths].each do |configuration_name, auth_class|
      rodauth = auth_class.allocate
      only_json = rodauth.method(:only_json?).owner != Rodauth::Base && rodauth.only_json?

      routes = auth_class.route_hash.map do |path, handle_method|
        file_path, start_line = rodauth.method(:"_#{handle_method}").source_location
        lines = File.foreach(file_path).to_a
        indentation = lines[start_line - 1][/^\s+/]
        verbs = []

        lines[start_line..-1].each do |code|
          verbs << :GET if code.include?("r.get") && !only_json
          verbs << :POST if code.include?("r.post")
          break if code.start_with?("#{indentation}end")
        end

        path_method = "#{handle_method.to_s.sub(/\Ahandle_/, "")}_path"

        [
          verbs.join("/"),
          "#{rodauth.prefix}#{path}",
          "rodauth#{configuration_name && "(:#{configuration_name})"}.#{path_method}",
        ]
      end

      verbs_padding = routes.map { |verbs, _, _| verbs.length }.max
      path_padding = routes.map { |_, path, _| path.length }.max

      route_lines = routes.map do |verbs, path, code|
        "#{verbs.ljust(verbs_padding)}  #{path.ljust(path_padding)}  #{code}"
      end

      puts "\n  #{route_lines.join("\n  ")}" unless route_lines.empty?
    end
  end
end
