## HEAD

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
