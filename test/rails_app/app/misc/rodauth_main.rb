class RodauthMain < Rodauth::Rails::Auth
  configure do
    enable :create_account, :verify_account, :verify_account_grace_period,
      :login, :remember, :logout, :active_sessions,
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

    after_login { remember_login }

    logout_redirect { rails_routes.root_path }
    verify_account_redirect { login_redirect }
    reset_password_redirect { login_path }
    title_instance_variable :@page_title
  end
end
