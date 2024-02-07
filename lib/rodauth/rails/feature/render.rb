module Rodauth
  module Rails
    module Feature
      module Render
        extend ActiveSupport::Concern

        included do
          auth_methods :rails_render
        end

        # Renders templates with layout. First tries to render a user-defined
        # template, otherwise falls back to Rodauth's template.
        def view(page, title)
          set_title(title)
          rails_render(action: page.tr("-", "_"), layout: true) ||
            rails_render(html: super.html_safe, layout: true, formats: :html)
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

        if defined?(::Turbo)
          def turbo_stream
            rails_controller_instance.send(:turbo_stream)
          end
        end

        private

        # Calls the Rails renderer, returning nil if a template is missing.
        def rails_render(*args)
          return if rails_controller <= ActionController::API

          rails_controller_instance.render_to_string(*args)
        rescue ActionView::MissingTemplate
          nil
        end

        # Only look up template formats that the current request is accepting.
        def before_rodauth
          super
          rails_controller_instance.formats = rails_request.formats.map(&:ref).compact
        end

        # Not all Rodauth actions are Turbo-compatible (some form submissions
        # render 200 HTML responses), so we disable Turbo on all Rodauth forms.
        def _view(meth, *)
          html = super
          html = html.gsub(/<form([^>]+)>/, '<form\1 data-turbo="false">') if meth == :view
          html
        end

        def set_title(title)
          if title_instance_variable
            rails_controller_instance.instance_variable_set(title_instance_variable, title)
          end
        end
      end
    end
  end
end
