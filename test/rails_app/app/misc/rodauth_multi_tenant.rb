class RodauthMultiTenant < Rodauth::Rails::Auth
  configure do
    enable :create_account, :verify_account, :verify_account_grace_period,
           :login, :remember, :logout, :active_sessions,
           :reset_password, :change_password, :change_password_notify,
           :change_login, :verify_login_change,
           :close_account, :lockout, :recovery_codes, :internal_request,
           :path_class_methods, :jwt

    prefix { "/multi/tenant/#{path_key}" }

    rails_controller { RodauthController }

    before_rodauth do
      if param_or_nil("raise")
        raise NotImplementedError
      elsif param_or_nil("fail")
        fail "failed"
      end
    end

    account_status_column :status

    email_subject_prefix "[RodauthTest] "
    email_from "noreply@rodauth.test"
    create_reset_password_email do
      RodauthMultiTenantMailer.reset_password(:multi_tenant, account_id, request.env[:path_key], reset_password_key_value)
    end
    create_verify_account_email { RodauthMultiTenantMailer.verify_account(:multi_tenant, account_id, request.env[:path_key], verify_account_key_value) }
    create_verify_login_change_email { |_login| RodauthMultiTenantMailer.verify_login_change(:multi_tenant, account_id, request.env[:path_key], verify_login_change_key_value) }
    create_password_changed_email { RodauthMultiTenantMailer.password_changed(:multi_tenant, account_id, request.env[:path_key]) }

    require_login_confirmation? false
    verify_account_set_password? false
    extend_remember_deadline? true
    max_invalid_logins 3

    if defined?(::Turbo)
      after_login_failure do
        if rails_request.format.turbo_stream?
          return_response rails_render(turbo_stream: [turbo_stream.append("login-form", %(<div id="turbo-stream">login failed</div>))])
        end
      end
      check_csrf? { rails_request.format.turbo_stream? ? false : super() }
    end

    after_login { remember_login }

    logout_redirect { rails_routes.root_path }
    login_redirect do
      segs = login_path.split('/')
      segs.insert(-2, request.env[:path_key])
      segs.join('/')
    end
    verify_account_redirect { login_redirect }
    reset_password_redirect do
      segs = login_path.split('/')
      segs.insert(-2, request.env[:path_key])
      segs.join('/')
    end
    title_instance_variable :@page_title

    verify_login_change_route nil
    change_login_route "change-email"
  end

  attr_accessor :path_key
end
