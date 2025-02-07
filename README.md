# rodauth-rails

Provides Rails integration for the [Rodauth] authentication framework.

## Resources

🔗 Useful links:

* [Rodauth documentation](http://rodauth.jeremyevans.net/documentation.html)
* [Rails demo](https://github.com/janko/rodauth-demo-rails)
* [JSON API guide](https://github.com/janko/rodauth-rails/wiki/JSON-API)
* [OmniAuth guide](https://github.com/janko/rodauth-rails/wiki/OmniAuth)
* [JSON Request Documentation for Rodauth](https://documenter.getpostman.com/view/26686011/2s9YC7SWn9)

🎥 Screencasts / Streams:

* [Rails Authentication with Rodauth](https://www.youtube.com/watch?v=2hDpNikacf0) \[8:23\]
* [Multifactor Authentication via TOTP with Rodauth](https://youtu.be/9ON-kgXpz2A) \[4:36\]
* [Multifactor Authentication via Recovery Codes with Rodauth](https://youtu.be/lkFCcE1Q5-w) \[4:24\]
* [Adding Admin Accounts with Rodauth](https://www.youtube.com/watch?v=N6z7AtKSpNI) \[1:25:55\]
* [Integrating Passkeys into Rails with Rodauth](https://www.youtube.com/watch?v=kGzgmfCmnmY) \[59:47\]

📚 Articles:

* [Rodauth: A Refreshing Authentication Solution for Ruby](https://janko.io/rodauth-a-refreshing-authentication-solution-for-ruby/)
* [Rails Authentication with Rodauth](https://janko.io/adding-authentication-in-rails-with-rodauth/)
* [Multifactor Authentication in Rails with Rodauth](https://janko.io/adding-multifactor-authentication-in-rails-with-rodauth/)
* [How to build an OIDC provider using rodauth-oauth on Rails](https://honeyryderchuck.gitlab.io/2021/03/15/oidc-provider-on-rails-using-rodauth-oauth.html)
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
Active Record. For Rails apps using Active Record, rodauth-rails configures Sequel to [reuse
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

This generator will create a Rodauth app and configuration with common
authentication features enabled, a database migration with tables required by
those features, and a few other files.

Feel free to remove any features you don't need, along with their corresponding
tables. Afterwards, run the migration:

```sh
$ rails db:migrate
```

### Install options

The install generator will use the `accounts` table by default. You can specify a different table name:

```sh
$ rails generate rodauth:install users
```

If you want Rodauth endpoints to be exposed via [JSON API]:

```sh
$ rails generate rodauth:install --json # cookied-based authentication
# or
$ rails generate rodauth:install --jwt # token-based authentication
```

To use Argon2 instead of bcrypt for password hashing:

```sh
$ rails generate rodauth:install --argon2
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

                   login  GET|POST  /login                   rodauth.login_path
          create_account  GET|POST  /create-account          rodauth.create_account_path
   verify_account_resend  GET|POST  /verify-account-resend   rodauth.verify_account_resend_path
          verify_account  GET|POST  /verify-account          rodauth.verify_account_path
         change_password  GET|POST  /change-password         rodauth.change_password_path
            change_login  GET|POST  /change-login            rodauth.change_login_path
                  logout  GET|POST  /logout                  rodauth.logout_path
                remember  GET|POST  /remember                rodauth.remember_path
  reset_password_request  GET|POST  /reset-password-request  rodauth.reset_password_request_path
          reset_password  GET|POST  /reset-password          rodauth.reset_password_path
     verify_login_change  GET|POST  /verify-login-change     rodauth.verify_login_change_path
           close_account  GET|POST  /close-account           rodauth.close_account_path
```

Using this information, you can add some basic authentication links to your
navigation header:

```erb
<% if rodauth.logged_in? %>
  <%= button_to "Sign out", rodauth.logout_path, method: :post %>
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

### Requiring authentication

You can require authentication for routes at the middleware level in in your Rodauth
app's routing block, which helps keep the authentication logic encapsulated:

```rb
# app/misc/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  route do |r|
    r.rodauth # route rodauth requests

    if r.path.start_with?("/dashboard") # /dashboard/* routes
      rodauth.require_account # redirect to login page if not authenticated
    end
  end
end
```

You can also require authentication at the controller layer:

```rb
class ApplicationController < ActionController::Base
  private

  def authenticate
    rodauth.require_account # redirect to login page if not authenticated
  end
end
```
```rb
class DashboardController < ApplicationController
  before_action :authenticate
end
```

Additionally, routes can be authenticated at the Rails router level:

```rb
# config/routes.rb
Rails.application.routes.draw do
  constraints Rodauth::Rails.authenticate do
    # ... these routes will require authentication ...
  end

  constraints Rodauth::Rails.authenticate { |rodauth| rodauth.uses_two_factor_authentication? } do
    # ... these routes will be available only if 2FA is setup ...
  end

  constraints Rodauth::Rails.authenticate(:admin) do
    # ... these routes will be authenticated with secondary "admin" configuration ...
  end

  constraints -> (r) { !r.env["rodauth"].logged_in? } do # or env["rodauth.admin"]
    # ... these routes will be available only if not authenticated ...
  end
end
```

### Controller

Your Rodauth configuration is linked to a Rails controller, which is primarily used to render views and handle CSRF protection, but will also execute any callbacks and rescue handlers defined on it around Rodauth endpoints.

```rb
# app/misc/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    rails_controller { RodauthController }
  end
end
```
```rb
class RodauthController < ApplicationController
  before_action :verify_captcha, only: :login, if: -> { request.post? } # executes before Rodauth endpoints
  rescue_from("SomeError") { |exception| ... } # rescues around Rodauth endpoints
end
```

Various methods are available in your Rodauth configuration to bridge the gap with the controller:

```rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    # calling methods on the controller:
    after_create_account do
      rails_controller_eval { some_controller_method(account_id) }
    end

    # accessing Rails URL helpers:
    login_redirect { rails_routes.dashboard_path }

    # accessing Rails request object:
    after_change_password do
      if rails_request.format.turbo_stream?
        return_response rails_render(turbo_stream: [turbo_stream.replace(...)])
      end
    end

    # accessing Rails cookies:
    after_login { rails_cookies.permanent[:last_account_id] = account_id }
  end
end
```

## Views

The templates built into Rodauth are useful when getting started, but soon
you'll want to start editing the markup. You can run the following command to
copy Rodauth templates into your Rails app:

```sh
$ rails generate rodauth:views
```

This will generate views for Rodauth features you have currently enabled into
the `app/views/rodauth` directory (provided that `RodauthController` is set for
the main configuration).

The generator accepts various options:

```sh
# generate views with Tailwind markup (requires @tailwindcss/forms plugin)
$ rails generate rodauth:views --css=tailwind

# specify Rodauth features to generate views for
$ rails generate rodauth:views login create_account lockout otp

# generate views for all Rodauth features
$ rails generate rodauth:views --all

# specify a different Rodauth configuration
$ rails generate rodauth:views webauthn two_factor_base --name admin
```

## Mailer

When you're ready to modify the default email templates and safely deliver them
in a background job, you can run the following command to generate the mailer
integration:

```sh
$ rails generate rodauth:mailer
```

This will create a `RodauthMailer` along with email templates, as well as output
the necessary configuration that you should copy into your auth class:

```rb
# app/misc/rodauth_main.rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    create_verify_account_email do
      RodauthMailer.verify_account(self.class.configuration_name, account_id, verify_account_key_value)
    end
    create_reset_password_email do
      RodauthMailer.reset_password(self.class.configuration_name, account_id, reset_password_key_value)
    end
    create_verify_login_change_email do |_login|
      RodauthMailer.verify_login_change(self.class.configuration_name, account_id, verify_login_change_key_value)
    end
  end
end
```

For email links to work, you need to have
`config.action_mailer.default_url_options` set for each environment.

```rb
# config/environments/development.rb
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
```

The generator accepts various options:

```sh
# generate mailer integration for specified features
$ rails generate rodauth:mailer email_auth lockout webauthn_modify_email

# generate mailer integration for all Rodauth features
$ rails generate rodauth:mailer --all

# specify different Rodauth configuration to select enabled features
$ rails generate rodauth:mailer --name admin
```

Note that the generated Rodauth configuration calls `#deliver_later`, which
uses Active Job to deliver emails in a background job. If you want to deliver
emails synchronously, you can modify the configuration to call `#deliver_now`
instead.

If you're using a background processing library without an Active Job adapter,
or a 3rd-party service for sending transactional emails, see [this wiki
page][custom mailer job] on how to set it up.

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

You can change the default migration name:

```sh
$ rails generate rodauth:migration email_auth --name create_account_email_auth_keys
```
```rb
# db/migration/*_create_account_email_auth_keys.rb
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
  include Rodauth::Rails.model # or `Rodauth::Rails.model(:admin)`
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

    if request.path.start_with?("/admin")
      rodauth(:admin).require_account
    end
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
rodauth(:admin).authenticated? # checks "admin_account_id" session value
rodauth(:admin).login_path #=> "/admin/login"
```

You'll likely want to save the information of which account belongs to which
configuration to the database, see [this guide][account types] on how you can do
that. Note that you can also [share configuration via inheritance][inheritance].

## Outside of a request

The [internal_request] and [path_class_methods] features are supported, with defaults taken from `config.action_mailer.default_url_options`.

```rb
# internal requests
RodauthApp.rodauth.create_account(login: "user@example.com", password: "secret123")
RodauthApp.rodauth(:admin).verify_account(account_login: "admin@example.com")

# path and URL methods
RodauthApp.rodauth.close_account_path #=> "/close-account"
RodauthApp.rodauth(:admin).otp_setup_url #=> "http://localhost:3000/admin/otp-setup"
```

### Calling instance methods

If you need to access Rodauth methods not exposed as internal requests, you can
use `Rodauth::Rails.rodauth` to retrieve the Rodauth instance (this requires enabling
the internal_request feature):

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

You can override default URL options ad-hoc by modifying `#rails_url_options`:

```rb
rodauth.base_url #=> "https://example.com"
rodauth.rails_url_options[:host] = "subdomain.example.com"
rodauth.base_url #=> "https://subdomain.example.com"
```

### Using as a library

Rodauth offers a [`Rodauth.lib`][library] method for when you want to use it as a library (via [internal requests][internal_request]), as opposed to having it route requests. This gem provides a `Rodauth::Rails.lib` counterpart that does the same but with Rails integration:

```rb
# skip require on boot to avoid inserting Rodauth middleware
gem "rodauth-rails", require: false
```
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

The `rails` feature rodauth-rails loads provides the following configuration methods:

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
| `rails_url_options`         | Options used for generating URLs outside of a request (defaults to `config.action_mailer.default_url_options`) |

```rb
class RodauthMain < Rodauth::Rails::Auth
  configure do
    rails_account_model { MyApp::Account }
    rails_controller { MyApp::RodauthController }
  end
end
```

### Manually inserting middleware

You can choose to insert the Rodauth middleware somewhere earlier than
in front of the Rails router:

```rb
# config/initializers/rodauth.rb
Rodauth::Rails.configure do |config|
  config.middleware = false # disable auto-insertion
end

Rails.configuration.middleware.insert_before AnotherMiddleware, Rodauth::Rails::Middleware
```

### Skipping Tilt

Rodauth uses the [Tilt] gem to render built-in view & email templates. If you don't want to have Tilt as a dependency, you can disable it, provided that you've imported all view & email templates into your app:

```rb
# config/initializers/rodauth.rb
Rodauth::Rails.configure do |config|
  config.tilt = false # skip loading Tilt gem
end
```

## How it works

### Rack middleware

The railtie inserts [`Rodauth::Rails::Middleware`](/lib/rodauth/rails/middleware.rb)
at the end of the middleware stack, which is just a wrapper around your Rodauth app.

```sh
$ rails middleware
# ...
# use Rodauth::Rails::Middleware
# run MyApp::Application.routes
```

> [!NOTE]
> If you're using a middleware that should be called before Rodauth routes, make sure that middleware is inserted *before* Rodauth.
>
> For example, if you're using [Rack::Attack] to throttle signups, make sure you put the `rack-attack` gem *above* `rodauth-rails` in the Gemfile, so that its middleware is inserted first.

### Roda app

The [`Rodauth::Rails::App`](/lib/rodauth/rails/app.rb) class is a [Roda]
subclass that provides a convenience layer over Rodauth.

#### Configure block

The `configure` call is a wrapper around `plugin :rodauth`. By convention, it receives an
auth class and configuration name as positional arguments (which get converted into
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

#### Rack env

The app sets Rodauth objects for each registered configuration in the Rack env,
so that they're accessible downstream by the Rails router, controllers and views:

```rb
request.env["rodauth"]       #=> #<RodauthMain>
request.env["rodauth.admin"] #=> #<RodauthAdmin> (if using multiple configurations)
```

### Auth class

The [`Rodauth::Rails::Auth`](/lib/rodauth/rails/auth.rb) class is a subclass of
`Rodauth::Auth`, which preloads the `rails` rodauth feature, sets [HMAC] secret to
Rails' secret key base, and modifies some [configuration defaults][restoring defaults].

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

## License

The gem is available as open source under the terms of the [MIT
License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the rodauth-rails project's codebases, issue trackers,
chat rooms and mailing lists is expected to follow the [code of
conduct](CODE_OF_CONDUCT.md).

[Rodauth]: https://github.com/jeremyevans/rodauth
[Sequel]: https://github.com/jeremyevans/sequel
[Bootstrap]: https://getbootstrap.com/
[Roda]: http://roda.jeremyevans.net/
[HMAC]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-HMAC
[database authentication functions]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-Password+Hash+Access+Via+Database+Functions
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
[custom mailer job]: https://github.com/janko/rodauth-rails/wiki/Custom-Mailer-Job
[Turbo]: https://turbo.hotwired.dev/
[rodauth-model]: https://github.com/janko/rodauth-model
[JSON API]: https://github.com/janko/rodauth-rails/wiki/JSON-API
[inheritance]: http://rodauth.jeremyevans.net/rdoc/files/doc/guides/share_configuration_rdoc.html
[library]: https://github.com/jeremyevans/rodauth#label-Using+Rodauth+as+a+Library
[restoring defaults]: https://github.com/janko/rodauth-rails/wiki/Restoring-Rodauth-Defaults
[Rack::Attack]: https://github.com/rack/rack-attack
[Tilt]: https://github.com/jeremyevans/tilt
