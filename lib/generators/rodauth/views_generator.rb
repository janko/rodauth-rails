require "rails/generators/base"

module Rodauth
  module Rails
    module Generators
      class ViewsGenerator < ::Rails::Generators::Base
        source_root "#{__dir__}/templates"
        namespace "rodauth:views"

        def copy_controller
          template "app/controllers/rodauth_controller.rb"
        end

        def copy_helper
          template "app/helpers/rodauth_helper.rb"
        end

        def copy_views
          directory "app/views/rodauth"
        end
      end
    end
  end
end
