require "#{__dir__}/configuration"
require "#{__dir__}/../views_generator"

module Rodauth
  module Rails
    module Generators
      module Concerns
        module FeatureOptions
          def self.included(base)
            base.send :include, Configuration

            base.send :class_option, :primary, type: :boolean, desc: '[CONFIG] this account is primary. True during install.'
            base.send :class_option, :argon2, type: :boolean, default: false, desc: '[CONFIG] use Argon2 for password hashing'
            base.send :class_option, :mails, type: :boolean, default: true, desc: '[CONFIG] setup mails'
            base.send :class_option, :api_only, type: :boolean, default: false, desc: '[CONFIG] only'

            base::CONFIGURATION.sort.each do |plugin, opts|
              plugin = plugin.to_sym
              base.send :class_option, plugin, type: :boolean, default: opts[:default],
                                               desc: opts[:desc] || "[PLUGIN] #{plugin}"

              next if %i[remember json jwt].include? plugin

              base.define_method "#{plugin}?" do
                kitchen_sink? || options[plugin]
              end
            end

            base.send :class_option, :kitchen_sink, type: :boolean, default: false,
                                                    desc: '[CONFIG] enable all supported plugins'
          end

          private

          def invoke_options
            extra_options = %i[primary argon2 mails kitchen_sink]
            valid_options = self.class::CONFIGURATION.keys.map(&:to_sym).concat extra_options

            opts = valid_options.map {|opt| [opt, send("#{opt}?".to_sym)] }.to_h.compact
            %i[api_only force skip pretend quiet].each do |key|
              next unless options[key]

              opts[key] = options[key]
            end

            opts
          end

          def enabled_features
            @enabled_features ||= self.class::CONFIGURATION.keys.select { |feature| send("#{feature}?") }
          end

          def enabled_plugins
            @enabled_plugins ||= enabled_features - %i[base]
          end

          def migration_features
            enabled_features.select{ |feature| self.class::CONFIGURATION[feature][:migrations] != false }.map(&:to_s)
          end

          def view_features
            enabled_features.select{ |feature| ViewsGenerator::VIEWS[feature] }.map(&:to_s)
          end

          def primary?
            options[:primary]
          end

          def argon2?
            options[:argon2]
          end

          def mails?
            defined?(ActionMailer) && options[:mails]
          end

          def json?
            (kitchen_sink? || options[:json]) || only_json?
          end

          def jwt?
            (kitchen_sink? || options[:jwt]) || only_json?
          end

          def remember?
            !only_json? && (kitchen_sink? || options[:remember])
          end

          def kitchen_sink?
            options[:kitchen_sink]
          end

          def only_json?
            ::Rails.application.config.api_only || !::Rails.application.config.session_store || options[:api_only]
          end
        end
      end
    end
  end
end
