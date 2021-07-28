module Rodauth
  module Rails
    module Feature
      module Render
        def self.included(feature)
          feature.auth_methods :rails_render
        end

        # Renders templates with layout. First tries to render a user-defined
        # template, otherwise falls back to Rodauth's template.
        def view(page, *)
          rails_render(action: page.tr("-", "_"), layout: true) ||
            rails_render(html: super.html_safe, layout: true)
        end

        # Renders templates without layout. First tries to render a user-defined
        # template or partial, otherwise falls back to Rodauth's template.
        def render(page)
          rails_render(partial: page.tr("-", "_"), layout: false) ||
            rails_render(action: page.tr("-", "_"), layout: false) ||
            super.html_safe
        end

        def button(*)
          super.html_safe
        end

        private

        # Calls the Rails renderer, returning nil if a template is missing.
        def rails_render(*args)
          return if rails_api_controller?

          rails_controller_instance.render_to_string(*args)
        rescue ActionView::MissingTemplate
          nil
        end

        # Only look up template formats that the current request is accepting.
        def _rails_controller_instance
          controller = super
          controller.formats = rails_request.formats.map(&:ref).compact
          controller
        end
      end
    end
  end
end
