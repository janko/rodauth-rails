require "test_helper"

class ModelTest < UnitTest
  test "password attribute with a column" do
    account = password_column_account

    account.password = "secret"
    assert_equal "secret", account.password

    refute_nil account.password_hash
    assert_operator BCrypt::Password.new(account.password_hash), :==, "secret"

    account.password = "new secret"
    assert_operator BCrypt::Password.new(account.password_hash), :==, "new secret"

    account.password = ""
    refute_nil account.password_hash

    account.password = nil
    assert_nil account.password_hash
  end

  test "password attribute with a table" do
    account = password_table_account

    account.password = "secret"
    assert_equal "secret", account.password

    assert_instance_of account.class::PasswordHash, account.password_hash
    assert_operator BCrypt::Password.new(account.password_hash.password_hash), :==, "secret"

    refute account.password_hash.persisted?
    account.save!
    assert account.password_hash.persisted?

    account.password = "new secret"
    assert_operator BCrypt::Password.new(account.password_hash.password_hash), :==, "new secret"
    account.password_hash.password_hash_changed?

    account.save!
    refute account.password_hash.changed?
    assert_operator BCrypt::Password.new(account.password_hash.password_hash), :==, "new secret"

    account.password = ""
    assert_operator BCrypt::Password.new(account.password_hash.password_hash), :==, ""

    account.password = nil
    refute account.password_hash.destroyed?
    account.save!
    assert account.password_hash.destroyed?

    account.reload
    assert_nil account.password_hash
  end

  test "not selecting password hash column when using database authentication functions" do
    account = build_account { use_database_authentication_functions? true }
    account.update(password: "secret")
    account.reload

    assert_equal account.id, account.password_hash.id
    assert_raises ActiveModel::MissingAttributeError do
      account.password_hash.password_hash
    end
  end

  test "password requirements validation" do
    account = password_column_account

    account.password = "foo"
    refute account.valid?
    assert_equal ["invalid password, does not meet requirements (minimum 6 characters)"], account.errors[:password]

    account.password = "foobar"
    assert account.valid?
  end

  test "per-account password requirements validation" do
    account = build_account do
      account_password_hash_column :password_hash
      password_minimum_length { @account[:email].length }
    end

    account.password = "foobar"
    refute account.valid?

    account.password = "long enough password"
    assert account.valid?
  end

  test "disabling password requirements validation" do
    account = password_column_account(validate: { password_requirements: false })
    account.password = "a"
    assert account.valid?
  end

  test "password presence validation with password column" do
    account = password_column_account(validate: { password_presence: true })

    refute account.valid?
    assert_equal ["can't be blank"], account.errors[:password]

    account.password = ""
    refute account.valid?
    assert_equal ["can't be blank"], account.errors[:password]

    account.password = "secret"
    assert account.valid?
  end

  test "password presence validation with password table" do
    account = password_table_account(validate: { password_presence: true })

    refute account.valid?
    assert_equal ["can't be blank"], account.errors[:password]

    account.password = ""
    refute account.valid?
    assert_equal ["can't be blank"], account.errors[:password]

    account.password = "secret"
    assert account.valid?

    account.save!
    account.password = nil
    refute account.valid?
    assert_equal ["can't be blank"], account.errors[:password]
  end

  test "disabling password presence validation" do
    account = password_column_account(validate: { password_presence: false })
    assert account.valid?
  end

  test "password confirmation validation" do
    account = password_column_account
    account.password = "secret"
    account.password_confirmation = ""
    refute account.valid?
    assert_equal ["passwords do not match"], account.errors[:password]
    account.password_confirmation = "foobar"
    refute account.valid?
    assert_equal ["passwords do not match"], account.errors[:password]
    account.password_confirmation = "secret"
    assert account.valid?
  end

  test "disabling password confirmation validation" do
    account = password_column_account(validate: { password_confirmation: false })
    refute account.respond_to?(:password_confirmation)
  end

  test "login presence validation" do
    account = build_account

    account.email = nil
    refute account.valid?
    assert_equal ["can't be blank"], account.errors[:email]

    account.email = ""
    refute account.valid?
    assert_equal ["can't be blank"], account.errors[:email]

    account.email = "user@example.com"
    assert account.valid?
  end

  test "login requirements validation" do
    account = build_account

    account.email = "f"
    refute account.valid?
    assert_equal ["invalid login, minimum 3 characters"], account.errors[:email]

    account.email = "foo"
    refute account.valid?
    assert_equal ["invalid login, not a valid email address"], account.errors[:email]

    account.email = "foo@bar.com"
    assert account.valid?
  end

  test "feature associations" do
    account = build_account do
      enable :jwt_refresh, :email_auth, :account_expiration, :audit_logging,
        :disallow_password_reuse, :otp, :sms_codes, :webauthn,
        :password_expiration, :single_session
    end

    account.save!

    account.create_remember_key!(id: account.id, key: "key", deadline: Time.now)
    assert_instance_of account.class::RememberKey, account.remember_key

    account.create_verification_key(id: account.id, key: "key")
    assert_instance_of account.class::VerificationKey, account.verification_key

    account.create_password_reset_key(id: account.id, key: "key", deadline: Time.now)
    assert_instance_of account.class::PasswordResetKey, account.password_reset_key

    account.create_login_change_key(id: account.id, key: "key", login: "foo@bar.com", deadline: Time.now)
    assert_instance_of account.class::LoginChangeKey, account.login_change_key

    account.create_lockout!(id: account.id, key: "key", deadline: Time.now)
    assert_instance_of account.class::Lockout, account.lockout

    account.create_login_failure!(id: account.id)
    assert_instance_of account.class::LoginFailure, account.login_failure

    account.create_email_auth_key!(id: account.id, key: "key", deadline: Time.now)
    assert_instance_of account.class::EmailAuthKey, account.email_auth_key

    account.create_activity_time!(id: account.id, last_activity_at: Time.now, last_login_at: Time.now)
    assert_instance_of account.class::ActivityTime, account.activity_time

    capture_io { account.active_session_keys.create!(session_id: "1") }
    assert_instance_of account.class::ActiveSessionKey, account.active_session_keys.first

    account.authentication_audit_logs.create!(message: "Foo")
    assert_instance_of account.class::AuthenticationAuditLog, account.authentication_audit_logs.first

    account.previous_password_hashes.create!(password_hash: "secret")
    assert_instance_of account.class::PreviousPasswordHash, account.previous_password_hashes.first

    account.jwt_refresh_keys.create!(key: "foo", deadline: Time.now)
    assert_instance_of account.class::JwtRefreshKey, account.jwt_refresh_keys.first

    account.create_password_change_time!(id: account.id)
    assert_instance_of account.class::PasswordChangeTime, account.password_change_time

    account.create_session_key!(id: account.id, key: "key")
    assert_instance_of account.class::SessionKey, account.session_key

    account.create_otp_key!(id: account.id, key: "key")
    assert_instance_of account.class::OtpKey, account.otp_key

    account.create_sms_code!(id: account.id, phone_number: "0123456789")
    assert_instance_of account.class::SmsCode, account.sms_code

    capture_io { account.recovery_codes.create!(id: account.id, code: "foo") }
    assert_instance_of account.class::RecoveryCode, account.recovery_codes.first

    account.create_webauthn_user_id!(id: account.id, webauthn_id: "id")
    assert_instance_of account.class::WebauthnUserId, account.webauthn_user_id

    capture_io { account.webauthn_keys.create!(webauthn_id: "id", public_key: "key", sign_count: 1) }
    assert_instance_of account.class::WebauthnKey, account.webauthn_keys.first
  end

  test "automatically destroying associations" do
    account = build_account { enable :audit_logging }
    account.update!(password: "secret")
    account.create_remember_key!(id: account.id, key: "key", deadline: Time.now)
    account.authentication_audit_logs.create!(message: "Foo")
    account.destroy

    assert account.password_hash.destroyed?
    assert account.remember_key.destroyed?
    assert_equal 1, account.class::AuthenticationAuditLog.count
  end

  test "passing association options hash" do
    account = build_account(association_options: { dependent: nil })
    account.save!
    account.create_remember_key!(id: account.id, key: "key", deadline: Time.now)

    assert_raises(ActiveRecord::InvalidForeignKey) { account.destroy }
  end

  test "passing association options block" do
    account = build_account(association_options: -> (name) {
      { dependent: nil } if name == :remember_key
    })

    account.save!
    account.create_remember_key!(id: account.id, key: "key", deadline: Time.now)

    assert_raises(ActiveRecord::InvalidForeignKey) { account.destroy }

    account.remember_key.destroy
    account.create_verification_key(id: account.id, key: "key")

    account.destroy
  end

  test "inverse association" do
    account = build_account
    account.save!
    account.create_remember_key!(id: account.id, key: "key", deadline: Time.now)
    account.reload

    assert_equal account.object_id, account.remember_key.account.object_id
  end

  test "module builder method with default configuration" do
    account_class = define_account_class
    account_class.include Rodauth::Rails.model(validate: { password_presence: false })
    assert account_class.reflect_on_association(:password_reset_key)
    account = account_class.new(email: "user@example.com")
    assert account.valid?
  end

  test "module builder method with secondary configuration" do
    account_class = define_account_class
    account_class.include Rodauth::Rails.model(:json, validate: { password_requirements: false })
    assert account_class.reflect_on_association(:verification_key)
    refute account_class.reflect_on_association(:password_reset_key)
    account = account_class.new(email: "user@example.com", password: "a")
    assert account.valid?
  end

  private

  def password_column_account(**options)
    build_account(**options) { account_password_hash_column :password_hash }
  end

  def password_table_account(**options)
    ActiveRecord::Base.connection.remove_column :accounts, :password_hash
    build_account(**options) { account_password_hash_column nil }
  end

  def build_account(**options, &block)
    account_class = define_account_class

    rodauth_class = Class.new(Rodauth::Rails.app.rodauth)
    rodauth_class.configure { instance_exec(&block) if block }

    account_class.include Rodauth::Rails::Model.new(rodauth_class, validate: { password_presence: false }, **options)
    account_class.new(email: "user@example.com")
  end

  def define_account_class
    account_class = Class.new(ActiveRecord::Base)
    account_class.table_name = :accounts
    self.class.const_set(:Account, account_class) # give it a name
    account_class
  end

  def teardown
    self.class.send(:remove_const, :Account) if self.class.constants.include?(:Account)
    ActiveSupport::Dependencies.clear # clear cache used for :class_name association option
    super
  end
end
