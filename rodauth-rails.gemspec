require_relative "lib/rodauth/rails/version"

Gem::Specification.new do |spec|
  spec.name          = "rodauth-rails"
  spec.version       = Rodauth::Rails::VERSION
  spec.authors       = ["Janko Marohnić"]
  spec.email         = ["janko.marohnic@gmail.com"]

  spec.summary       = %q{Provides Rails integration for Rodauth authentication framework.}
  spec.description   = %q{Provides Rails integration for Rodauth authentication framework.}
  spec.homepage      = "https://github.com/janko/rodauth-rails"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.6"

  spec.files         = Dir["README.md", "LICENSE.txt", "lib/**/*", "*.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 5.1", "< 8.1"
  spec.add_dependency "rodauth", "~> 2.36"
  spec.add_dependency "roda", "~> 3.76"
  spec.add_dependency "rodauth-model", "~> 0.2"

  spec.add_development_dependency "tilt"
  spec.add_development_dependency "bcrypt", "~> 3.1"
  spec.add_development_dependency "jwt"
  spec.add_development_dependency "rotp"
  spec.add_development_dependency "rqrcode"
  spec.add_development_dependency "webauthn" unless RUBY_ENGINE == "jruby"
end
