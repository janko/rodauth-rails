class RodauthMain < Rodauth::Rails::Auth
  configure do
    enable :create_account, :verify_account, :verify_account_grace_period,
      :login, :remember, :logout, :active_sessions, :http_basic_auth,
      :reset_password, :change_password, :change_password_notify,
      :change_login, :verify_login_change,
      :close_account, :lockout, :recovery_codes, :internal_request,
      :path_class_methods

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
    before_create_account { rails_account.username }

    already_logged_in { redirect rails_routes.root_path(rails_request.query_parameters) }
    logout_redirect { rails_routes.root_path }
    verify_account_redirect { login_redirect }
    reset_password_redirect { login_path }
    title_instance_variable :@page_title

    verify_login_change_route nil
  end
end
