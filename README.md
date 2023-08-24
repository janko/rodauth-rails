# rodauth-rails

Provides Rails integration for the [Rodauth] authentication framework.

## Resources

🔗 Useful links:

* [Rodauth documentation](http://rodauth.jeremyevans.net/documentation.html)
* [Rails demo](https://github.com/janko/rodauth-demo-rails)
* [JSON API guide](https://github.com/janko/rodauth-rails/wiki/JSON-API)
* [OmniAuth guide](https://github.com/janko/rodauth-rails/wiki/OmniAuth)

🎥 Screencasts:

* [Rails Authentication with Rodauth](https://www.youtube.com/watch?v=2hDpNikacf0)
* [Multifactor Authentication with Rodauth](https://www.youtube.com/watch?v=9ON-kgXpz2A&list=PLkGQXZLACDTGKsaRWstkHQdm2CUmT3SZ-) ([TOTP](https://youtu.be/9ON-kgXpz2A), [Recovery Codes](https://youtu.be/lkFCcE1Q5-w))
* [Add Admin Accounts](https://www.youtube.com/watch?v=N6z7AtKSpNI)

📚 Articles:

* [Rodauth: A Refreshing Authentication Solution for Ruby](https://janko.io/rodauth-a-refreshing-authentication-solution-for-ruby/)
* [Rails Authentication with Rodauth](https://janko.io/adding-authentication-in-rails-with-rodauth/)
* [Multifactor Authentication in Rails with Rodauth](https://janko.io/adding-multifactor-authentication-in-rails-with-rodauth/)
* [How to build an OIDC provider using rodauth-oauth on Rails](https://honeyryderchuck.gitlab.io/httpx/2021/03/15/oidc-provider-on-rails-using-rodauth-oauth.html)
* [What It Took to Build a Rails Integration for Rodauth](https://janko.io/what-it-took-to-build-a-rails-integration-for-rodauth/)
* [Social Login in Rails with Rodauth](https://janko.io/social-login-in-rails-with-rodauth/)
* [Passkey Authentication with Rodauth](https://janko.io/passkey-authentication-with-rodauth/)

## Why Rodauth?

There are already several popular authentication solutions for Rails (Devise,
Sorcery, Clearance, Authlogic), so why would you choose Rodauth? Here are some
of the advantages that stand out for me:

* multifactor authentication ([TOTP][otp], [SMS codes][sms_codes], [recovery codes][recovery_codes], [passkeys][webauthn])
* standardized [JSON API support][json] for every feature (including [JWT][jwt])
* enterprise security features ([password complexity][password_complexity], [disallow password reuse][disallow_password_reuse], [password expiration][password_expiration], [session expiration][session_expiration], [single session][single_session], [account expiration][account_expiration])
* passwordless authentication ([email][email_auth], [passkeys][webauthn_login])
* [audit logging][audit_logging] for any action
* ability to protect password hashes even in case of SQL injection ([more details][password protection])
* uniform configuration DSL with before/after hooks around everything

### Sequel

One common concern for people coming from other Rails authentication frameworks
is the fact that Rodauth uses [Sequel] for database interaction instead of
Active Record. Sequel has powerful APIs for building advanced queries,
supporting complex SQL expressions, database-agnostic date arithmetic, SQL
function calls and more, all without having to drop down to raw SQL.

For Rails apps using Active Record, rodauth-rails configures Sequel to [reuse
Active Record's database connection][sequel-activerecord_connection]. This
makes it run smoothly alongside Active Record, even allowing calling Active
Record code from within Rodauth configuration. So, for all intents and
purposes, Sequel can be treated just as an implementation detail of Rodauth.

## Installation

Add the gem to your project:

```sh
$ bundle add rodauth-rails
```

Next, run the install generator:

```sh
$ rails generate rodauth:install
```

This will use the `accounts` table. If you want a different table name:

```sh
$ rails generate rodauth:install users
```

If you want Rodauth endpoints to be exposed via [JSON API]:

```sh
$ rails generate rodauth:install --json # regular authentication using the Rails session
# or
$ rails generate rodauth:install --jwt # token authentication via the "Authorization" header
$ bundle add jwt
```

To use Argon2 instead of bcrypt for password hashing:

```sh
$ rails generate rodauth:install --argon2
$ bundle add argon2
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
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```

## Usage

The Rodauth app will be called for each request before it reaches the Rails
router. It handles requests to Rodauth endpoints, and allows you to call
additional code before your main routes.

```sh
$ rails middleware
# ...
# use Rodauth::Rails::Middleware (calls your Rodauth app)
# run YourApp::Application.routes
```

### Routes

Because requests to Rodauth endpoints are handled by Roda, Rodauth routes will
not show in `rails routes`. You can use the `rodauth:routes` rake task to view
the list of endpoints based on currently loaded features:

```sh
$ rails rodauth:routes
```
```
Routes handled by RodauthApp:

  GET|POST  /login                   rodauth.login_path
  GET|POST  /create-account          rodauth.create_account_path
  GET|POST  /verify-account-resend   rodauth.verify_account_resend_path
  GET|POST  /verify-account          rodauth.verify_account_path
  GET|POST  /change-password         rodauth.change_password_path
  GET|POST  /change-login            rodauth.change_login_path
  GET|POST  /logout                  rodauth.logout_path
  GET|POST  /remember                rodauth.remember_path
  GET|POST  /reset-password-request  rodauth.reset_password_request_path
  GET|POST  /reset-password          rodauth.reset_password_path
  GET|POST  /verify-login-change     rodauth.verify_login_change_path
  GET|POST  /close-account           rodauth.close_account_path
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

The Rodauth object defines a `#rails_account` method, which returns a model
instance of the currently logged in account. You can create a helper method for
easy access from controllers and views:

```rb
class ApplicationController < ActionController::Base
  private

  def current_account
    rodauth.rails_account
  end
  helper_method :current_account # skip if inheriting from ActionController::API
end
```

```rb
current_account #=> #<Account id=123 email="user@example.com">
current_account.email #=> "user@example.com"
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

    # require authentication for /dashboard/* routes
    if r.path.start_with?("/dashboard")
      rodauth.require_account # redirect to login page if not authenticated
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
    rodauth.require_account # redirect to login page if not authenticated
  end
end
```
```rb
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate
end
```

#### Routing constraints

In some cases it makes sense to require authentication at the Rails router
level. You can do this via the built-in `authenticated` routing constraint:

```rb
# config/routes.rb
Rails.application.routes.draw do
  constraints Rodauth::Rails.authenticate do
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
  constraints Rodauth::Rails.authenticate { |rodauth| rodauth.uses_two_factor_authentication? } do
    # ...
  end
end
```

You can specify a different Rodauth configuration by passing the configuration name:

```rb
# config/routes.rb
Rails.application.routes.draw do
  constraints Rodauth::Rails.authenticate(:admin) do
    # ...
  end
end
```

If you need something more custom, you can always create the routing constraint
manually:

```rb
# config/routes.rb
Rails.application.routes.draw do
  constraints -> (r) { !r.env["rodauth"].logged_in? } do # or env["rodauth.admin"]
    # routes when the user is not logged in
  end
end
```

### Controller

Your Rodauth configuration is connected to a Rails controller (`RodauthController` by default), and
it automatically executes any callbacks and rescue handlers defined on it (or the parent controller)
around Rodauth endpoints.

```rb
class RodauthController < ApplicationController
  before_action :set_locale # executes before Rodauth endpoints
  rescue_from("MyApp::SomeError") { |exception| ... } # rescues around Rodauth endpoints
end
```

#### Calling controller methods

You can call any controller methods from your Rodauth configuration via `rails_controller_eval`:

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

### Rails URL helpers

Inside Rodauth configuration and the `route` block you can access Rails route
helpers through `#rails_routes`:

```rb
# app/misc/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    login_redirect { rails_routes.activity_path }
    change_password_redirect { rails_routes.profile_path }
    change_login_redirect { rails_routes.profile_path }
  end
end
```

## Views

The templates built into Rodauth are useful when getting started, but soon
you'll want to start editing the markup. You can run the following command to
copy Rodauth templates into your Rails app:

```sh
$ rails generate rodauth:views # bootstrap views
# or
$ rails generate rodauth:views --css=tailwind # tailwind views (requires @tailwindcss/forms plugin)
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
$ rails generate rodauth:views webauthn two_factor_base --name admin
```

### Page titles

The generated configuration sets `title_instance_variable` to make page titles
available in your views via `@page_title` instance variable, which you can then
use in your layout:

```rb
# app/misc/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    title_instance_variable :@page_title
  end
end
```
```erb
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title><%= @page_title || "Default title" %></title>
    <!-- ... -->
  </head>
  <!-- ... -->
</html>
```

### Layout

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
         rodauth.verify_account_resend_path,
         rodauth.reset_password_path,
         rodauth.reset_password_request_path
      "authentication"
    else
      "dashboard"
    end
  end
end
```

### Turbo

[Turbo] has been disabled by default on all built-in and generated view
templates, because some Rodauth actions (multi-phase login, adding recovery
codes) aren't Turbo-compatible, as they return 200 responses on POST requests.

That being said, most of Rodauth *is* Turbo-compatible, so feel free to enable
Turbo for actions where you want to use it.

## Mailer

The install generator will create `RodauthMailer` with default email templates,
and configure Rodauth features that send emails as part of the authentication
flow to use it.

```rb
# app/mailers/rodauth_mailer.rb
class RodauthMailer < ApplicationMailer
  def verify_account(account_id, key) ... end
  def reset_password(account_id, key) ... end
  def verify_login_change(account_id, key) ... end
  def password_changed(account_id) ... end
  # def email_auth(account_id, key) ... end
  # def unlock_account(account_id, key) ... end
end
```
```rb
# app/misc/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    create_reset_password_email { RodauthMailer.reset_password(account_id, reset_password_key_value) }
    create_verify_account_email { RodauthMailer.verify_account(account_id, verify_account_key_value) }
    create_verify_login_change_email { |_login| RodauthMailer.verify_login_change(account_id, verify_login_change_key_value) }
    create_password_changed_email { RodauthMailer.password_changed(account_id) }
    # create_email_auth_email { RodauthMailer.email_auth(account_id, email_auth_key_value) }
    # create_unlock_account_email { RodauthMailer.unlock_account(account_id, unlock_account_key_value) }
    send_email do |email|
      # queue email delivery on the mailer after the transaction commits
      db.after_commit { email.deliver_later }
    end
  end
end
```

This configuration calls `#deliver_later`, which uses Active Job to deliver
emails in a background job. If you want to send emails synchronously, you can
modify the configuration to call `#deliver_now` instead.

If you're using a background processing library without an Active Job adapter,
or a 3rd-party service for sending transactional emails, see [this wiki
page][custom mailer worker] on how to set it up.

## Migrations

The install generator will create a migration for tables used by the Rodauth
features enabled by default. For any additional features, you can use the
migration generator to create the required tables:

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

### Table prefix

If you're storing account records in a table other than `accounts`, you'll want
to specify the appropriate table prefix when generating new migrations:

```sh
$ rails generate rodauth:migration base active_sessions --prefix user

# Add the following to your Rodauth configuration:
#
#   accounts_table :users
#   active_sessions_table :user_active_session_keys
#   active_sessions_account_id_column :user_id
```
```rb
# db/migration/*_create_rodauth_user_base_active_sessions.rb
class CreateRodauthUserBaseActiveSessions < ActiveRecord::Migration
  def change
    create_table :users do |t| ... end
    create_table :user_active_session_keys do |t| ... end
  end
end
```

### Custom migration name

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

The [rodauth-model] gem provides a `Rodauth::Model` mixin that can be included
into the account model, which defines a password attribute and associations for
tables used by enabled authentication features.

```rb
class Account < ActiveRecord::Base # Sequel::Model
  include Rodauth::Rails.model # or Rodauth::Rails.model(:admin)
end
```
```rb
# setting password hash
account = Account.create!(email: "user@example.com", password: "secret123")
account.password_hash #=> "$2a$12$k/Ub1I2iomi84RacqY89Hu4.M0vK7klRnRtzorDyvOkVI.hKhkNw."

# clearing password hash
account.password = nil
account.password_hash #=> nil

# associations
account.remember_key #=> #<Account::RememberKey> (record from `account_remember_keys` table)
account.active_session_keys #=> [#<Account::ActiveSessionKey>,...] (records from `account_active_session_keys` table)
```

## Multiple configurations

If you need to handle multiple types of accounts that require different
authentication logic, you can create new configurations for them. This
is done by creating new `Rodauth::Rails::Auth` subclasses, and registering
them under a name.

```rb
# app/misc/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  configure RodauthMain          # primary configuration
  configure RodauthAdmin, :admin # secondary configuration

  route do |r|
    r.rodauth         # route primary rodauth requests
    r.rodauth(:admin) # route secondary rodauth requests
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
configuration to the database, see [this guide][account types] on how you can do
that. Note that you can also [share configuration via inheritance][inheritance].

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
RodauthApp.rodauth.create_account(login: "user@example.com", password: "secret123")
RodauthApp.rodauth.verify_account(account_login: "user@example.com")

# secondary configuration
RodauthApp.rodauth(:admin).close_account(account_login: "user@example.com")
```

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

### Using as a library

Rodauth offers a `Rodauth.lib` method for configuring Rodauth so that it can be used as a library, instead of routing requests (see [internal_request] feature). This gem provides a `Rodauth::Rails.lib` counterpart that does the same but with Rails integration:

```rb
# app/misc/rodauth_main.rb
require "rodauth/rails"
require "sequel/core"

RodauthMain = Rodauth::Rails.lib do
  enable :create_account, :login, :close_account
  db Sequel.postgres(extensions: :activerecord_connection, keep_reference: false)
  # ...
end
```
```rb
RodauthMain.create_account(login: "email@example.com", password: "secret123")
RodauthMain.login(login: "email@example.com", password: "secret123")
RodauthMain.close_account(account_login: "email@example.com")
```

Note that you'll want to skip requiring `rodauth-rails` on Rails boot, to avoid it automatically inserting the Rodauth middleware, and remove some unnecessary files generated by the install generator.

```rb
# Gemfile
gem "rodauth-rails", require: false
```
```sh
$ rm config/initializers/rodauth.rb app/misc/rodauth_app.rb app/controllers/rodauth_controller.rb
```

The `Rodauth::Rails.lib` call will forward any Rodauth [plugin options] passed to it:

```rb
# skips loading Roda render plugin and Tilt gem (used for rendering built-in templates)
Rodauth::Rails.lib(render: false) { ... }
```

## Testing

For system and integration tests, which run the whole middleware stack,
authentication can be exercised normally via HTTP endpoints. For example, given
a controller


```rb
# app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  before_action -> { rodauth.require_account }

  def index
    # ...
  end
end
```

One can write `ActionDispatch::IntegrationTest` test helpers for `login` and
`logout` by making requests to the Rodauth endpoints:

```rb
# test/controllers/articles_controller_test.rb
class ArticlesControllerTest < ActionDispatch::IntegrationTest
  def login(email, password)
    post "/login", params: { email: email, password: password }
    assert_redirected_to "/"
  end

  def logout
    post "/logout"
    assert_redirected_to "/"
  end
  
  test "required authentication" do
    get :index

    assert_response 302
    assert_redirected_to "/login"
    assert_equal "Please login to continue", flash[:alert]

    account = Account.create!(email: "user@example.com", password: "secret123", status: "verified")
    login(account.email, "secret123")

    get :index
    assert_response 200

    logout

    get :index
    assert_response 302
    assert_equal "Please login to continue", flash[:alert]
  end
end
```

For more examples and information about testing with rodauth, see
[this wiki page about testing](https://github.com/janko/rodauth-rails/wiki/Testing). 

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

```rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    rails_controller { Authentication::RodauthController }
    rails_account_model { Authentication::Account }
  end
end
```

For the list of configuration methods provided by Rodauth, see the [feature
documentation].

### Defining custom methods

All Rodauth configuration methods are just syntax sugar for defining instance
methods on the auth class. You can also define your own custom methods:

```rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    password_match? { |password| ldap_valid?(password) }
  end

  def admin?
    rails_account.admin?
  end

  private

  def ldap_valid?(password)
    SimpleLdapAuthenticator.valid?(account[:email], password)
  end
end
```
```rb
rodauth.admin? #=> true
```

### Single-file configuration

If you would prefer, you can have all your Rodauth logic contained inside the
Rodauth app class:

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

### Manually inserting middleware

You can choose to insert the Rodauth middleware somewhere earlier than
in front of the Rails router:

```rb
Rodauth::Rails.configure do |config|
  config.middleware = false # disable auto-insertion
end

Rails.application.config.middleware.insert_before AnotherMiddleware, Rodauth::Rails::Middleware
```

## How it works

### Rack middleware

The railtie inserts [`Rodauth::Rails::Middleware`](/lib/rodauth/rails/middleware.rb)
at the end of the middleware stack, which calls your Rodauth app around each request.

```sh
$ rails middleware
# ...
# use Rodauth::Rails::Middleware
# run MyApp::Application.routes
```

The middleware retrieves the Rodauth app via `Rodauth::Rails.app`, which is
specified as a string to keep the class autoloadable and reloadable in
development.

```rb
Rodauth::Rails.configure do |config|
  config.app = "RodauthApp"
end
```

In addition to Zeitwerk compatibility, this extra layer catches Rodauth redirects
that happen on the controller level (e.g. when calling
`rodauth.require_account` in a `before_action` filter).

### Roda app

The [`Rodauth::Rails::App`](/lib/rodauth/rails/app.rb) class is a [Roda]
subclass that provides a convenience layer for Rodauth:

* uses Action Dispatch flash messages
* provides syntax sugar for loading the rodauth plugin
* saves Rodauth object(s) to Rack env hash
* propagates edited headers to Rails responses

#### Configure block

The `configure` call loads the rodauth plugin. By convention, it receives an
auth class and configuration name as positional arguments (forwarded as
`:auth_class` and `:name` plugin options), a block for anonymous auth classes,
and also accepts any additional plugin options.

```rb
class RodauthApp < Rodauth::Rails::App
  # named auth class
  configure(RodauthMain)
  configure(RodauthAdmin, :admin)

  # anonymous auth class
  configure { ... }
  configure(:admin) { ... }

  # plugin options
  configure(RodauthMain, json: :only, render: false)
end
```

#### Route block

The `route` block is called for each request, before it reaches the Rails
router, and it's yielded the request object.

```rb
class RodauthApp < Rodauth::Rails::App
  route do |r|
    # called before each request
  end
end
```

#### Routing prefix

If you use a routing prefix, you don't need to add a call to `r.on` like with
vanilla Rodauth, as `r.rodauth` has been modified to automatically route the
prefix.

```rb
class RodauthApp < Rodauth::Rails::App
  configure do
    prefix "/user"
  end

  route do |r|
    r.rodauth # no need to wrap with `r.on("user") { ... }`
  end
end
```

### Auth class

The [`Rodauth::Rails::Auth`](/lib/rodauth/rails/auth.rb) class is a subclass of
`Rodauth::Auth`, which preloads the `rails` rodauth feature, sets [HMAC] secret to
Rails' secret key base, and modifies some [configuration defaults](#rodauth-defaults).

```rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    # authentication configuration
  end
end
```

### Rodauth feature

The [`rails`](/lib/rodauth/rails/feature.rb) Rodauth feature loaded by
`Rodauth::Rails::Auth` provides the main part of the Rails integration for Rodauth:

* uses Action View for template rendering
* uses Action Dispatch for CSRF protection
* runs Action Controller callbacks and rescue from blocks around Rodauth requests
* uses Action Mailer to create and deliver emails
* uses Action Controller instrumentation around Rodauth requests
* uses Action Mailer's default URL options when calling Rodauth outside of a request

### Controller

The Rodauth app stores the `Rodauth::Rails::Auth` instances in the Rack env
hash, which is then available in your Rails app:

```rb
request.env["rodauth"]       #=> #<RodauthMain>
request.env["rodauth.admin"] #=> #<RodauthAdmin> (if using multiple configurations)
```

For convenience, this object can be accessed via the `#rodauth` method in views
and controllers:

```rb
class MyController < ApplicationController
  def my_action
    rodauth         #=> #<RodauthMain>
    rodauth(:admin) #=> #<RodauthAdmin> (if using multiple configurations)
  end
end
```
```erb
<% rodauth         #=> #<RodauthMain> %>
<% rodauth(:admin) #=> #<RodauthAdmin> (if using multiple configurations) %>
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
    Rodauth.create_database_authentication_functions(db)
  end

  def down
    Rodauth.drop_database_authentication_functions(db)
  end

  private

  def db
    RodauthMain.allocate.db
  end
end
```

### Account statuses

The recommended [Rodauth migration] stores possible account status values in a
separate table, and creates a foreign key on the accounts table, which ensures
only a valid status value will be persisted. Unfortunately, this doesn't work
when the database is restored from the schema file, in which case the account
statuses table will be empty. This happens in tests by default, but it's also
not unusual to do it in development.

To address this, rodauth-rails uses a `status` column without a separate table.
If you're worried about invalid status values creeping in, you may use enums
instead. Alternatively, you can always go back to the setup recommended by
Rodauth.

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
  class RodauthMain < Rodauth::Rails::Auth
    configure do
      # ...
-     account_status_column :status
      # ...
    end
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
conduct](CODE_OF_CONDUCT.md).

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
[webauthn_login]: http://rodauth.jeremyevans.net/rdoc/files/doc/webauthn_login_rdoc.html
[json]: http://rodauth.jeremyevans.net/rdoc/files/doc/json_rdoc.html
[jwt]: http://rodauth.jeremyevans.net/rdoc/files/doc/jwt_rdoc.html
[email_auth]: http://rodauth.jeremyevans.net/rdoc/files/doc/email_auth_rdoc.html
[audit_logging]: http://rodauth.jeremyevans.net/rdoc/files/doc/audit_logging_rdoc.html
[password protection]: https://github.com/jeremyevans/rodauth#label-Password+Hash+Access+Via+Database+Functions
[password_complexity]: http://rodauth.jeremyevans.net/rdoc/files/doc/password_complexity_rdoc.html
[disallow_password_reuse]: http://rodauth.jeremyevans.net/rdoc/files/doc/disallow_password_reuse_rdoc.html
[password_expiration]: http://rodauth.jeremyevans.net/rdoc/files/doc/password_expiration_rdoc.html
[session_expiration]: http://rodauth.jeremyevans.net/rdoc/files/doc/session_expiration_rdoc.html
[single_session]: http://rodauth.jeremyevans.net/rdoc/files/doc/single_session_rdoc.html
[account_expiration]: http://rodauth.jeremyevans.net/rdoc/files/doc/account_expiration_rdoc.html
[simple_ldap_authenticator]: https://github.com/jeremyevans/simple_ldap_authenticator
[internal_request]: http://rodauth.jeremyevans.net/rdoc/files/doc/internal_request_rdoc.html
[path_class_methods]: https://rodauth.jeremyevans.net/rdoc/files/doc/path_class_methods_rdoc.html
[account types]: https://github.com/janko/rodauth-rails/wiki/Account-Types
[custom mailer worker]: https://github.com/janko/rodauth-rails/wiki/Custom-Mailer-Worker
[Turbo]: https://turbo.hotwired.dev/
[rodauth-model]: https://github.com/janko/rodauth-model
[JSON API]: https://github.com/janko/rodauth-rails/wiki/JSON-API
[inheritance]: http://rodauth.jeremyevans.net/rdoc/files/doc/guides/share_configuration_rdoc.html
