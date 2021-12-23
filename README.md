# rodauth-rails

Provides Rails integration for the [Rodauth] authentication framework.

## Resources

Useful links:

* [Rodauth documentation](http://rodauth.jeremyevans.net/documentation.html)
* [Rails demo](https://github.com/janko/rodauth-demo-rails)
* [JSON API guide](https://github.com/janko/rodauth-rails/wiki/JSON-API)
* [OmniAuth guide](https://github.com/janko/rodauth-rails/wiki/OmniAuth)
* [Testing guide](https://github.com/janko/rodauth-rails/wiki/Testing)

Articles:

* [Rodauth: A Refreshing Authentication Solution for Ruby](https://janko.io/rodauth-a-refreshing-authentication-solution-for-ruby/)
* [Adding Authentication in Rails with Rodauth](https://janko.io/adding-authentication-in-rails-with-rodauth/)
* [Adding Multifactor Authentication in Rails with Rodauth](https://janko.io/adding-multifactor-authentication-in-rails-with-rodauth/)
* [How to build an OIDC provider using rodauth-oauth on Rails](https://honeyryderchuck.gitlab.io/httpx/2021/03/15/oidc-provider-on-rails-using-rodauth-oauth.html)

## Why Rodauth?

There are already several popular authentication solutions for Rails (Devise,
Sorcery, Clearance, Authlogic), so why would you choose Rodauth? Here are some
of the advantages that stand out for me:

* multifactor authentication ([TOTP][otp], [SMS codes][sms_codes], [recovery codes][recovery_codes], [WebAuthn][webauthn])
* standardized [JSON API support][json] for every feature (including [JWT][jwt])
* enterprise security features ([password complexity][password_complexity], [disallow password reuse][disallow_password_reuse], [password expiration][password_expiration], [session expiration][session_expiration], [single session][single_session], [account expiration][account_expiration])
* [email authentication][email_auth] (aka "passwordless")
* [audit logging][audit_logging] (for any action)
* ability to protect password hashes even in case of SQL injection ([more details][password protection])
* additional bruteforce protection for tokens ([more details][bruteforce tokens])
* uniform configuration DSL (any setting can be static or dynamic)
* consistent before/after hooks around everything
* dedicated object encapsulating all authentication logic

One commmon concern is the fact that, unlike most other authentication
frameworks for Rails, Rodauth uses [Sequel] for database interaction instead of
Active Record. There are good reasons for this, and to make Rodauth work
smoothly alongside Active Record, rodauth-rails configures Sequel to [reuse
Active Record's database connection][sequel-activerecord_connection].

## Installation

Add the gem to your Gemfile:

```rb
gem "rodauth-rails", "~> 0.18"

# gem "jwt",      require: false # for JWT feature
# gem "rotp",     require: false # for OTP feature
# gem "rqrcode",  require: false # for OTP feature
# gem "webauthn", require: false # for WebAuthn feature
```

Then run `bundle install`.

Next, run the install generator:

```sh
$ rails generate rodauth:install
```

Or if you want Rodauth endpoints to be exposed via JSON API:

```sh
$ rails generate rodauth:install --json # regular authentication using the Rails session
# or
$ rails generate rodauth:install --jwt # token authentication via the "Authorization" header
$ bundle add jwt
```

This generator will create a Rodauth app and configuration with common
authentication features enabled, a database migration with tables required by
those features, a mailer with default templates, and a few other files.

Feel free to remove any features you don't need, along with their corresponding
tables. Afterwards, run the migration:

```sh
$ rails db:migrate
```

For your mailer to be able to generate email links, you'll need to set up
default URL options in each environment. Here is a possible configuration for
`config/environments/development.rb`:

```rb
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

## Usage

### Routes

Because requests to Rodauth endpoints are handled by the Rodauth middleware, and
not a Rails controller, Rodauth routes will not show in `rails routes`.

Use the `rodauth:routes` rake task to view the list of endpoints based on
currently loaded features:

```sh
$ rails rodauth:routes
```
```
Routes handled by RodauthApp:

  /login                   rodauth.login_path
  /create-account          rodauth.create_account_path
  /verify-account-resend   rodauth.verify_account_resend_path
  /verify-account          rodauth.verify_account_path
  /change-password         rodauth.change_password_path
  /change-login            rodauth.change_login_path
  /logout                  rodauth.logout_path
  /remember                rodauth.remember_path
  /reset-password-request  rodauth.reset_password_request_path
  /reset-password          rodauth.reset_password_path
  /verify-login-change     rodauth.verify_login_change_path
  /close-account           rodauth.close_account_path
```

Using this information, you can add some basic authentication links to your
navigation header:

```erb
<% if rodauth.logged_in? %>
  <%= link_to "Sign out", rodauth.logout_path, method: :post %>
<% else %>
  <%= link_to "Sign in", rodauth.login_path %>
  <%= link_to "Sign up", rodauth.create_account_path %>
<% end %>
```

These routes are fully functional, feel free to visit them and interact with the
pages. The templates that ship with Rodauth aim to provide a complete
authentication experience, and the forms use [Bootstrap] markup.

### Current account

The `#current_account` method is defined in controllers and views, which
returns the model instance of the currently logged in account.

```rb
current_account #=> #<Account id=123 email="user@example.com">
current_account.email #=> "user@example.com"
```

If the account doesn't exist in the database, the session will be cleared and
login required.

Pass the configuration name to retrieve accounts belonging to other Rodauth
configurations:

```rb
current_account(:admin)
```

#### Custom account model

The `#current_account` method will try to infer the account model class from
the configured table name. If that fails, you can set the account model
manually:

```rb
# app/misc/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    # ...
    rails_account_model Authentication::Account # custom model name
  end
end
```

### Requiring authentication

You'll likely want to require authentication for certain parts of your app,
redirecting the user to the login page if they're not logged in. You can do this
in your Rodauth app's routing block, which helps keep the authentication logic
encapsulated:

```rb
# app/misc/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  # ...
  route do |r|
    # ...
    r.rodauth # route rodauth requests

    # require authentication for /dashboard/* and /account/* routes
    if r.path.start_with?("/dashboard") || r.path.start_with?("/account")
      rodauth.require_authentication # redirect to login page if not authenticated
    end
  end
end
```

You can also require authentication at the controller layer:

```rb
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  private

  def authenticate
    rodauth.require_authentication # redirect to login page if not authenticated
  end
end
```
```rb
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate
end
```
```rb
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate, except: [:index, :show]
end
```

#### Routing constraints

In some cases it makes sense to require authentication at the Rails router
level. You can do this via the built-in `authenticated` routing constraint:

```rb
# config/routes.rb
Rails.application.routes.draw do
  constraints Rodauth::Rails.authenticated do
    # ... authenticated routes ...
  end
end
```

If you want additional conditions, you can pass in a block, which is
called with the Rodauth instance:

```rb
# config/routes.rb
Rails.application.routes.draw do
  # require multifactor authentication to be setup
  constraints Rodauth::Rails.authenticated { |rodauth| rodauth.uses_two_factor_authentication? } do
    # ...
  end
end
```

You can specify the Rodauth configuration by passing the configuration name:

```rb
# config/routes.rb
Rails.application.routes.draw do
  constraints Rodauth::Rails.authenticated(:admin) do
    # ...
  end
end
```

If you need something more custom, you can always create the routing constraint
manually:

```rb
# config/routes.rb
Rails.application.routes.draw do
  constraints -> (r) { !r.env["rodauth"].logged_in? } do # or "rodauth.admin"
    # routes when the user is not logged in
  end
end
```

### Views

The templates built into Rodauth are useful when getting started, but soon
you'll want to start editing the markup. You can run the following command to
copy Rodauth templates into your Rails app:

```sh
$ rails generate rodauth:views
```

This will generate views for Rodauth features you have currently enabled into
the `app/views/rodauth` directory, provided that `RodauthController` is set for
the main configuration.

You can pass a list of Rodauth features to the generator to create views for
these features (this will not remove any existing views):

```sh
$ rails generate rodauth:views login create_account lockout otp
```

Or you can generate views for all features:

```sh
$ rails generate rodauth:views --all
```

Use `--name` to generate views for a different Rodauth configuration:

```sh
$ rails generate rodauth:views webauthn --name admin
```

#### Page titles

The generated view templates use `content_for(:title)` to store Rodauth's page
titles, which you can then retrieve in your layout template to set the page
title:

```erb
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title><%= content_for(:title) %></title>
    <!-- ... -->
  </head>
  <body>
    <!-- ... -->
  </body>
</html>
```

#### Layout

To use different layouts for different Rodauth views, you can compare the
request path in the layout method:

```rb
# app/controllers/rodauth_controller.rb
class RodauthController < ApplicationController
  layout :rodauth_layout

  private

  def rodauth_layout
    case request.path
    when rodauth.login_path,
         rodauth.create_account_path,
         rodauth.verify_account_path,
         rodauth.reset_password_path,
         rodauth.reset_password_request_path
      "authentication"
    else
      "dashboard"
    end
  end
end
```

#### Turbo

[Turbo] has been disabled by default on all built-in and generated view
templates, because some Rodauth actions (multi-phase login, adding recovery
codes) aren't Turbo-compatible, as they return 200 responses on POST requests.

That being said, most of Rodauth *is* Turbo-compatible, so feel free to enable
Turbo for actions where you want to use it.

### Mailer

The install generator will create `RodauthMailer` with default email templates,
and configure Rodauth features that send emails as part of the authentication
flow to use it.

```rb
# app/mailers/rodauth_mailer.rb
class RodauthMailer < ApplicationMailer
  def verify_account(account_id, key)
    # ...
  end
  def reset_password(account_id, key)
    # ...
  end
  def verify_login_change(account_id, old_login, new_login, key)
    # ...
  end
  def password_changed(account_id)
    # ...
  end
  # def email_auth(account_id, key)
  # ...
  # end
  # def unlock_account(account_id, key)
  # ...
  # end
end
```
```rb
# app/misc/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    # ...
    create_reset_password_email do
      RodauthMailer.reset_password(account_id, reset_password_key_value)
    end
    create_verify_account_email do
      RodauthMailer.verify_account(account_id, verify_account_key_value)
    end
    create_verify_login_change_email do |_login|
      RodauthMailer.verify_login_change(account_id, verify_login_change_old_login, verify_login_change_new_login, verify_login_change_key_value)
    end
    create_password_changed_email do
      RodauthMailer.password_changed(account_id)
    end
    # create_email_auth_email do
    #   RodauthMailer.email_auth(account_id, email_auth_key_value)
    # end
    # create_unlock_account_email do
    #   RodauthMailer.unlock_account(account_id, unlock_account_key_value)
    # end
    send_email do |email|
      # queue email delivery on the mailer after the transaction commits
      db.after_commit { email.deliver_later }
    end
    # ...
  end
end
```

This configuration calls `#deliver_later`, which uses Active Job to deliver
emails in a background job. It's generally recommended to send emails
asynchronously for better request throughput and the ability to retry
deliveries. However, if you want to send emails synchronously, you can modify
the configuration to call `#deliver_now` instead.

If you're using a background processing library without an Active Job adapter,
or a 3rd-party service for sending transactional emails, see [this wiki
page][custom mailer worker] on how to set it up.

### Migrations

The install generator will create a migration for tables used by the Rodauth
features enabled by default. For any additional features, you can use the
migration generator to create the corresponding tables:

```sh
$ rails generate rodauth:migration otp sms_codes recovery_codes
```
```rb
# db/migration/*_create_rodauth_otp_sms_codes_recovery_codes.rb
class CreateRodauthOtpSmsCodesRecoveryCodes < ActiveRecord::Migration
  def change
    create_table :account_otp_keys do |t| ... end
    create_table :account_sms_codes do |t| ... end
    create_table :account_recovery_codes do |t| ... end
  end
end
```

#### Custom migration name

You can change the default migration name:

```sh
$ rails generate rodauth:migration email_auth --name create_account_email_auth_keys
```
```rb
# db/migration/*_create_account_email_auth_keys
class CreateAccountEmailAuthKeys < ActiveRecord::Migration
  def change
    create_table :account_email_auth_keys do |t| ... end
  end
end
```

## Model

The `Rodauth::Rails::Model` mixin can be included into the account model, which
defines a password attribute and associations for tables used by enabled
authentication features.

```rb
class Account < ApplicationRecord
  include Rodauth::Rails.model # or `Rodauth::Rails.model(:admin)`
end
```

### Password attribute

Regardless of whether you're storing the password hash in a column in the
accounts table, or in a separate table, the `#password` attribute can be used
to set or clear the password hash.

```rb
account = Account.create!(email: "user@example.com", password: "secret")

# when password hash is stored in a column on the accounts table
account.password_hash #=> "$2a$12$k/Ub1I2iomi84RacqY89Hu4.M0vK7klRnRtzorDyvOkVI.hKhkNw."

# when password hash is stored in a separate table
account.password_hash #=> #<Account::PasswordHash...> (record from `account_password_hashes` table)
account.password_hash.password_hash #=> "$2a$12$k/Ub1..." (inaccessible when using database authentication functions)

account.password = nil # clears password hash
account.password_hash #=> nil
```

Note that the password attribute doesn't come with validations, making it
unsuitable for forms. It was primarily intended to allow easily creating
accounts in development console and in tests.

### Associations

The `Rodauth::Rails::Model` mixin defines associations for Rodauth tables
associated to the accounts table:

```rb
account.remember_key #=> #<Account::RememberKey> (record from `account_remember_keys` table)
account.active_session_keys #=> [#<Account::ActiveSessionKey>,...] (records from `account_active_session_keys` table)
```

You can also reference the associated models directly:

```rb
# model referencing the `account_authentication_audit_logs` table
Account::AuthenticationAuditLog.where(message: "login").group(:account_id)
```

The associated models define the inverse `belongs_to :account` association:

```rb
Account::ActiveSessionKey.includes(:account).map(&:account)
```

Here is an example of using associations to create a method that returns
whether the account has multifactor authentication enabled:

```rb
class Account < ApplicationRecord
  include Rodauth::Rails.model

  def mfa_enabled?
    otp_key || (sms_code && sms_code.num_failures.nil?) || recovery_codes.any?
  end
end
```

Here is another example of creating a query scope that selects accounts with
multifactor authentication enabled:

```rb
class Account < ApplicationRecord
  include Rodauth::Rails.model

  scope :otp_setup, -> { where(otp_key: OtpKey.all) }
  scope :sms_codes_setup, -> { where(sms_code: SmsCode.where(num_failures: nil)) }
  scope :recovery_codes_setup, -> { where(recovery_codes: RecoveryCode.all) }
  scope :mfa_enabled, -> { merge(otp_setup.or(sms_codes_setup).or(recovery_codes_setup)) }
end
```

#### Association reference

Below is a list of all associations defined depending on the features loaded:

| Feature                 | Association                  | Type       | Model                    | Table (default)                     |
| :------                 | :----------                  | :---       | :----                    | :----                               |
| account_expiration      | `:activity_time`             | `has_one`  | `ActivityTime`           | `account_activity_times`            |
| active_sessions         | `:active_session_keys`       | `has_many` | `ActiveSessionKey`       | `account_active_session_keys`       |
| audit_logging           | `:authentication_audit_logs` | `has_many` | `AuthenticationAuditLog` | `account_authentication_audit_logs` |
| disallow_password_reuse | `:previous_password_hashes`  | `has_many` | `PreviousPasswordHash`   | `account_previous_password_hashes`  |
| email_auth              | `:email_auth_key`            | `has_one`  | `EmailAuthKey`           | `account_email_auth_keys`           |
| jwt_refresh             | `:jwt_refresh_keys`          | `has_many` | `JwtRefreshKey`          | `account_jwt_refresh_keys`          |
| lockout                 | `:lockout`                   | `has_one`  | `Lockout`                | `account_lockouts`                  |
| lockout                 | `:login_failure`             | `has_one`  | `LoginFailure`           | `account_login_failures`            |
| otp                     | `:otp_key`                   | `has_one`  | `OtpKey`                 | `account_otp_keys`                  |
| password_expiration     | `:password_change_time`      | `has_one`  | `PasswordChangeTime`     | `account_password_change_times`     |
| recovery_codes          | `:recovery_codes`            | `has_many` | `RecoveryCode`           | `account_recovery_codes`            |
| remember                | `:remember_key`              | `has_one`  | `RememberKey`            | `account_remember_keys`             |
| reset_password          | `:password_reset_key`        | `has_one`  | `PasswordResetKey`       | `account_password_reset_keys`       |
| single_session          | `:session_key`               | `has_one`  | `SessionKey`             | `account_session_keys`              |
| sms_codes               | `:sms_code`                  | `has_one`  | `SmsCode`                | `account_sms_codes`                 |
| verify_account          | `:verification_key`          | `has_one`  | `VerificationKey`        | `account_verification_keys`         |
| verify_login_change     | `:login_change_key`          | `has_one`  | `LoginChangeKey`         | `account_login_change_keys`         |
| webauthn                | `:webauthn_keys`             | `has_many` | `WebauthnKey`            | `account_webauthn_keys`             |
| webauthn                | `:webauthn_user_id`          | `has_one`  | `WebauthnUserId`         | `account_webauthn_user_ids`         |

Note that some Rodauth tables use composite primary keys, which Active Record
doesn't support out of the box. For associations to work properly, you might
need to add the [composite_primary_keys] gem to your Gemfile.

#### Association options

By default, all associations except for audit logs have `dependent: :destroy`
set, to allow for easy deletion of account records in the console. You can use
`:association_options` to modify global or per-association options:

```rb
# don't auto-delete associations when account model is deleted
Rodauth::Rails.model(association_options: { dependent: nil })

# require authentication audit logs to be eager loaded before retrieval
Rodauth::Rails.model(association_options: -> (name) {
  { strict_loading: true } if name == :authentication_audit_logs
})
```

## Multiple configurations

If you need to handle multiple types of accounts that require different
authentication logic, you can create new configurations for them. This
is done by creating new `Rodauth::Rails::Auth` subclasses, and registering
them under a name.

```rb
# app/misc/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  # primary configuration
  configure RodauthMain

  # secondary configuration
  configure RodauthAdmin, :admin

  route do |r|
    r.rodauth

    r.on "admin" do
      r.rodauth(:admin)
      break # allow routing of other /admin/* requests to continue to Rails
    end

    # ...
  end
end
```
```rb
# app/misc/rodauth_admin.rb
class RodauthAdmin < Rodauth::Rails::Auth
  configure do
    # ... enable features ...
    prefix "/admin"
    session_key_prefix "admin_"
    remember_cookie_key "_admin_remember" # if using remember feature
    # ...

    # search views in `app/views/admin/rodauth` directory
    rails_controller { Admin::RodauthController }
  end
end
```
```rb
# app/controllers/admin/rodauth_controller.rb
class Admin::RodauthController < ApplicationController
end
```

Then in your application you can reference the secondary Rodauth instance:

```rb
rodauth(:admin).login_path #=> "/admin/login"
```

You'll likely want to save the information of which account belongs to which
configuration to the database. See [this guide][account types] on how you can do
that.

### Sharing configuration

If there are common settings that you want to share between Rodauth
configurations, you can do so via inheritance:

```rb
# app/misc/rodauth_base.rb
class RodauthBase < Rodauth::Rails::Auth
  # common settings that are shared between multiple configurations
  configure do
    enable :login, :logout
    login_return_to_requested_location? true
    logout_redirect "/"
    # ...
  end
end
```
```rb
# app/misc/rodauth_main.rb
class RodauthMain < RodauthBase # inherit common settings
  configure do
    # ... customize main ...
  end
end
```
```rb
# app/misc/rodauth_admin.rb
class RodauthAdmin < RodauthBase # inherit common settings
  configure do
    # ... customize admin ...
  end
end
```

## Outside of a request

### Calling actions

In some cases you might need to use Rodauth more programmatically. If you want
to perform authentication operations outside of request context, Rodauth ships
with the [internal_request] feature just for that.

```rb
# app/misc/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    enable :internal_request
  end
end
```
```rb
# primary configuration
RodauthApp.rodauth.create_account(login: "user@example.com", password: "secret")
RodauthApp.rodauth.verify_account(account_login: "user@example.com")

# secondary configuration
RodauthApp.rodauth(:admin).close_account(account_login: "user@example.com")
```

The rodauth-rails gem additionally updates the internal rack env hash with your
`config.action_mailer.default_url_options`, which is used for generating email
links.

### Generating URLs

For generating authentication URLs outside of a request use the
[path_class_methods] plugin:

```rb
# app/misc/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    enable :path_class_methods
    create_account_route "register"
  end
end
```
```rb
# primary configuration
RodauthApp.rodauth.create_account_path # => "/register"
RodauthApp.rodauth.verify_account_url(key: "abc123") #=> "https://example.com/verify-account?key=abc123"

# secondary configuration
RodauthApp.rodauth(:admin).close_account_path(foo: "bar") #=> "/admin/close-account?foo=bar"
```

### Calling instance methods

If you need to access Rodauth methods not exposed as internal requests, you can
use `Rodauth::Rails.rodauth` to retrieve the Rodauth instance used by the
internal_request feature:

```rb
# app/misc/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    enable :internal_request # this is required
  end
end
```
```rb
account = Account.find_by!(email: "user@example.com")
rodauth = Rodauth::Rails.rodauth(account: account) #=> #<RodauthMain::InternalRequest ...>

rodauth.compute_hmac("token") #=> "TpEJTKfKwqYvIDKWsuZhkhKlhaBXtR1aodskBAflD8U"
rodauth.open_account? #=> true
rodauth.two_factor_authentication_setup? #=> true
rodauth.password_meets_requirements?("foo") #=> false
rodauth.locked_out? #=> false
```

In addition to the `:account` option, the `Rodauth::Rails.rodauth`
method accepts any options supported by the internal_request feature.

```rb
# main configuration
Rodauth::Rails.rodauth(env: { "HTTP_USER_AGENT" => "programmatic" })
Rodauth::Rails.rodauth(session: { two_factor_auth_setup: true })

# secondary configuration
Rodauth::Rails.rodauth(:admin, params: { "param" => "value" })
```

## How it works

### Middleware

rodauth-rails inserts a `Rodauth::Rails::Middleware` into your middleware
stack, which calls your Rodauth app for each request, before the request
reaches the Rails router.

```sh
$ rails middleware
...
use Rodauth::Rails::Middleware
run MyApp::Application.routes
```

The Rodauth app stores the `Rodauth::Auth` instance in the Rack env hash, which
is then available in your Rails app:

```rb
request.env["rodauth"]       #=> #<Rodauth::Auth>
request.env["rodauth.admin"] #=> #<Rodauth::Auth> (if using multiple configurations)
```

For convenience, this object can be accessed via the `#rodauth` method in views
and controllers:

```rb
class MyController < ApplicationController
  def my_action
    rodauth         #=> #<Rodauth::Auth>
    rodauth(:admin) #=> #<Rodauth::Auth> (if using multiple configurations)
  end
end
```
```erb
<% rodauth         #=> #<Rodauth::Auth> %>
<% rodauth(:admin) #=> #<Rodauth::Auth> (if using multiple configurations) %>
```

### App

The `Rodauth::Rails::App` class is a [Roda] subclass that provides Rails
integration for Rodauth:

* uses Action Dispatch flash instead of Roda's
* uses Action Dispatch CSRF protection instead of Roda's
* sets [HMAC] secret to Rails' secret key base
* uses Action Controller for rendering templates
* runs Action Controller callbacks & rescue handlers around Rodauth actions
* uses Action Mailer for sending emails

The `configure` method wraps configuring the Rodauth plugin, forwarding
any additional [plugin options].

```rb
class RodauthApp < Rodauth::Rails::App
  configure { ... }             # defining default Rodauth configuration
  configure(json: true) { ... } # passing options to the Rodauth plugin
  configure(:admin) { ... }     # defining multiple Rodauth configurations
end
```

The `route` block is provided by Roda, and it's called on each request before
it reaches the Rails router.

```rb
class RodauthApp < Rodauth::Rails::App
  route do |r|
    # ... called before each request ...
  end
end
```

Since `Rodauth::Rails::App` is just a Roda subclass, you can do anything you
would with a Roda app, such as loading additional Roda plugins:

```rb
class RodauthApp < Rodauth::Rails::App
  plugin :request_headers # easier access to request headers
  plugin :typecast_params # methods for conversion of request params
  plugin :default_headers, { "Foo" => "Bar" }
  # ...
end
```

### Sequel

Rodauth uses the [Sequel] library for database queries, due to more advanced
database usage (SQL expressions, database-agnostic date arithmetic, SQL
function calls).

If ActiveRecord is used in the application, the `rodauth:install` generator
will have automatically configured Sequel to reuse ActiveRecord's database
connection, using the [sequel-activerecord_connection] gem.

This means that, from the usage perspective, Sequel can be considered just
as an implementation detail of Rodauth.

## Configuring

### Configuration methods

The `rails` feature rodauth-rails loads provides the following configuration
methods:

| Name                        | Description                                                        |
| :----                       | :----------                                                        |
| `rails_render(**options)`   | Renders the template with given render options.                    |
| `rails_csrf_tag`            | Hidden field added to Rodauth templates containing the CSRF token. |
| `rails_csrf_param`          | Value of the `name` attribute for the CSRF tag.                    |
| `rails_csrf_token`          | Value of the `value` attribute for the CSRF tag.                   |
| `rails_check_csrf!`         | Verifies the authenticity token for the current request.           |
| `rails_controller_instance` | Instance of the controller with the request env context.           |
| `rails_controller`          | Controller class to use for rendering and CSRF protection.         |
| `rails_account_model`       | Model class connected with the accounts table.                     |

### General configuration

The `Rodauth::Rails` module has a few config settings available as well:

| Name         | Description                                                                                         |
| :-----       | :----------                                                                                         |
| `app`        | Constant name of your Rodauth app, which is called by the middleware.                               |
| `middleware` | Whether to insert the middleware into the Rails application's middleware stack. Defaults to `true`. |

```rb
# config/initializers/rodauth.rb
Rodauth::Rails.configure do |config|
  config.app = "RodauthApp"
  config.middleware = true
end
```

For the list of configuration methods provided by Rodauth, see the [feature
documentation].

### Defining custom methods

All Rodauth configuration methods are just syntax sugar for defining instance
methods on the auth class. You can also define your own custom methods on the
auth class:

```rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    password_match? { |password| ldap_valid?(password) }
  end

  # Example external identities table
  def identities
    db[:account_identities].where(account_id: account_id).all
  end

  private

  # Example LDAP authentication
  def ldap_valid?(password)
    SimpleLdapAuthenticator.valid?(account[:email], password)
  end
end
```
```rb
rodauth.identities #=> [{ provider: "facebook", uid: "abc123", ... }, ...]
```

### Rails URL helpers

Inside Rodauth configuration and the `route` block you can access Rails route
helpers through `#rails_routes`:

```rb
# app/misc/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    login_redirect { rails_routes.activity_path }
  end
end
```

### Calling controller methods

When using Rodauth before/after hooks or generally overriding your Rodauth
configuration, in some cases you might want to call methods defined on your
controllers. You can do so with `rails_controller_eval`, for example:

```rb
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  private
  def setup_tracking(account_id)
    # ... some implementation ...
  end
end
```
```rb
# app/misc/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    after_create_account do
      rails_controller_eval { setup_tracking(account_id) }
    end
  end
end
```

### Single-file configuration

If you would prefer to have all Rodauth logic contained inside a single file,
you call `Rodauth::Rails::App.configure` with a block, which will create an
anonymous auth class.

```rb
# app/misc/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  # primary configuration
  configure do
    enable :login, :logout, :create_account, :verify_account
    # ...
  end

  # secondary configuration
  configure(:admin) do
    enable :email_auth, :single_session
    # ...
  end

  route do |r|
    # ...
  end
end
```

## Rodauth defaults

rodauth-rails changes some of the default Rodauth settings for easier setup:

### Database functions

By default, on PostgreSQL, MySQL, and Microsoft SQL Server Rodauth uses
database functions to access password hashes, with the user running the
application unable to get direct access to password hashes. This reduces the
risk of an attacker being able to access password hashes and use them to attack
other sites.

While this is useful additional security, it is also more complex to set up and
to reason about, as it requires having two different database users and making
sure the correct migration is run for the correct user.

To keep with Rails' "convention over configuration" doctrine, rodauth-rails
disables the use of database functions, though you can always turn it back on.

```rb
use_database_authentication_functions? true
```

To create the database functions, pass the Sequel database object into the
Rodauth method for creating database functions:

```rb
# db/migrate/*_create_rodauth_database_functions.rb
require "rodauth/migrations"

class CreateRodauthDatabaseFunctions < ActiveRecord::Migration
  def up
    Rodauth.create_database_authentication_functions(DB)
  end

  def down
    Rodauth.drop_database_authentication_functions(DB)
  end
end
```

### Account statuses

The recommended [Rodauth migration] stores possible account status values in a
separate table, and creates a foreign key on the accounts table, which ensures
only a valid status value will be persisted.

Unfortunately, this doesn't work when the database is restored from the schema
file, in which case the account statuses table will be empty. This happens in
tests by default, but it's also commonly done in development.

To address this, rodauth-rails modifies the setup to store account status text
directly in the accounts table. If you're worried about invalid status values
creeping in, you may use enums instead. Alternatively, you can always go back
to the setup recommended by Rodauth.

```rb
# in the migration:
create_table :account_statuses do |t|
  t.string :name, null: false, unique: true
end
execute "INSERT INTO account_statuses (id, name) VALUES (1, 'Unverified'), (2, 'Verified'), (3, 'Closed')"

create_table :accounts do |t|
  # ...
  t.references :status, foreign_key: { to_table: :account_statuses }, null: false, default: 1
  # ...
end
```
```diff
configure do
  # ...
- account_status_column :status
- account_unverified_status_value "unverified"
- account_open_status_value "verified"
- account_closed_status_value "closed"
  # ...
end
```

### Deadline values

To simplify changes to the database schema, rodauth-rails configures Rodauth
to set deadline values for various features in Ruby, instead of relying on
the database to set default column values.

You can easily change this back:

```rb
set_deadline_values? false
```

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the rodauth-rails project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the [code of
conduct](https://github.com/janko/rodauth-rails/blob/master/CODE_OF_CONDUCT.md).

[Rodauth]: https://github.com/jeremyevans/rodauth
[Sequel]: https://github.com/jeremyevans/sequel
[feature documentation]: http://rodauth.jeremyevans.net/documentation.html
[Bootstrap]: https://getbootstrap.com/
[Roda]: http://roda.jeremyevans.net/
[HMAC]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-HMAC
[database authentication functions]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-Password+Hash+Access+Via+Database+Functions
[Rodauth migration]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-Creating+tables
[sequel-activerecord_connection]: https://github.com/janko/sequel-activerecord_connection
[plugin options]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-Plugin+Options
[hmac]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-HMAC
[otp]: http://rodauth.jeremyevans.net/rdoc/files/doc/otp_rdoc.html
[sms_codes]: http://rodauth.jeremyevans.net/rdoc/files/doc/sms_codes_rdoc.html
[recovery_codes]: http://rodauth.jeremyevans.net/rdoc/files/doc/recovery_codes_rdoc.html
[webauthn]: http://rodauth.jeremyevans.net/rdoc/files/doc/webauthn_rdoc.html
[json]: http://rodauth.jeremyevans.net/rdoc/files/doc/json_rdoc.html
[jwt]: http://rodauth.jeremyevans.net/rdoc/files/doc/jwt_rdoc.html
[email_auth]: http://rodauth.jeremyevans.net/rdoc/files/doc/email_auth_rdoc.html
[audit_logging]: http://rodauth.jeremyevans.net/rdoc/files/doc/audit_logging_rdoc.html
[password protection]: https://github.com/jeremyevans/rodauth#label-Password+Hash+Access+Via+Database+Functions
[bruteforce tokens]: https://github.com/jeremyevans/rodauth#label-Tokens
[password_complexity]: http://rodauth.jeremyevans.net/rdoc/files/doc/password_complexity_rdoc.html
[disallow_password_reuse]: http://rodauth.jeremyevans.net/rdoc/files/doc/disallow_password_reuse_rdoc.html
[password_expiration]: http://rodauth.jeremyevans.net/rdoc/files/doc/password_expiration_rdoc.html
[session_expiration]: http://rodauth.jeremyevans.net/rdoc/files/doc/session_expiration_rdoc.html
[single_session]: http://rodauth.jeremyevans.net/rdoc/files/doc/single_session_rdoc.html
[account_expiration]: http://rodauth.jeremyevans.net/rdoc/files/doc/account_expiration_rdoc.html
[simple_ldap_authenticator]: https://github.com/jeremyevans/simple_ldap_authenticator
[internal_request]: http://rodauth.jeremyevans.net/rdoc/files/doc/internal_request_rdoc.html
[composite_primary_keys]: https://github.com/composite-primary-keys/composite_primary_keys
[path_class_methods]: https://rodauth.jeremyevans.net/rdoc/files/doc/path_class_methods_rdoc.html
[account types]: https://github.com/janko/rodauth-rails/wiki/Account-Types
[custom mailer worker]: https://github.com/janko/rodauth-rails/wiki/Custom-Mailer-Worker
[Turbo]: https://turbo.hotwired.dev/
