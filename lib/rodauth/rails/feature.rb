module Rodauth
  Feature.define(:rails) do
    # Assign feature and feature configuration to constants for introspection.
    Rodauth::Rails::Feature              = self
    Rodauth::Rails::FeatureConfiguration = self.configuration

    require "rodauth/rails/feature/base"
    require "rodauth/rails/feature/callbacks"
    require "rodauth/rails/feature/csrf"
    require "rodauth/rails/feature/render"
    require "rodauth/rails/feature/email"
    require "rodauth/rails/feature/instrumentation"
    require "rodauth/rails/feature/internal_request"
    require "rodauth/rails/feature/associations"

    include Rodauth::Rails::Feature::Base
    include Rodauth::Rails::Feature::Callbacks
    include Rodauth::Rails::Feature::Csrf
    include Rodauth::Rails::Feature::Render
    include Rodauth::Rails::Feature::Email
    include Rodauth::Rails::Feature::Instrumentation
    include Rodauth::Rails::Feature::InternalRequest
    include Rodauth::Rails::Feature::Associations
  end
end
