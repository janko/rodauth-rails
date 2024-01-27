require "test_helper"

class ModelTest < IntegrationTest
  test "allows referencing custom columns for new accounts" do
    visit "/create-account"
    fill_in "Login", with: "foo@bar.com"
    fill_in "Password", with: "supersecret"
    fill_in "Confirm Password", with: "supersecret"
    click_on "Create Account"
  end
end
