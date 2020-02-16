# Rodauth::Rails

Provides Rails integration for [Rodauth].

NOTE: This is not yet 100% finished and thus it's not yet released on RubyGems.org. Your can expect it to be published soon.

## Rails support

Rails 5.0 or above is supported. This is mainly due to the fact that Rails 5.0
added the API for [rendering views outside of controllers], which this gem
uses.

If you're on an older version of Rails and would like to use this gem, let me
know and we can work together to add support.

## Installation

Add the gem to your Gemfile:

```rb
gem "rodauth-rails"
```

Then run `bundle install`.

Next, run the install generator:

```
$ rails generate rodauth:install
```

This will create a migration file with tables required by Rodauth. Once you've
reviewed it, you can run the migrations:

```
$ rails db:migrate
```

The generator also creates your Rodauth app in the `lib/` directory:

```rb
# lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  rodauth do
    # ... configuration ...
  end

  route do |r|
    r.rodauth # routes Rodauth endpoints

    # ...
  end
end
```

And configures your app to be used in the Rodauth middleware:

```rb
# config/initializers/rodauth.rb
Rodauth::Rails.configure do |config|
  config.app = "RodauthApp"
end
```

## Getting started

The `#rodauth` method is available in your controllers and views, and it
returns the Rodauth instance. It can be used for managing authentication,
inquiring on current state, fetching routes, or retrieving other settings.

```rb
# app/controllers/my_controller.rb
class MyController < ApplicationController
  def my_action
    rodauth #=> #<Rodauth::Auth>
    # or
    rodauth(:name) #=> #<Rodauth::Auth> (if using multiple configurations)
  end
end
```
```erb
<!-- app/views/directory/my_template.html.erb -->
<% rodauth #=> #<Rodauth::Auth> %>
<!-- or -->
<% rodauth(:name) #=> #<Rodauth::Auth> (if using multiple configurations) %>
```

### Generating links

In order to display links to Rodauth actions, you can use `*_path` or `*_url`
counterparts to Rodauth `*_route` methods:

```erb
<!-- app/views/layouts/application.html.erb -->
<html>
  <head>...</head>
  <body>
    <nav>
      <ul>
        <% if rodauth.authenticated? %>
          <li><%= link_to "Sign out", rodauth.logout_path, method: :post %></li>
        <% else %>
          <li><%= link_to "Sign in", rodauth.login_path %></li>
          <li><%= link_to "Sign up", rodauth.create_account_path %></li>
        <% end %>
      </ul>
    </nav>

    <%= yield %>
  </body>
</html>
```

Consult the [Rodauth feature documentation] for the available routes.

### Requiring authentication

You'll likely want to require authentication for certain controllers/actions.
You can do this in your Rodauth app using [Roda routing]:

```rb
# lib/rodauth_app.rb
class RodauthApp < Rodauth::Rails::App
  # ...

  route do |r|
    # ...

    r.rodauth

    next unless r.path.start_with?("/dashboard") # authenticate /dashboard/* routes
    next unless r.path.start_with?("/account")   # authenticate /account/* routes
    next unless r.path =~ %r{posts/\w+/edit}     # authenticate /posts/:id/edit route

    rodauth.require_authentication # # redirect to login if not authenticated

    nil # forward the request to the Rails app
  end
end
```

Alternatively, you can require authentication at the controller layer:

```rb
class ApplicationController < ActionController::Base
  private

  def authenticate
    rodauth.require_authentication
  end
end
```
```rb
class DashboardController < ApplicationController
  before_action :authenticate
end
```
```rb
class PostsController < ApplicationController
  before_action :authenticate, except: [:index, :show]
end
```

### Current account

To retrieve the current account, you can define an `Account` model and a
`#current_account` controller/helper method:

```rb
# app/models/account.rb
class Account < ApplicationRecord
end
```
```rb
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  private

  def current_account
    @current_account ||= Account.find(rodauth.session_value)
  end
  helper_method :current_account
end
```

### Views

Rodauth ships with built-in templates that are used by default, which use
Bootstrap classes. When you're ready to start customizing the views, you can
run the following command to create the views for your app:

```sh
$ rails generate rodauth:views
```

This will copy views into your `app/views/rodauth/` directory, and add a
`RodauthController` for rendering those views.

Note that these are just copies of Rodauth's built-in templates written for
Rails, so it's possible that a template is missing in a newer Rodauth version.
In this case Rodauth will just fall back to rendering the built-in template.

### Mailer

Emails are sent using ActionMailer, with message headers and body defined by
Rodauth configuration.

```rb
rodauth do
  # ...
  # general settings
  email_from "no-reply@myapp.com"
  email_subject_prefix "[MyApp] "
  # ...
  # feature settings
  verify_account_email_subject "Verify your account"
  verify_account_email_body { "Verify your account by visting this link: #{verify_account_email_link}" }
  # ...
end
```

This is convenient when starting out, but eventually you might want more
control by using your own mailer. You can do this by overriding `#send_*_email`
auth methods for individual Rodauth actions:

```rb
rodauth do
  # ...
  send_verify_account_email { rails_mailer_deliver(:verify_account, verify_account_email_link) }
  send_reset_password_email { rails_mailer_deliver(:reset_password, reset_password_email_link) }

  auth_class_eval do
    def rails_mailer_deliver(name, *args, **options)
      email = AuthenticationMailer.public_send(name, email_to, *args, **options)
      email.deliver_now # or .deliver_later
    end
  end
  # ...
end
```
```rb
# app/mailers/authentication_mailer.rb
class AuthenticationMailer < ApplicationMailer
  def verify_account(recipient, email_link)
    @email_link = email_link

    mail to: recipient, subject: "Verify Account"
  end

  def reset_password(recipient, email_link)
    @email_link = email_link

    mail to: recipient, subject: "Reset Password"
  end

  # ...
end
```
```erb
<!-- app/views/authentication_mailer/verify_account.text.erb -->
Someone has created an account with this email address. If you did not create
this account, please ignore this message. If you created this account, please go to
<%= @email_link %>
to verify the account.
```
```erb
<!-- app/views/authentication_mailer/reset_password.text.erb -->
Someone has requested a password reset for the account with this email
address.  If you did not request a password reset, please ignore this
message.  If you requested a password reset, please go to
<%= @email_link %>
to reset the password for the account.
```

See Rodauth's default `*-email` templates in the [`templates/`][templates]
directory for inspiration.

## How it works

The `Rodauth::Rails::App` class is a [Roda] subclass with some basic plugins
preloaded.

```rb
Rodauth::Rails::App.superclass #=> Roda
```

The app stores the `Rodauth::Auth` instance in the Rack env hash under
`env["rodauth"]`, which is then available in controllers and views via the
`#rodauth` method.

```rb
request.env["rodauth"] #=> #<Rodauth::Auth>
# or
request.env["rodauth.<name>"] #=> #<Rodauth::Auth> (if using multiple configurations)
```

The `rodauth { ... }` call internally loads the Rodauth plugin together with
the Rails integration, and applies some default configuration.

```rb
rodauth { ... }             # defining default Rodauth configuration
rodauth(json: true)         # passing options to the Rodauth plugin
rodauth(:secondary) { ... } # defining multiple Rodauth configurations
```

The Rails integration does the following:

* automatically connects Sequel to the database ActiveRecord is connected to
* renders views with ActionController & ActionView when views are copied
* creates and sends emails using ActionMailer (using Rodauth configuration)
* uses ActionDispatch::Flash for flash messages
* verifies Rails authenticity token before Rodauth actions
* sets [HMAC secret][HMAC] for additional security (uses Rails' `secret_key_base`)
* disables usage of [database authentication functions] for easier setup

## Configuring

The Rails integration can be configured for additional flexibility:

```rb
class RodauthMiddleware < Rodauth::Rails::App
  rodauth do
    # ...
    # use a different controller for rendering templates
    rails_controller { AuthenticationController }
    rails_render do |template_name|
      # customize how templates are rendered
    end
    # ...
  end
end
```

See the [feature](/lib/rodauth/rails/feature.rb) source code for list of
overridable methods and values.

## Performance considerations

Rodauth uses Sequel for database interaction, which cannot share the same
connection as ActiveRecord. This means that your database might have up to
twice as many open connections than it would normally have, depending on which
worker model your web server is using.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the rodauth-rails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/janko/rodauth-rails/blob/master/CODE_OF_CONDUCT.md).

[Rodauth]: https://rodauth.jeremyevans.net
[rendering views outside of controllers]: https://blog.bigbinary.com/2016/01/08/rendering-views-outside-of-controllers-in-rails-5.html
[Rodauth feature documentation]: http://rodauth.jeremyevans.net/documentation.html
[Roda routing]: http://roda.jeremyevans.net/rdoc/files/README_rdoc.html#label-Usage
[Roda]: http://roda.jeremyevans.net/
[HMAC]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-HMAC
[database authentication functions]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-Password+Hash+Access+Via+Database+Functions
[templates]: https://github.com/jeremyevans/rodauth/tree/master/templates
[multiple configurations]: http://rodauth.jeremyevans.net/rdoc/files/README_rdoc.html#label-With+Multiple+Configurations
[views]: /app/views/rodauth
