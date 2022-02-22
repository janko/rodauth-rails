require "test_helper"

class FlashTest < IntegrationTest
  test "redirect notice" do
    register

    assert_includes page.html, %(<p id="notice">An email has been sent to you with a link to verify your account</p>)
    refute_includes page.html, %(id="alert")

    visit "/"

    refute_includes page.html, %(id="alert")
    refute_includes page.html, %(id="notice")
  end

  test "redirect alert" do
    visit "/auth1"

    assert_includes page.html, %(<p id="alert">Please login to continue</p>)
    refute_includes page.html, %(id="notice")

    visit "/login"

    refute_includes page.html, %(id="alert")
    refute_includes page.html, %(id="notice")
  end

  test "now alert" do
    login

    assert_includes page.html, %(<p id="alert">There was an error logging in</p>)
    refute_includes page.html, %(id="notice")

    visit "/login"

    refute_includes page.html, %(id="alert")
    refute_includes page.html, %(id="notice")
  end

  test "halted now alert" do
    register(verify: true)
    logout

    4.times { login(password: "invalid") }

    assert_includes page.html, %(id="unlock-account-request-form")
    assert_includes page.html, %(<p id="alert">This account is currently locked out and cannot be logged in to</p>)

    visit "/"

    refute_includes page.html, %(id="alert")
    refute_includes page.html, %(id="notice")
  end

  test "controller redirect alert" do
    visit "/auth2"

    assert_includes page.html, %(<p id="alert">Please login to continue</p>)
    refute_includes page.html, %(id="notice")

    visit "/login"

    refute_includes page.html, %(id="alert")
    refute_includes page.html, %(id="notice")
  end

  test "preserving flash on double redirect" do
    register(password: "secret", verify: true)

    visit "/multifactor-manage"
    fill_in "Password", with: "secret"
    click_on "View Authentication Recovery Codes"
    fill_in "Password", with: "secret"
    click_on "Add Authentication Recovery Codes"
    assert_text "Additional authentication recovery codes have been added"

    logout
    login

    visit "/auth2"
    assert_equal "/recovery-auth", page.current_path
    assert_text "You need to authenticate via an additional factor before continuing"
  end
end
