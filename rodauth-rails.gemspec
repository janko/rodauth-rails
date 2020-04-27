Gem::Specification.new do |spec|
  spec.name          = "rodauth-rails"
  spec.version       = "0.1.0"
  spec.authors       = ["Janko Marohnić"]
  spec.email         = ["janko.marohnic@gmail.com"]

  spec.summary       = %q{Provides Rails integration for Rodauth.}
  spec.description   = %q{Provides Rails integration for Rodauth.}
  spec.homepage      = "https://github.com/janko/rodauth-rails"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.3.0"

  spec.files         = Dir["README.md", "LICENSE.txt", "CHANGELOG.md", "lib/**/*.rb", "*.gemspec"]
  spec.require_paths = ["lib"]

  spec.add_dependency "railties", ">= 5.0", "< 7"
  spec.add_dependency "rodauth", "~> 2.0"
  spec.add_dependency "sequel-activerecord-adapter", "~> 0.1"
  spec.add_dependency "tilt"
  spec.add_dependency "bcrypt"
  spec.add_dependency "dry-configurable", "~> 0.11"
end
