source "https://rubygems.org"

gemspec

gem "sequel-activerecord_connection", "~> 2.0"
gem "after_commit_everywhere", "~> 1.1"

gem "rake", "~> 13.0"
gem "warning"

gem "rails", "~> 8.0"
gem "turbo-rails", "~> 1.4"
gem "sqlite3", "~> 2.0",                platforms: [:mri, :truffleruby]
gem "activerecord-jdbcsqlite3-adapter", platforms: :jruby

gem "capybara"

if RUBY_VERSION >= "3.1.0"
  # mail gem dependencies on Ruby 3.1+
  gem "net-smtp"
  gem "net-imap"
  gem "net-pop"

  # rake gem dependency on Ruby 3.1+
  gem "matrix"
end
