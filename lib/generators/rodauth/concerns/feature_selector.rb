require "#{__dir__}/configuration"
require "#{__dir__}/../views_generator"

module Rodauth
  module Rails
    module Generators
      module Concerns
        module FeatureSelector
          def self.included(base)
            base.send :include, Configuration

            base.send :class_option, :primary, type: :boolean,
                                               desc: '[CONFIG] generated account is primary'
            base.send :class_option, :argon2, type: :boolean, default: false,
                                              desc: '[CONFIG] use Argon2 for password hashing'
            base.send :class_option, :mails, type: :boolean, default: true, desc: '[CONFIG] setup mails'
            base.send :class_option, :api_only, type: :boolean, default: false,
                                                desc: '[CONFIG] configure only json api support'

            base::FEATURE_CONFIG.sort.each do |feature, opts|
              feature = feature.to_sym
              modifier = "*" if opts[:default]
              default_description = "[FEATURE]#{modifier} #{feature}"
              base.send :class_option, feature, type: :boolean, desc: opts[:desc] || default_description

              base.define_method "#{feature}?" do
                feature_selected?(feature)
              end
            end

            base.send :class_option, :kitchen_sink, type: :boolean, default: false,
                                                    desc: '[CONFIG] enable all supported features'
          end

          private

          def feature_selected?(feature)
            return true if kitchen_sink?

            feature_selector = configuration[feature]
            case feature
            when :json, :jwt
              return true if only_json?
            when :remember
              return false if only_json?
            end

            # if the feature option is not set, try to get the default.
            options[feature].nil? ? feature_selector[:default] : options[feature]
          end

          def invoke_options
            extra_options = %i[primary argon2 mails kitchen_sink]
            valid_options = feature_config.keys.map(&:to_sym).concat extra_options

            opts = valid_options.map {|opt| [opt, send("#{opt}?".to_sym)] }.to_h.compact
            %i[api_only force skip pretend quiet].each do |key|
              next unless options[key]

              opts[key] = options[key]
            end

            opts
          end

          def enabled_features
            feature_config.keys.select { |feature| send("#{feature}?") }
          end

          def migration_features
            (enabled_features & migration_config.keys).map(&:to_s)
          end

          def view_features
            (enabled_features & view_config.keys).map(&:to_s)
          end

          def primary?
            # During install this defaults to true and must be explicitly turned on.
            # Otherwise, we consider this to be false.
            self.class.to_s == 'Rodauth::Rails::Generators::InstallGenerator' ? options[:primary] != false : options[:primary]
          end

          def argon2?
            options[:argon2]
          end

          def mails?
            defined?(ActionMailer) && options[:mails]
          end

          def only_json?
            ::Rails.application.config.api_only || !::Rails.application.config.session_store || options[:api_only]
          end

          def kitchen_sink?
            options[:kitchen_sink]
          end
        end
      end
    end
  end
end
