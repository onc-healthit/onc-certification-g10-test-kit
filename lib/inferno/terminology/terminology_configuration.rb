# frozen_string_literal: true

module Inferno
  class TerminologyConfiguration
    class << self
      def config
        @config =
          if File.file? File.join('config', 'terminology_config.yml')
            YAML.load_file(File.join('config', 'terminology_config.yml')).presence || {}
          else
            {}
          end
      end

      def allowed_systems_metadata
        @allowed_systems_metadata ||=
          Terminology.code_system_metadata
            .select { |url, _metadata| system_allowed?(url) }
      end

      def prohibited_systems
        @prohibited_systems ||=
          Terminology.code_system_metadata
            .reject { |url, _metadata| system_allowed?(url) }
            .keys
      end

      def prohibited_license_restriction_levels
        config[:exclude_license_restriction_levels] || []
      end

      def explicitly_allowed_systems
        config[:include] || []
      end

      def explicitly_prohibited_systems
        config[:exclude] || []
      end

      def system_allowed?(url)
        return true if explicitly_allowed_systems.include?(url)
        return false if explicitly_prohibited_systems.include?(url)

        !prohibited_license_restriction_levels.include?(Terminology.code_system_metadata.dig(url, :restriction_level))
      end

      def system_prohibited?(url)
        !system_allowed?(url)
      end
    end
  end
end
