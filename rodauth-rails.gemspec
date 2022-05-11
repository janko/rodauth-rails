require_relative "lib/rodauth/rails/version"

Gem::Specification.new do |spec|
  spec.name          = "rodauth-rails"
  spec.version       = Rodauth::Rails::VERSION
  spec.authors       = ["Janko Marohnić"]
  spec.email         = ["janko.marohnic@gmail.com"]

  spec.summary       = %q{Provides Rails integration for Rodauth.}
  spec.description   = %q{Provides Rails integration for Rodauth.}
  spec.homepage      = "https://github.com/janko/rodauth-rails"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.3"

  spec.files         = Dir["README.md", "LICENSE.txt", "CHANGELOG.md", "lib/**/*", "*.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 4.2", "< 8"
  spec.add_dependency "rodauth", "~> 2.23"
  spec.add_dependency "roda", "~> 3.55"
  spec.add_dependency "sequel-activerecord_connection", "~> 1.1"
  spec.add_dependency "rodauth-model", "~> 0.2"
  spec.add_dependency "tilt"
  spec.add_dependency "bcrypt"

  spec.add_development_dependency "jwt"
  spec.add_development_dependency "rotp"
  spec.add_development_dependency "rqrcode"
  spec.add_development_dependency "webauthn" unless RUBY_ENGINE == "jruby"
end
