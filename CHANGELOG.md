## HEAD

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
