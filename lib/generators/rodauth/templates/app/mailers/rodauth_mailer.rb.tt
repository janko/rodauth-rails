class RodauthMailer < ApplicationMailer
  default to: -> { @rodauth.email_to }, from: -> { @rodauth.email_from }

  def verify_account(name, account_id, key)
    @rodauth = rodauth(name, account_id) { @verify_account_key_value = key }
    @account = @rodauth.rails_account

    mail subject: @rodauth.email_subject_prefix + @rodauth.verify_account_email_subject
  end

  def reset_password(name, account_id, key)
    @rodauth = rodauth(name, account_id) { @reset_password_key_value = key }
    @account = @rodauth.rails_account

    mail subject: @rodauth.email_subject_prefix + @rodauth.reset_password_email_subject
  end

  def verify_login_change(name, account_id, key)
    @rodauth = rodauth(name, account_id) { @verify_login_change_key_value = key }
    @account = @rodauth.rails_account
    @new_email = @account.login_change_key.login

    mail to: @new_email, subject: @rodauth.email_subject_prefix + @rodauth.verify_login_change_email_subject
  end

  def password_changed(name, account_id)
    @rodauth = rodauth(name, account_id)
    @account = @rodauth.rails_account

    mail subject: @rodauth.email_subject_prefix + @rodauth.password_changed_email_subject
  end

  # def reset_password_notify(name, account_id)
  #   @rodauth = rodauth(name, account_id)
  #   @account = @rodauth.rails_account

  #   mail subject: @rodauth.email_subject_prefix + @rodauth.reset_password_notify_email_subject
  # end

  # def email_auth(name, account_id, key)
  #   @rodauth = rodauth(name, account_id) { @email_auth_key_value = key }
  #   @account = @rodauth.rails_account

  #   mail subject: @rodauth.email_subject_prefix + @rodauth.email_auth_email_subject
  # end

  # def unlock_account(name, account_id, key)
  #   @rodauth = rodauth(name, account_id) { @unlock_account_key_value = key }
  #   @account = @rodauth.rails_account

  #   mail subject: @rodauth.email_subject_prefix + @rodauth.unlock_account_email_subject
  # end

  private

  def rodauth(name, account_id, &block)
    instance = RodauthApp.rodauth(name).allocate
    instance.instance_eval { @account = account_ds(account_id).first! }
    instance.instance_eval(&block) if block
    instance
  end
end
