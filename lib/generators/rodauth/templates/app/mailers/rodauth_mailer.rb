class RodauthMailer < ApplicationMailer
  def verify_account(recipient, email_link)
    @email_link = email_link

    mail to: recipient
  end

  def reset_password(recipient, email_link)
    @email_link = email_link

    mail to: recipient
  end

  def verify_login_change(recipient, old_login, new_login, email_link)
    @old_login  = old_login
    @new_login  = new_login
    @email_link = email_link

    mail to: recipient
  end

  def password_changed(recipient)
    mail to: recipient
  end

  # def email_auth(recipient, email_link)
  #   @email_link = email_link
  #
  #   mail to: recipient
  # end

  # def unlock_account(recipient, email_link)
  #   @email_link = email_link
  #
  #   mail to: recipient
  # end
end
