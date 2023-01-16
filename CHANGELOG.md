## HEAD

* Fix loading JavaScript for WebAuthn in generated view templates (@janko)

## 1.7.0 (2022-12-21)

* Add Tailwind CSS templates to `rodauth:views` generator via the `--css=tailwind` option (@benkoshy, @janko)

## 1.6.4 (2022-11-24)

* Make `#rails_account` work on directly allocated Rodauth object with `@account` set (@janko)

* Add commented out email configuration for `password_reset_notify` feature (@janko)

* Design generated mailer in a way that exposes the Rodauth object (@janko)

* Fix generated logout page always logging out globally when using active sessions feature (@janko)

## 1.6.3 (2022-11-15)

* Suggest passing an integer to `verify_account_grace_period` instead of `ActiveSupport::Duration` (@vlado)

* Use `pass` plugin for forwarding other `{prefix}/*` requests when automatically routing the prefix (@janko)

* Set minimum password length to 8 in the generated configuration, as per OWASP recommendation (@janko)

* Set maximum password bytesize to 72 in the generated configuration, as bcrypt truncates inputs longer than 72 bytes (@janko)

## 1.6.2 (2022-09-19)

* Use matching precision for current timestamp default values in Active Record 7.0+ migrations on MySQL (@janko)

## 1.6.1 (2022-09-19)

* Fix argument error when calling `RodauthMailer` in default configuration (@janko)

## 1.6.0 (2022-09-14)

* Avoid creating IDENTITY columns for primary foreign keys on SQL Server with Active Record (@janko)

* Make configuration name argument required in generated `RodauthMailer` (@janko)

* Make the Rails integration work without Action Mailer loaded (@janko)

* Don't redirect to login page when account is missing in `current_account` method (@janko)

## 1.5.5 (2022-08-04)

* Don't raise `ArgumentError` when calling `#current_account` without being logged in (@benkoshy)

* Abort `rodauth:views` generator when unknown feature was specified (@janko)

* Abort `rodauth:migration` generator when unknown feature was specified (@janko)

## 1.5.4 (2022-07-21)

* Generate account fixtures in `spec/fixtures` directory when using RSpec (@benkoshy)

* Generate account fixtures in `test/fixtures` directory instead of `app/test/fixtures` (@benkoshy)

* Use string status column values in generated accounts fixture (@janko)

* Create integer status column in generated Sequel migration (@janko)

* Store password hash in accounts table in generated Sequel migration (@janko)

## 1.5.3 (2022-07-21)

*Yanked*

## 1.5.2 (2022-07-03)

* Bump Rodauth dependency version to 2.25+ (@janko)

* Generate fixture file for accounts on `rodauth:install` (@benkoshy)

* Fix error about undefined `controller_path` method in `newrelic_rpm` gem instrumentation (@janko)

* Don't display disabled routes in `rodauth:routes` (@janko)

* Display HTTP verbs of endpoints in `rodauth:routes` rake task (@janko)

## 1.5.1 (2022-06-19)

* Fix syntax for creating `citext` PG extension in Sequel base migration (@Empact)

## 1.5.0 (2022-06-11)

* Remove `content_for` calls from generated view templates (@janko)

* Set title instance variable to `@page_title` in generated configuration (@janko)

* Set title instance variable on the controller when `title_instance_variable` is set (@HoneyryderChuck)

## 1.4.2 (2022-05-15)

* Stop passing email addresses in mailer arguments on verifying login change (@janko)

* Extract finding account into a method in the generated mailer (@janko)

* Make generated Action Mailer integration work with secondary Rodauth configurations (@janko)

* Include `Rodauth::Rails.model` in generated Sequel account model as well (@janko)

## 1.4.1 (2022-05-08)

* Deprecate `Rodauth::Rails::Model` constant (@janko)

* Remove `Rodauth::Rails::Auth#associations` in favour of new association registration API (@janko)

* Extract model mixin into the rodauth-model gem (@janko)

## 1.4.0 (2022-05-04)

* Move association definitions to `#associations` Rodauth method, allowing external features to extend them (@janko)

* Add Sequel support for generating database migrations, model, and mailer (@janko)

* Skip calling Rodauth app on asset requests when using Sprockets or Propshaft (@janko)

## 1.3.1 (2022-04-22)

* Ensure response status is logged when calling a halting rodauth method inside a controller (@janko)

## 1.3.0 (2022-04-01)

* Store password hash on the `accounts` table in generated Rodauth migration and configuration (@janko)

* Add support for controller testing with Minitest or RSpec (@janko)

* Fix `enum` declaration in generated `Account` model for Active Record < 7.0 (@janko)

* Ensure `require_login_redirect` points to the login page even if the login route changes (@janko)

## 1.2.2 (2022-02-22)

* Fix flash messages not being preserved through consecutive redirects (@janko)

## 1.2.1 (2022-02-19)

* Change `accounts.status` column type from string to integer (@zhongsheng)

## 1.2.0 (2022-02-11)

* Work around Active Record 4.2 not supporting procs for literal SQL column default (@janko)

* Avoid re-fetching the account in `#current_account` when it has already been fetched by Rodauth (@janko)

* Extract `#current_account` helper functionality into `#rails_account` Rodauth method (@janko)

* Use default account status values in generated configuration, with enum on `Account` model (@janko)

## 1.1.0 (2022-01-16)

* Automatically route the path prefix in `r.rodauth` if one has been set (@janko)

## 1.0.0 (2021-12-25)

* Set Rodauth's email subject in the generated mailer (@janko)

* Raise error when outside of a request and `config.action_mailer.default_url_options` is unset (@janko)

* Avoid method re-definition warnings with named auth classes caused by `post_configure` being called twice (@janko)

* Don't modify `config.action_mailer.default_url_options` when `:protocol` is missing (@janko)

* Move `Rodauth::Rails.url_options` into `Rodauth::Auth#rails_url_options` (@janko)

* Generate named auth classes in `rodauth:install` generator (@janko)

* Generate `rodauth_app.rb` in `app/misc` directory (@janko)

* Add `--name` option to `rodauth:migration` generator (@janko)

* Disable Turbo in all built-in and generated views (@janko)

* Modify generated mailer integration to generate URLs according to `default_url_options` (@janko)

* Skip Active Record files in `rodauth:install` if `ActiveRecord::Railtie` is not defined (@janko)

* Stop loading `pass` plugin in `Rodauth::Rails::App` (@janko)

* Remove deprecated `:query` and `:form` options in `Rodauth::Rails.rodauth` (@janko)

* Require internal_request feature to be enabled in `Rodauth::Rails.rodauth` (@janko)

## 0.18.1 (2021-12-16)

* Loosen Rails gem dependency to allow Rails 7.x (Intrepidd)

## 0.18.0 (2021-11-05)

* Disable Turbo on the generated login form (@janko)

* Generate controller views with `form_with` helper on Rails 5.1+ (@janko)

* Fix missing layout error when rendering Rodauth's built-in templates when using Turbo on Rails 6.0+ (@janko)

* Fix `Rodauth::Rails.middleware` config not actually affecting middleware insertion (@janko)

* Set page titles in generated view templates (@janko)

* Merge field and button partials into view templates (@janko)

* Raise error for unknown configuration in `Rodauth::Rails.model` (@janko)

* Generate views for all enabled features by default in `rodauth:views` generator (@janko)

* Add `Rodauth::Rails::App.rodauth!` which raises an error for unknown configuration (@janko)

* Remove deprecated `--features` option from `rodauth:views` generator (@janko)

* Inline `_recovery_codes_form.html.erb` partial into `recovery_codes.html.erb` (@janko)

* Use Rodauth helper methods for texts in generated views, for easier i18n (@janko)

* Allow setting passing a `Sequel::Model` to `:account` in `Rodauth::Rails.rodauth` (@janko)

## 0.17.1 (2021-10-20)

* Skip checking CSRF when request forgery protection wasn't loaded on the controller (@janko)

* Create partial unique index for `accounts.email` column when using `sqlite3` adapter (@janko)

* Revert setting `delete_account_on_close?` to `true` in generated `rodauth_app.rb` (@janko)

* Disable Turbo in `_recovery_codes_form.html.erb`, since viewing recovery codes isn't Turbo-compatible (@janko)

* Generate JSON configuration on `rodauth:install` for API-only with sessions enabled (@janko)

* Generate JWT configuration on `rodauth:install` only for API-only apps without sessions enabled (@janko)

* Don't generate JWT configuration when `rodauth:install --json` was run in API-only app (@janko)

* Use `config.action_mailer.default_url_options` in path_class_methods feature (@janko)

## 0.17.0 (2021-10-05)

* Set `delete_account_on_close?` to `true` in generated `rodauth_app.rb` (@janko)

* Change default `:dependent` option for associations to `:delete`/`:delete_all` (@janko)

* Add `rails_account_model` configuration method for when the account model cannot be inferred (@janko)

## 0.16.0 (2021-09-26)

* Add `#current_account` to methods defined on `ActionController::Base` (@janko)

* Add missing template for verify_login_change feature to `rodauth:views` generator (@janko)

* Add `#rodauth_response` controller method for converting rodauth responses into controller responses (@janko)

## 0.15.0 (2021-07-29)

* Add `Rodauth::Rails::Model` mixin that defines password attribute and associations on the model (@janko)

* Add support for the new internal_request feature (@janko)

* Implement `Rodauth::Rails.rodauth` in terms of the internal_request feature (@janko)

## 0.14.0 (2021-07-10)

* Speed up template rendering by only searching formats accepted by the request (@janko)

* Add `--name` option to `rodauth:views` generator for specifying different rodauth configuration (@janko)

* Infer correct template path from configured controller in `rodauth:views` generator (@janko)

* Raise `ArgumentError` if undefined rodauth configuration is passed to `Rodauth::Rails.app` (@janko)

* Make `#rails_controller` method on the rodauth instance public (@janko)

* Remove `--directory` option from `rodauth:views` generator (@janko)

* Remove `#features` and `#routes` writer and `#configuration` reader from `Rodauth::Rails::Auth` (@janko)

## 0.13.0 (2021-06-10)

* Add `:query`, `:form`, `:session`, `:account`, and `:env` options to `Rodauth::Rails.rodauth` (@janko)

## 0.12.0 (2021-05-15)

* Include total view render time in logs for Rodauth requests (@janko)

* Instrument redirects (@janko)

* Instrument Rodauth requests on `action_controller` namespace (@janko)

* Update templates for Boostrap 5 compatibility (@janko)

* Log request parameters for Rodauth requests (@janko)

## 0.11.0 (2021-05-06)

* Add controller-like logging for requests to Rodauth endpoints (@janko)

* Add `#rails_routes` to Roda and Rodauth instance for accessing Rails route helpers (@janko)

* Add `#rails_request` to Roda and Rodauth instance for retrieving an `ActionDispatch::Request` instance (@janko)

## 0.10.0 (2021-03-23)

* Add `Rodauth::Rails::Auth` superclass for moving configurations into separate files (@janko)

* Load the `pass` Roda plugin and recommend calling `r.pass` on prefixed routes (@janko)

* Improve Roda middleware inspect output (@janko)

* Create `RodauthMailer` and email templates in `rodauth:install`, and remove `rodauth:mailer` (@janko)

* Raise `KeyError` in `#rodauth` method when the Rodauth instance doesn't exist (@janko)

* Add `Rodauth::Rails.authenticated` routing constraint for requiring authentication (@janko)

## 0.9.1 (2021-02-10)

* Fix flash integration being loaded for API-only apps and causing an error (@dmitryzuev)

* Change account status column default to `unverified` in migration to match Rodauth's default (@basabin54)

## 0.9.0 (2021-02-07)

* Load Roda's JSON support by default, so that enabling `json`/`jwt` feature is all that's needed (@janko)

* Bump Rodauth dependency to 2.9+ (@janko)

* Add `--json` option for `rodauth:install` generator for configuring `json` feature (@janko)

* Add `--jwt` option for `rodauth:install` generator for configuring `jwt` feature (@janko)

* Remove the `--api` option from `rodauth:install` generator (@janko)

## 0.8.2 (2021-01-10)

* Reset Rails session on `#clear_session`, protecting from potential session fixation attacks (@janko)

## 0.8.1 (2021-01-04)

* Fix blank email body when `json: true` and `ActionController::API` descendant are used (@janko)

* Make view and email rendering work when there are multiple configurations and one is `json: :only` (@janko)

* Don't attempt to protect against forgery when `ActionController::API` descendant is used (@janko)

* Mark content of rodauth built-in partials as HTML-safe (@janko)

## 0.8.0 (2021-01-03)

* Add `--api` option to `rodauth:install` generator for choosing JSON-only configuration (@janko)

* Don't blow up when a Rodauth request is made using an unsupported HTTP verb (@janko)

## 0.7.0 (2020-11-27)

* Add `#rails_controller_eval` method for running code in context of a controller instance (@janko)

* Detect `secret_key_base` from credentials and `$SECRET_KEY_BASE` environment variable (@janko)

## 0.6.1 (2020-11-25)

* Generate the Rodauth controller for API-only Rails apps as well (@janko)

* Fix remember cookie deadline not extending in remember feature (@janko)

## 0.6.0 (2020-11-22)

* Add `Rodauth::Rails.rodauth` method for retrieving Rodauth instance outside of request context (@janko)

* Add default Action Dispatch response headers in Rodauth responses (@janko)

* Run controller rescue handlers around Rodauth actions (@janko)

* Run controller action callbacks around Rodauth actions (@janko)

## 0.5.0 (2020-11-16)

* Support more Active Record adapters in `rodauth:install` generator (@janko)

* Add `rodauth:migration` generator for creating tables of specified features (@janko)

* Use UUIDs for primary keys if so configured in Rails generators (@janko)

* Add `rodauth:routes` rake task for printing routes handled by Rodauth middleware (@janko)

## 0.4.2 (2020-11-08)

* Drop support for Ruby 2.2 (@janko)

* Bump `sequel-activerecord_connection` dependency to 1.1+ (@janko)

* Set default bcrypt hash cost to `1` in tests (@janko)

* Call `AR::Base.connection_db_config` on Rails 6.1+ in `rodauth:install` generator (@janko)

## 0.4.1 (2020-11-02)

* Don't generate `RodauthController` in API-only mode (@janko)

* Pass `test: false` to Sequel in the `sequel.rb` initializer (@janko)

## 0.4.0 (2020-11-02)

* Support Rails API-only mode (@janko)

* Make `rodauth:install` create `rodauth_app.rb` in `app/lib/` directory (@janko)

## 0.3.1 (2020-10-25)

* Depend on sequel-activerecord_connection 1.0+ (@janko)

## 0.3.0 (2020-09-18)

* Handle custom configured database migration paths in install generator (@janko)

* Allow specifying features as plain arguments in `rodauth:views` generator (@janko)

* Add some missing foreign key constraints in generated migration file (@janko)

## 0.2.1 (2020-07-26)

* Fix incorrect JDBC connect syntax in `sequel.rb` template on JRuby (@janko)

## 0.2.0 (2020-07-26)

* Drop support for Rodauth 1.x (@janko)

* Change `rodauth_app.rb` template to send emails in the background after transaction commit (@janko)

* Bump `sequel-activerecord_connection` dependency to `~> 0.3` (@janko)

* Use the JDBC adapter in sequel.rb initializer when on JRuby (@janko)

## 0.1.3 (2020-07-04)

* Remove insecure MFA integration with remember feature suggestion in `lib/rodauth_app.rb` (@janko, @nicolas-besnard)

* Use correct password autocomplete value on Rodauth 2.1+ (@janko)

* Enable skipping CSRF protection on Rodauth 2.1+ by overriding `#check_csrf?` (@janko)

* Don't generate Sequel initializer if Sequel connection exists (@janko)

* Fix typo in remember view template (@nicolas-besnard)

* Fix some more typos in `lib/rodauth_app.rb` (@janko)

## 0.1.2 (2020-05-14)

* Fix some typos in comment suggestions in `lib/rodauth_app.rb` (@janko)

## 0.1.1 (2020-05-09)

* Include view templates in the gem (@janko)
* Use `Login` labels to be consistent with Rodauth (@janko)
