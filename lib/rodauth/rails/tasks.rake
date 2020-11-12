namespace :rodauth do
  task routes: :environment do
    app = Rodauth::Rails.app

    puts "Routes handled by Rodauth::Rails::Middleware:"
    puts

    app.opts[:rodauths].each do |rodauth_name, rodauth_class|
      routes = []

      rodauth_class.features.uniq.each do |feature|
        case feature
        when :login
          routes << [[:get, :post], :login]
        when :logout
          routes << [[:get, :post], :logout]
        when :create_account
          routes << [[:get, :post], :create_account]
        when :verify_account
          routes << [[:get, :post], :verify_account_resend]
          routes << [[:get, :post], :verify_account]
        when :reset_password
          routes << [[:get, :post], :reset_password_request]
          routes << [[:get, :post], :reset_password]
        when :change_password
          routes << [[:get, :post], :change_password]
        when :change_login
          routes << [[:get, :post], :change_login]
        when :verify_login_change
          routes << [[:get, :post], :verify_login_change]
        when :confirm_password
          routes << [[:get, :post], :confirm_password]
        when :remember
          routes << [[:get, :post], :remember]
        when :lockout
          routes << [[:post],       :unlock_account_request]
          routes << [[:get, :post], :unlock_account]
        when :close_account
          routes << [[:get, :post], :close_account]
        when :email_auth
          routes << [[:post],       :email_auth_request]
          routes << [[:get, :post], :email_auth]
        when :two_factor_base
          routes << [[:get],        :two_factor_manage]
          routes << [[:get],        :two_factor_auth]
          routes << [[:get, :post], :two_factor_disable]
        when :otp
          routes << [[:get, :post], :otp_auth]
          routes << [[:get, :post], :otp_setup]
          routes << [[:get, :post], :otp_disable]
        when :sms_codes
          routes << [[:get, :post], :sms_request]
          routes << [[:get, :post], :sms_auth]
          routes << [[:get, :post], :sms_setup]
          routes << [[:get, :post], :sms_confirm]
          routes << [[:get, :post], :sms_disable]
        when :recovery_codes
          routes << [[:get, :post], :recovery_auth]
          routes << [[:get, :post], :recovery_codes]
        when :webauthn
          routes << [[:get],        :webauthn_auth_js]
          routes << [[:get, :post], :webauthn_auth]
          routes << [[:get],        :webauthn_setup_js]
          routes << [[:get, :post], :webauthn_setup]
          routes << [[:get, :post], :webauthn_remove]
        when :webauthn_login
          routes << [[:post], :webauthn_login]
        when :jwt_refresh
          routes << [[:post], :jwt_refresh]
        end
      end

      rodauth = rodauth_class.allocate
      rodauth.instance_variable_set(:@scope, app.allocate)

      # no need to display GET routes in API-only mode
      if rodauth.only_json?
        routes.each { |verbs, _| verbs.delete(:get) }
      end

      routes.map! do |verbs, name|
        [
          verbs.map { |verb| verb.to_s.upcase }.join("/"),
          rodauth.public_send(:"#{name}_path"),
          "rodauth#{rodauth_name && "(:#{rodauth_name})"}.#{name}_path",
        ]
      end

      verbs_padding, route_padding, code_padding = [0, 1, 2].map do |idx|
        routes.map { |a| a[idx] }.map(&:length).max
      end

      lines = routes.map do |verbs, route, code|
        [
          verbs.rjust(verbs_padding),
          route.ljust(route_padding),
          code.ljust(code_padding),
        ].join("  ")
      end

      puts "  #{lines.join("\n  ")}"
      puts
    end
  end
end
