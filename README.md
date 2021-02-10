# rodauth-rails

Provides Rails integration for the [Rodauth] authentication framework.

## Table of contents

* [Resources](#resources)
* [Why Rodauth?](#why-rodauth)
* [Upgrading](#upgrading)
* [Installation](#installation)
* [Usage](#usage)
  - [Routes](#routes)
  - [Current account](#current-account)
  - [Requiring authentication](#requiring-authentication)
  - [Views](#views)
  - [Mailer](#mailer)
  - [Migrations](#migrations)
  - [Multiple configurations](#multiple-configurations)
  - [Calling controller methods](#calling-controller-methods)
  - [Rodauth instance](#rodauth-instance)
* [How it works](#how-it-works)
  - [Middleware](#middleware)
  - [App](#app)
  - [Sequel](#sequel)
* [JSON API](#json-api)
* [OmniAuth](#omniauth)
* [Configuring](#configuring)
* [Custom extensions](#custom-extensions)
* [Testing](#testing)
* [Rodauth defaults](#rodauth-defaults)
  - [Database functions](#database-functions)
  - [Account statuses](#account-statuses)

## Resources

Useful links:

* [Rodauth documentation](http://rodauth.jeremyevans.net/documentation.html)
* [Rails demo](https://github.com/janko/rodauth-demo-rails)

Articles:

* [Rodauth: A Refreshing Authentication Solution for Ruby](https://janko.io/rodauth-a-refreshing-authentication-solution-for-ruby/)
* [Adding Authentication in Rails with Rodauth](https://janko.io/adding-authentication-in-rails-with-rodauth/)
* [Adding Multifactor Authentication in Rails with Rodauth](https://janko.io/adding-multifactor-authentication-in-rails-with-rodauth/)

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

## Upgrading

### Upgrading to 0.7.0

Starting from version 0.7.0, rodauth-rails now correctly detects Rails
application's `secret_key_base` when setting default `hmac_secret`, including
when it's set via credentials or `$SECRET_KEY_BASE` environment variable. This
means that your authentication will now be more secure by default, and Rodauth
features that require `hmac_secret` should now work automatically as well.

However, if you've already been using rodauth-rails in production, where the
`secret_key_base` is set via credentials or environment variable and `hmac_secret`
was not explicitly set, the fact that your authentication will now start using
HMACs has backwards compatibility considerations. See the [Rodauth
documentation][hmac] for instructions on how to safely transition, or just set
`hmac_secret nil` in your Rodauth configuration.

## Installation

Add the gem to your Gemfile:

```rb
gem "rodauth-rails", "~> 0.9"

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

The generator will create the following files:

* Rodauth migration at `db/migrate/*_create_rodauth.rb`
* Rodauth initializer at `config/initializers/rodauth.rb`
* Sequel initializer at `config/initializers/sequel.rb` for ActiveRecord integration
* Rodauth app at `app/lib/rodauth_app.rb`
* Rodauth controller at `app/controllers/rodauth_controller.rb`
* Account model at `app/models/account.rb`

### Migration

The migration file creates tables required by Rodauth. You're encouraged to
review the migration, and modify it to only create tables for features you
intend to use.

```rb
# db/migrate/*_create_rodauth.rb
class CreateRodauth < ActiveRecord::Migration
  def change
    create_table :accounts do |t| ... end
    create_table :account_password_hashes do |t| ... end
    create_table :account_password_reset_keys do |t| ... end
    create_table :account_verification_keys do |t| ... end
    create_table :account_login_change_keys do |t| ... end
    create_table :account_remember_keys do |t| ... end
  end
end
```

Once you're done, you can run the migration:

```
$ rails db:migrate
```

### Rodauth initializer

The Rodauth initializer assigns the constant for your Rodauth app, which will
be called by the Rack middleware that's added in front of your Rails router.

```rb
# config/initializers/rodauth.rb
Rodauth::Rails.configure do |config|
  config.app = "RodauthApp"
end
```

### Sequel initializer

Rodauth uses [Sequel] for database interaction. If you're using ActiveRecord,
an additional initializer will be created which configures Sequel to use the
ActiveRecord connection.

```rb
# config/initializers/sequel.rb
require "sequel/core"

# initialize Sequel and have it reuse Active Record's database connection
DB = Sequel.connect("postgresql://", extensions: :activerecord_connection)
```

### Rodauth app

Your Rodauth app is created in the `app/lib/` directory, and comes with a
default set of authentication features enabled, as well as extensive examples
on ways you can configure authentication behaviour.

```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  configure do
    # authentication configuration
  end

  route do |r|
    # request handling
  end
end
```

### Controller

Your Rodauth app will by default use `RodauthController` for view rendering,
CSRF protection, and running controller callbacks and rescue handlers around
Rodauth actions.

```rb
# app/controllers/rodauth_controller.rb
class RodauthController < ApplicationController
end
```

### Account model

Rodauth stores user accounts in the `accounts` table, so the generator will
also create an `Account` model for custom use.

```rb
# app/models/account.rb
class Account < ApplicationRecord
end
```

## Usage

### Routes

We can see the list of routes our Rodauth middleware handles:

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

Using this information, we could add some basic authentication links to our
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

To be able to fetch currently authenticated account, let's define a
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
  helper_method :current_account
end
```

This allows us to access the current account in controllers and views:

```erb
<p>Authenticated as: <%= current_account.email %></p>
```

### Requiring authentication

We'll likely want to require authentication for certain parts of our app,
redirecting the user to the login page if they're not logged in. We can do this
in our Rodauth app's routing block, which helps keep the authentication logic
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

We can also require authentication at the controller layer:

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

Or at the Rails router level:

```rb
# config/routes.rb
Rails.application.routes.draw do
  constraints -> (r) { r.env["rodauth"].require_authentication } do
    namespace :admin do
      # ...
    end
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
`app/views/rodauth` directory, which will be automatically picked up by the
`RodauthController`.

You can pass a list of Rodauth features to the generator to create views for
these features (this will not remove any existing views):

```sh
$ rails generate rodauth:views login create_account lockout otp
```

Or you can generate views for all features:

```sh
$ rails generate rodauth:views --all
```

You can also tell the generator to create views into another directory (in this
case make sure to rename the Rodauth controller accordingly):

```sh
# generates views into app/views/authentication
$ rails generate rodauth:views --name authentication
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

Depending on the features you've enabled, Rodauth may send emails as part of
the authentication flow. Most email settings can be customized:

```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  # ...
  configure do
    # ...
    # general settings
    email_from "no-reply@myapp.com"
    email_subject_prefix "[MyApp] "
    send_email(&:deliver_later)
    # ...
    # feature settings
    verify_account_email_subject "Verify your account"
    verify_account_email_body { "Verify your account by visting this link: #{verify_account_email_link}" }
    # ...
  end
end
```

This is convenient when starting out, but eventually you might want to use your
own mailer. You can start by running the following command:

```sh
$ rails generate rodauth:mailer
```

This will create a `RodauthMailer` with the associated mailer views in
`app/views/rodauth_mailer` directory:

```rb
# app/mailers/rodauth_mailer.rb
class RodauthMailer < ApplicationMailer
  def verify_account(recipient, email_link) ... end
  def reset_password(recipient, email_link) ... end
  def verify_login_change(recipient, old_login, new_login, email_link) ... end
  def password_changed(recipient) ... end
  # def email_auth(recipient, email_link) ... end
  # def unlock_account(recipient, email_link) ... end
end
```

You can then uncomment the lines in your Rodauth configuration to have it call
your mailer. If you've enabled additional authentication features that send
emails, make sure to override their `create_*_email` methods as well.

```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  # ...
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

This approach can be used even if you're using a 3rd-party service for
transactional emails, where emails are sent via HTTP instead of SMTP. Whatever
the `create_*_email` block returns will be passed to `send_email`, so you can
be creative.

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

### Multiple configurations

If you need to handle multiple types of accounts that require different
authentication logic, you can create different configurations for them:

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
    r.on("admin") { r.rodauth(:admin) }
    # ...
  end
end
```

Then in your application you can reference the secondary Rodauth instance:

```rb
rodauth(:admin).login_path #=> "/admin/login"
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

### Rodauth instance

In some cases you might need to use Rodauth more programmatically, and perform
Rodauth operations outside of the request context. rodauth-rails gives you the
ability to retrieve the Rodauth instance:

```rb
rodauth = Rodauth::Rails.rodauth # or Rodauth::Rails.rodauth(:admin)

rodauth.login_url #=> "https://example.com/login"
rodauth.account_from_login("user@example.com") # loads user by email
rodauth.password_match?("secret") #=> true
rodauth.setup_account_verification
rodauth.close_account
```

This Rodauth instance will be initialized with basic Rack env that allows is it
to generate URLs, using `config.action_mailer.default_url_options` options.

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
    only_json? true # accept only JSON requests
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
    only_json? true # accept only JSON requests
    # ...
  end
end
```

If you need Cross-Origin Resource Sharing and/or JWT refresh tokens, enable the
corresponding Rodauth features and create the necessary tables:

```sh
$ rails generate rodauth:migration jwt_refresh
$ rails db:migrate
```
```rb
# app/lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  configure do
    # ...
    enable :jwt, :jwt_cors, :jwt_refresh
    # ...
  end
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

Let's implement the OmniAuth callback endpoint on our Rodauth controller:

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

For the list of configuration methods provided by Rodauth, see the [feature
documentation].

The `rails` feature rodauth-rails loads is customizable as well, here is the
list of its configuration methods:

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

## Custom extensions

When developing custom extensions for Rodauth inside your Rails project, it's
better to use plain modules (at least in the beginning), because Rodauth
feature design doesn't yet support Zeitwerk reloading well. Here is
an example of an LDAP authentication extension that uses the
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

If you're writing system tests, it's generally better to go through the actual
authentication flow with tools like Capybara, and to not use any stubbing.

In functional and integration tests you can just make requests to Rodauth
routes:

```rb
# test/controllers/posts_controller_test.rb
class PostsControllerTest < ActionDispatch::IntegrationTest
  test "should require authentication" do
    get posts_url
    assert_redirected_to "/login"

    login
    get posts_url
    assert_response :success

    logout
    assert_redirected_to "/login"
  end

  private

  def login(login: "user@example.com", password: "secret")
    post "/create-account", params: {
      "login"            => login,
      "password"         => password,
      "password-confirm" => password,
    }

    post "/login", params: {
      "login"    => login,
      "password" => password,
    }
  end

  def logout
    post "/logout"
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
