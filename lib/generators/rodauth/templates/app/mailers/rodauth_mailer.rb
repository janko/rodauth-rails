class RodauthMailer < ApplicationMailer
  def verify_account(name, account_id, key)
    @email_link = email_link(name, :verify_account, account_id, key)
    @account = find_account(name, account_id)

    mail to: @account.email, subject: rodauth(name).verify_account_email_subject
  end

  def reset_password(name, account_id, key)
    @email_link = email_link(name, :reset_password, account_id, key)
    @account = find_account(name, account_id)

    mail to: @account.email, subject: rodauth(name).reset_password_email_subject
  end

  def verify_login_change(name, account_id, key)
    @email_link = email_link(name, :verify_login_change, account_id, key)
    @account = find_account(name, account_id)
    @new_email = @account.login_change_key.login

    mail to: @new_email, subject: rodauth(name).verify_login_change_email_subject
  end

  def password_changed(name, account_id)
    @account = find_account(name, account_id)

    mail to: @account.email, subject: rodauth(name).password_changed_email_subject
  end

  # def email_auth(name, account_id, key)
  #   @email_link = email_link(name, :email_auth, account_id, key)
  #   @account = find_account(name, account_id)

  #   mail to: @account.email, subject: rodauth(name).email_auth_email_subject
  # end

  # def unlock_account(name, account_id, key)
  #   @email_link = email_link(name, :unlock_account, account_id, key)
  #   @account = find_account(name, account_id)

  #   mail to: @account.email, subject: rodauth(name).unlock_account_email_subject
  # end

  private

  def find_account(_name, account_id)
<% if defined?(ActiveRecord::Railtie) -%>
    Account.find(account_id)
<% else -%>
    Account.with_pk!(account_id)
<% end -%>
  end

  def email_link(name, action, account_id, key)
    instance = rodauth(name)
    instance.instance_variable_set(:@account, { id: account_id })
    instance.instance_variable_set(:"@#{action}_key_value", key)
    instance.public_send(:"#{action}_email_link")
  end

  def rodauth(name)
    RodauthApp.rodauth(name).allocate
  end
end
