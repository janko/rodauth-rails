# rodauth-rails

Provides Rails integration for the [Rodauth] authentication framework.

## Resources

Useful links:

* [Rodauth documentation](http://rodauth.jeremyevans.net/documentation.html)
* [Rails demo](https://github.com/janko/rodauth-demo-rails)

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

## Upgrading

For instructions on upgrading from previous rodauth-rails versions, see
[UPGRADING.md](/UPGRADING.md).

## Installation

Add the gem to your Gemfile:

```rb
gem "rodauth-rails", "~> 0.14"

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

This generator will create a Rodauth app with common authentication features
enabled, a database migration with tables required by those features, a mailer
with default templates, and a few other files.

Feel free to remove any features you don't need, along with their corresponding
tables. Afterwards, run the migration:

```sh
$ rails db:migrate
```

## Usage

### Routes

You can see the list of routes our Rodauth middleware handles:

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

Inside Rodauth configuration and the `route` block you can access Rails route
helpers through `#rails_routes`:

```rb
class RodauthApp < Rodauth::Rails::App
  configure do
    # ...
    login_redirect { rails_routes.activity_path }
    # ...
  end
end
```

### Current account

To be able to fetch currently authenticated account, you can define a
`#current_account` method that fetches the account id from session and
retrieves the corresponding account record:

```rb
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :current_account, if: -> { rodauth.logged_in? }

  private

  def current_account
    @current_account ||= Account.find(rodauth.session_value)
  rescue ActiveRecord::RecordNotFound
    rodauth.logout
    rodauth.login_required
  end
  helper_method :current_account # skip if inheriting from ActionController::API
end
```

This allows you to access the current account in controllers and views:

```erb
<p>Authenticated as: <%= current_account.email %></p>
```

### Requiring authentication

You'll likely want to require authentication for certain parts of your app,
redirecting the user to the login page if they're not logged in. You can do this
in your Rodauth app's routing block, which helps keep the authentication logic
encapsulated:

```rb
# app/lib/rodauth_app.rb
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

This will generate views for the default set of Rodauth features into the
`app/views/rodauth` directory, provided that `RodauthController` is set for the
main configuration.

You can pass a list of Rodauth features to the generator to create views for
these features (this will not remove or overwrite any existing views):

```sh
$ rails generate rodauth:views login create_account lockout otp
```

Or you can generate views for all features:

```sh
$ rails generate rodauth:views --all
```

Use `--name` to generate views for a different Rodauth configuration:

```sh
$ rails generate rodauth:views --name admin
```

#### Layout

To use different layouts for different Rodauth views, you can compare the
request path in the layout method:

```rb
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

### Mailer

The install generator will create `RodauthMailer` with default email templates,
and configure Rodauth features that send emails as part of the authentication
flow to use it.

```rb
# app/mailers/rodauth_mailer.rb
class RodauthMailer < ApplicationMailer
  def verify_account(recipient, email_link)
    # ...
  end
  def reset_password(recipient, email_link)
    # ...
  end
  def verify_login_change(recipient, old_login, new_login, email_link)
    # ...
  end
  def password_changed(recipient)
    # ...
  end
  # def email_auth(recipient, email_link)
  # ...
  # end
  # def unlock_account(recipient, email_link)
  # ...
  # end
end
```
```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  configure do
    # ...
    create_reset_password_email do
      RodauthMailer.reset_password(email_to, reset_password_email_link)
    end
    create_verify_account_email do
      RodauthMailer.verify_account(email_to, verify_account_email_link)
    end
    create_verify_login_change_email do |login|
      RodauthMailer.verify_login_change(login, verify_login_change_old_login, verify_login_change_new_login, verify_login_change_email_link)
    end
    create_password_changed_email do
      RodauthMailer.password_changed(email_to)
    end
    # create_email_auth_email do
    #   RodauthMailer.email_auth(email_to, email_auth_email_link)
    # end
    # create_unlock_account_email do
    #   RodauthMailer.unlock_account(email_to, unlock_account_email_link)
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
or a 3rd-party service for sending transactional emails, this two-phase API
might not be suitable. In this case, instead of overriding `#create_*_email`
and `#send_email`, override the `#send_*_email` methods instead, which are
required to send the email immediately. For example:

```rb
# app/workers/rodauth_mailer_worker.rb
class RodauthMailerWorker
  include Sidekiq::Worker

  def perform(name, *args)
    email = RodauthMailer.public_send(name, *args)
    email.deliver_now
  end
end
```
```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  configure do
    # ...
    # use `#send_*_email` method to be able to immediately enqueue email delivery
    send_reset_password_email do
      enqueue_email(:reset_password, email_to, reset_password_email_link)
    end
    # ...
    auth_class_eval do
      # custom method for enqueuing email delivery using our worker
      def enqueue_email(name, *args)
        db.after_commit do
          RodauthMailerWorker.perform_async(name, *args)
        end
      end
    end
    # ...
  end
end
```

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

### Model

The `Rodauth::Rails::Model` mixin can be included into the account model, which
defines a password attribute and associations for tables used by enabled
authentication features.

```rb
class Account < ApplicationRecord
  include Rodauth::Rails.model # or `Rodauth::Rails.model(:admin)`
end
```

#### Password attribute

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

#### Associations

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

### Multiple configurations

If you need to handle multiple types of accounts that require different
authentication logic, you can create additional configurations for them:

```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  # primary configuration
  configure do
    # ...
  end

  # alternative configuration
  configure(:admin) do
    # ... enable features ...
    prefix "/admin"
    session_key_prefix "admin_"
    remember_cookie_key "_admin_remember" # if using remember feature
    # ...
  end

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

Then in your application you can reference the secondary Rodauth instance:

```rb
rodauth(:admin).login_path #=> "/admin/login"
```

You'll likely want to save the information of which account belongs to which
configuration to the database. One way would be to have a separate table that
stores account types:

```sh
$ rails generate migration create_account_types
```
```rb
# db/migrate/*_create_account_types.rb
class CreateAccountTypes < ActiveRecord::Migration
  def change
    create_table :account_types do |t|
      t.references :account, foreign_key: { on_delete: :cascade }, null: false
      t.string :type, null: false
    end
  end
end
```
```sh
$ rails db:migrate
```

Then an entry would be inserted after account creation, and optionally whenever
Rodauth retrieves accounts you could filter only those belonging to the current
configuration:

```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  configure(:admin) do
    # ...
    after_create_account do
      db[:account_types].insert(account_id: account_id, type: "admin")
    end
    auth_class_eval do
      def account_ds(*)
        super.join(:account_types, account_id: :id).where(type: "admin")
      end
    end
    # ...
  end
end
```

#### Named auth classes

A `configure` block inside `Rodauth::Rails::App` will internally create an
anonymous `Rodauth::Auth` subclass, and register it under the given name.
However, you can also define the auth classes explicitly, by creating
subclasses of `Rodauth::Rails::Auth`:

```rb
# app/lib/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    # ... main configuration ...
  end
end
```
```rb
# app/lib/rodauth_admin.rb
class RodauthAdmin < Rodauth::Rails::Auth
  configure do
    # ...
    prefix "/admin"
    session_key_prefix "admin_"
    # ...
  end
end
```
```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  configure RodauthMain
  configure RodauthAdmin, :admin
  # ...
end
```

This allows having each configuration in a dedicated file, and named constants
improve introspection and error messages. You can also use inheritance to share
common settings:

```rb
# app/lib/rodauth_base.rb
class RodauthBase < Rodauth::Rails::Auth
  # common settings that can be shared between multiple configurations
  configure do
    enable :login, :logout
    login_return_to_requested_location? true
    logout_redirect "/"
    # ...
  end
end
```
```rb
# app/lib/rodauth_main.rb
class RodauthMain < RodauthBase # inherit common settings
  configure do
    # ... customize main ...
  end
end
```
```rb
# app/lib/rodauth_admin.rb
class RodauthAdmin < RodauthBase # inherit common settings
  configure do
    # ... customize admin ...
  end
end
```

Another benefit of explicit classes is that you can define custom methods
directly at the class level instead of inside an `auth_class_eval`:

```rb
# app/lib/rodauth_admin.rb
class RodauthAdmin < Rodauth::Rails::Auth
  configure do
    # ...
  end

  def superadmin?
    Role.where(account_id: session_id, type: "superadmin").any?
  end
end
```
```rb
# config/routes.rb
Rails.application.routes.draw do
  constraints Rodauth::Rails.authenticated(:admin) { |rodauth| rodauth.superadmin? } do
    mount Sidekiq::Web => "sidekiq"
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
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  configure do
    after_create_account do
      rails_controller_eval { setup_tracking(account_id) }
    end
  end
end
```

### Outside of a request

In some cases you might need to use Rodauth more programmatically. If you would
like to perform Rodauth operations outside of request context, Rodauth ships
with the [internal_request] feature just for that. The rodauth-rails gem
additionally updates the internal rack env hash with your
`config.action_mailer.default_url_options`, which is used for generating URLs.

If you need to access Rodauth methods not exposed as internal requests, you can
use `Rodauth::Rails.rodauth` to retrieve the Rodauth instance used by the
internal_request feature:

```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  configure do
    enable :internal_request # this is required
  end
end
```
```rb
account = Account.find_by!(email: "user@example.com")
rodauth = Rodauth::Rails.rodauth(account: account)

rodauth.compute_hmac("token") #=> "TpEJTKfKwqYvIDKWsuZhkhKlhaBXtR1aodskBAflD8U"
rodauth.open_account? #=> true
rodauth.two_factor_authentication_setup? #=> true
rodauth.password_meets_requirements?("foo") #=> false
rodauth.locked_out? #=> false
```

In addition to the `:account` option, the `Rodauth::Rails.rodauth`
method accepts any options supported by the internal_request feature.

```rb
Rodauth::Rails.rodauth(
  env: { "HTTP_USER_AGENT" => "programmatic" },
  session: { two_factor_auth_setup: true },
  params: { "param" => "value" }
)
```

Secondary Rodauth configurations are specified by passing the configuration
name:

```rb
Rodauth::Rails.rodauth(:admin)
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

## JSON API

To make Rodauth endpoints accessible via JSON API, enable the [`json`][json]
feature:

```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  configure do
    # ...
    enable :json
    only_json? true # accept only JSON requests (optional)
    # ...
  end
end
```

This will store account session data into the Rails session. If you rather want
stateless token-based authentication via the `Authorization` header, enable the
[`jwt`][jwt] feature (which builds on top of the `json` feature) and add the
[JWT gem] to the Gemfile:

```sh
$ bundle add jwt
```
```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  configure do
    # ...
    enable :jwt
    jwt_secret "<YOUR_SECRET_KEY>" # store the JWT secret in a safe place
    only_json? true # accept only JSON requests (optional)
    # ...
  end
end
```

The JWT token will be returned after each request to Rodauth routes. To also
return the JWT token on requests to your app's routes, you can add the
following code to your base controller:

```rb
class ApplicationController < ActionController::Base
  # ...
  after_action :set_jwt_token

  private

  def set_jwt_token
    if rodauth.use_jwt? && rodauth.valid_jwt?
      response.headers["Authorization"] = rodauth.session_jwt
    end
  end
  # ...
end
```

## OmniAuth

While Rodauth doesn't yet come with [OmniAuth] integration, we can build one
ourselves using the existing Rodauth API.

In order to allow the user to login via multiple external providers, let's
create an `account_identities` table that will have a many-to-one relationship
with the `accounts` table:

```sh
$ rails generate model AccountIdentity
```
```rb
# db/migrate/*_create_account_identities.rb
class CreateAccountIdentities < ActiveRecord::Migration
  def change
    create_table :account_identities do |t|
      t.references :account, null: false, foreign_key: { on_delete: :cascade }
      t.string :provider, null: false
      t.string :uid, null: false
      t.jsonb :info, null: false, default: {} # adjust JSON column type for your database

      t.timestamps

      t.index [:provider, :uid], unique: true
    end
  end
end
```
```rb
# app/models/account_identity.rb
class AcccountIdentity < ApplicationRecord
  belongs_to :account
end
```
```rb
# app/models/account.rb
class Account < ApplicationRecord
  has_many :identities, class_name: "AccountIdentity"
end
```

Let's assume we want to implement Facebook login, and have added the
corresponding OmniAuth strategy to the middleware stack, together with an
authorization link on the login form:

```rb
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, ENV["FACEBOOK_APP_ID"], ENV["FACEBOOK_APP_SECRET"],
    scope: "email", callback_path: "/auth/facebook/callback"
end
```
```erb
<%= link_to "Login via Facebook", "/auth/facebook" %>
```

Finally, let's implement the OmniAuth callback endpoint on our Rodauth
controller:

```rb
# config/routes.rb
Rails.application.routes.draw do
  # ...
  get "/auth/:provider/callback", to: "rodauth#omniauth"
end
```
```rb
# app/controllres/rodauth_controller.rb
class RodauthController < ApplicationController
  def omniauth
    auth = request.env["omniauth.auth"]

    # attempt to find existing identity directly
    identity = AccountIdentity.find_by(provider: auth["provider"], uid: auth["uid"])

    if identity
      # update any external info changes
      identity.update!(info: auth["info"])
      # set account from identity
      account = identity.account
    end

    # attempt to find an existing account by email
    account ||= Account.find_by(email: auth["info"]["email"])

    # disallow login if account is not verified
    if account && account.status != rodauth.account_open_status_value
      redirect_to rodauth.login_path, alert: rodauth.unverified_account_message
      return
    end

    # create new account if it doesn't exist
    unless account
      account = Account.create!(email: auth["info"]["email"], status: rodauth.account_open_status_value)
    end

    # create new identity if it doesn't exist
    unless identity
      account.identities.create!(provider: auth["provider"], uid: auth["uid"], info: auth["info"])
    end

    # login with Rodauth
    rodauth.account_from_login(account.email)
    rodauth.login("omniauth")
  end
end
```

## Configuring

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

## Custom extensions

When developing custom extensions for Rodauth inside your Rails project, it's
probably better to use plain modules, at least in the beginning, as Rodauth
feature design doesn't yet work well with Zeitwerk reloading.

Here is an example of an LDAP authentication extension that uses the
[simple_ldap_authenticator] gem.

```rb
# app/lib/rodauth_ldap.rb
module RodauthLdap
  def require_bcrypt?
    false
  end

  def password_match?(password)
    SimpleLdapAuthenticator.valid?(account[:email], password)
  end
end
```
```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  configure do
    # ...
    auth_class_eval do
      include RodauthLdap
    end
    # ...
  end
end
```

## Testing

System (browser) tests for Rodauth actions could look something like this:

```rb
# test/system/authentication_test.rb
require "test_helper"

class AuthenticationTest < ActionDispatch::SystemTestCase
  include ActiveJob::TestHelper
  driven_by :rack_test

  test "creating and verifying an account" do
    create_account
    assert_match "An email has been sent to you with a link to verify your account", page.text

    verify_account
    assert_match "Your account has been verified", page.text
  end

  test "logging in and logging out" do
    create_account(verify: true)

    logout
    assert_match "You have been logged out", page.text

    login
    assert_match "You have been logged in", page.text
  end

  private

  def create_account(email: "user@example.com", password: "secret", verify: false)
    visit "/create-account"
    fill_in "Login", with: email
    fill_in "Password", with: password
    fill_in "Confirm Password", with: password
    click_on "Create Account"
    verify_account if verify
  end

  def verify_account
    perform_enqueued_jobs # run enqueued email deliveries
    email = ActionMailer::Base.deliveries.last
    verify_account_link = email.body.to_s[/\S+verify-account\S+/]
    visit verify_account_link
    click_on "Verify Account"
  end

  def login(email: "user@example.com", password: "secret")
    visit "/login"
    fill_in "Login", with: email
    fill_in "Password", with: password
    click_on "Login"
  end

  def logout
    visit "/logout"
    click_on "Logout"
  end
end
```

While request tests in JSON API mode with JWT tokens could look something like
this:

```rb
# test/integration/authentication_test.rb
require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "creating and verifying an account" do
    create_account
    assert_response :success
    assert_match "An email has been sent to you with a link to verify your account", JSON.parse(body)["success"]

    verify_account
    assert_response :success
    assert_match "Your account has been verified", JSON.parse(body)["success"]
  end

  test "logging in and logging out" do
    create_account(verify: true)

    logout
    assert_response :success
    assert_match "You have been logged out", JSON.parse(body)["success"]

    login
    assert_response :success
    assert_match "You have been logged in", JSON.parse(body)["success"]
  end

  private

  def create_account(email: "user@example.com", password: "secret", verify: false)
    post "/create-account", as: :json, params: { login: email, password: password, "password-confirm": password }
    verify_account if verify
  end

  def verify_account
    perform_enqueued_jobs # run enqueued email deliveries
    email = ActionMailer::Base.deliveries.last
    verify_account_key = email.body.to_s[/verify-account\?key=(\S+)/, 1]
    post "/verify-account", as: :json, params: { key: verify_account_key }
  end

  def login(email: "user@example.com", password: "secret")
    post "/login", as: :json, params: { login: email, password: password }
  end

  def logout
    post "/logout", as: :json, headers: { "Authorization" => headers["Authorization"] }
  end
end
```

If you're delivering emails in the background, make sure to set Active Job
queue adapter to `:test` or `:inline`:

```rb
# config/environments/test.rb
Rails.application.configure do |config|
  # ...
  config.active_job.queue_adapter = :test # or :inline
  # ...
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
[JWT gem]: https://github.com/jwt/ruby-jwt
[Bootstrap]: https://getbootstrap.com/
[Roda]: http://roda.jeremyevans.net/
[HMAC]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-HMAC
[database authentication functions]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-Password+Hash+Access+Via+Database+Functions
[Rodauth migration]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-Creating+tables
[sequel-activerecord_connection]: https://github.com/janko/sequel-activerecord_connection
[plugin options]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-Plugin+Options
[hmac]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-HMAC
[OmniAuth]: https://github.com/omniauth/omniauth
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
