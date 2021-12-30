require_relative '../exceptions'

module Inferno
  module Terminology
    module BCP47
      # https://tools.ietf.org/html/bcp47
      # https://tools.ietf.org/html/rfc5646
      # https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry
      #
      class << self
        SEPARATOR = '%%'.freeze
        REGISTRY_URL = 'https://www.iana.org/assignments/language-subtag-registry/language-subtag-registry'.freeze

        def code_set(filter = nil)
          filter_codes(filter)
        end

        def load_bcp47
          response = RestClient.get REGISTRY_URL
          response.body.split(SEPARATOR).drop(1)
        end

        def filter_codes(filter = nil)
          bcp47 = bcp
          cs_set = Set.new
          bcp47.each do |raw_language|
            language = parse_language(raw_language)
            next if language['Subtag'].nil?
            next if language['Type'] == 'region'

            cs_set.add(system: 'urn:ietf:bcp:47', code: language['Subtag']) if meets_filter_criteria?(language, filter)
          end
          cs_set
        end

        private

        @bcp = nil
        def bcp
          @bcp ||= load_bcp47
        end

        # Parse the language attributes chunk from the text file
        #
        # @param [String] language A single language and its attributes from the file
        # @return [Hash] the language attributes as key value pairs
        def parse_language(language)
          # Need to use scan because match only returns the first match group
          language.scan(regex).to_h
        end

        def regex
          /^(?<key>\S+): (?<value>.*)$/
        end

        def string_to_boolean(boolean_string)
          case boolean_string
          when 'true'
            true
          when 'false'
            false
          end
        end

        def meets_filter_criteria?(language, filter)
          return true unless filter

          meets_criteria = true

          raise FilterOperationException, filter.op unless filter.op == 'exists'

          filter_value = string_to_boolean(filter.value)
          raise FilterOperationException, filter.to_s if filter_value.nil?

          case filter.property
          when 'ext-lang'
            meets_criteria = (language['Type'] == 'extlang') == filter_value
          when 'script'
            meets_criteria = (language['Type'] == 'script') == filter_value
          when 'variant'
            meets_criteria = (language['Type'] == 'variant') == filter_value
          when 'extension'
            meets_criteria = language['Subtag'].match?(/-\w-/) == filter_value
          when 'private-use'
            meets_criteria = (language['Scope'] == 'private-use') == filter_value
          else
            raise FilterOperationException, filter.to_s
          end

          meets_criteria
        end
      end
    end
  end
end
