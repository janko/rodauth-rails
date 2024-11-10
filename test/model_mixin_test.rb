require "test_helper"

class ModelMixinTest < UnitTest
  test "module builder method with default configuration" do
    account_class = define_account_class
    account_class.include Rodauth::Rails.model(association_options: { dependent: nil })
    reflection = account_class.reflect_on_association(:password_reset_key)
    assert_nil reflection.options.fetch(:dependent)
  end

  test "module builder method with secondary configuration" do
    account_class = define_account_class
    account_class.include Rodauth::Rails.model(:json, association_options: { dependent: nil })
    reflection = account_class.reflect_on_association(:verification_key)
    assert_nil reflection.options.fetch(:dependent)
    refute account_class.reflect_on_association(:password_reset_key)
  end

  test "unknown configuration" do
    assert_raises Rodauth::Rails::Error do
      Rodauth::Rails.model(:unknown)
    end
  end

  private

  def define_account_class
    account_class = Class.new(ActiveRecord::Base)
    account_class.table_name = :accounts
    account_class
  end

  def teardown
    ActiveSupport::Dependencies.clear # clear cache used for :class_name association option
    super
  end
end
