require "test_helper"
require "generators/rodauth/mailer_generator"

class MailerGeneratorTest < Rails::Generators::TestCase
  tests Rodauth::Rails::Generators::MailerGenerator
  destination File.expand_path("#{__dir__}/../../tmp")
  setup :prepare_destination

  test "mailer" do
    run_generator

    assert_file "app/mailers/rodauth_mailer.rb", /class RodauthMailer < ApplicationMailer/
  end

  test "views" do
    run_generator

    %w[
      verify_account verify_login_change unlock_account reset_password
      password_changed email_auth
    ].each do |template|
      assert_file "app/views/rodauth_mailer/#{template}.text.erb"
    end
  end

  test "name option" do
    run_generator %w[--name authentication]

    assert_file "app/mailers/authentication_mailer.rb", /class AuthenticationMailer < ApplicationMailer/
    assert_file "app/views/authentication_mailer/verify_account.text.erb"

    assert_no_directory "app/views/rodauth_mailer"
  end
end
