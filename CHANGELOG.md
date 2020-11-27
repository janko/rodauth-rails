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
