require 'sqlite3'
require 'date'
require 'fhir_models'

require_relative '../exceptions'
require_relative 'bcp_13'
require_relative 'bcp47'
require_relative 'codesystem'
require_relative 'fhir_package_manager'

module Inferno
  module Terminology
    class ValueSet
      # STU3 ValueSets located at: http://hl7.org/fhir/stu3/terminologies-valuesets.html
      # STU3 ValueSet Resource: http://hl7.org/fhir/stu3/valueset.html
      #
      # snomed in umls: https://www.nlm.nih.gov/research/umls/Snomed/snomed_represented.html

      # The UMLS Database
      attr_accessor :db
      # The FHIR::Model Representation of the ValueSet
      attr_accessor :value_set_model

      # Flag to say "use the provided expansion" when processing the valueset
      attr_accessor :use_expansions

      @value_sets_repo = Inferno::Repositories::ValueSets.new

      class << self
        attr_reader :value_sets_repo
      end

      # UMLS Vocabulary: https://www.nlm.nih.gov/research/umls/sourcereleasedocs/index.html
      SAB = {
        'http://unitsofmeasure.org' => {
          abbreviation: 'NCI_UCUM',
          name: 'Unified Code for Units of Measure (UCUM)'
        }.freeze,
        'http://loinc.org' => {
          abbreviation: 'LNC',
          name: 'Logical Observation Identifiers Names and Codes terminology (LOINC)'
        }.freeze,
        'http://snomed.info/sct' => {
          abbreviation: 'SNOMEDCT_US',
          name: 'Systematized Nomenclature of Medicine-Clinical Terms (SNOMED CT), US Edition'
        }.freeze
        # The systems below are needed if building all terminology rather than
        # only the required bindings.
        # 'http://www.nlm.nih.gov/research/umls/rxnorm' => {
        #   abbreviation: 'RXNORM',
        #   name: 'RxNorm Vocabulary'
        # }.freeze,
        # 'http://www.cms.gov/Medicare/Coding/ICD10' => {
        #   abbreviation: 'ICD10PCS',
        #   name: 'ICD-10 Procedure Coding System (ICD-10-PCS)'
        # }.freeze,
        # 'http://hl7.org/fhir/sid/cvx' => {
        #   abbreviation: 'CVX',
        #   name: 'Vaccines Administered (CVX)'
        # }.freeze,
        # 'http://hl7.org/fhir/sid/icd-10-cm' => {
        #   abbreviation: 'ICD10CM',
        #   name: 'International Classification of Diseases, Tenth Revision, Clinical Modification (ICD-10-CM)'
        # }.freeze,
        # 'http://hl7.org/fhir/sid/icd-9-cm' => {
        #   abbreviation: 'ICD9CM',
        #   name: 'International Classification of Diseases, Ninth Revision, Clinical Modification (ICD-9-CM)'
        # }.freeze,
        # 'urn:oid:2.16.840.1.113883.6.101' => {
        #   abbreviation: 'NUCCHCPT',
        #   name: 'National Uniform Claim Committee - Health Care Provider Taxonomy (NUCCHCPT)'
        # },
        # 'http://nucc.org/provider-taxonomy' => {
        #   abbreviation: 'NUCCHCPT',
        #   name: 'National Uniform Claim Committee - Health Care Provider Taxonomy (NUCCHCPT)'
        # }.freeze,
        # 'http://www.ama-assn.org/go/cpt' => {
        #   abbreviation: 'CPT',
        #   name: 'Current Procedural Terminology (CPT)'
        # }.freeze,
        # 'http://www.cms.gov/Medicare/Coding/HCPCSReleaseCodeSets' => {
        #   abbreviation: 'HCPCS',
        #   name: 'Healthcare Common Procedure Coding System (HCPCS)'
        # }.freeze,
        # 'urn:oid:2.16.840.1.113883.6.285' => {
        #   abbreviation: 'HCPCS',
        #   name: 'Healthcare Common Procedure Coding System (HCPCS)'
        # }.freeze,
        # 'urn:oid:2.16.840.1.113883.6.13' => {
        #   abbreviation: 'CDT',
        #   name: 'Code on Dental Procedures and Nomenclature (CDT)'
        # }.freeze,
        # 'http://ada.org/cdt' => {
        #   abbreviation: 'CDT',
        #   name: 'Code on Dental Procedures and Nomenclature (CDT)'
        # },
        # 'http://www.ada.org/cdt' => {
        #   abbreviation: 'CDT',
        #   name: 'Code on Dental Procedures and Nomenclature (CDT)'
        # }
      }.freeze

      CODE_SYS = {
        'urn:ietf:bcp:13' => -> { BCP13.code_set },
        'urn:ietf:bcp:47' => ->(filter = nil) { BCP47.code_set(filter) },
        'http://ihe.net/fhir/ValueSet/IHE.FormatCode.codesystem' =>
          -> { value_sets_repo.find('http://hl7.org/fhir/ValueSet/formatcodes').value_set },
        'https://www.usps.com/' =>
          lambda do
            codes = [
              'AL', 'AK', 'AS', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'DC', 'FM',
              'FL', 'GA', 'GU', 'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA',
              'ME', 'MH', 'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV',
              'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'MP', 'OH', 'OK', 'OR', 'PW',
              'PA', 'PR', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VI', 'VA',
              'WA', 'WV', 'WI', 'WY', 'AE', 'AP', 'AA'
            ]
            codes.each_with_object(Set.new) do |code, set|
              set.add(system: 'https://www.usps.com/', code:)
            end
          end
      }.freeze

      # https://www.nlm.nih.gov/research/umls/knowledge_sources/metathesaurus/release/attribute_names.html
      FILTER_PROP = {
        'CLASSTYPE' => 'LCN',
        'DOC' => 'Doc',
        'SCALE_TYP' => 'LOINC_SCALE_TYP'
      }.freeze

      def initialize(database, use_expansions = true) # rubocop:disable Style/OptionalBooleanParameter
        @db = database
        @use_expansions = use_expansions
      end

      def umls_abbreviation(system)
        if system != 'http://nucc.org/provider-taxonomy' && system != 'urn:oid:2.16.840.1.113883.6.101'
          return SAB.dig(system, :abbreviation)
        end

        @nucc_system ||= # rubocop:disable Naming/MemoizedInstanceVariableName
          if @db.execute("SELECT COUNT(*) FROM mrconso WHERE SAB = 'NUCCPT'").flatten.first.positive?
            'NUCCPT'
          else
            'NUCCHCPT'
          end
      end

      def code_system_metadata(system)
        SAB[system]
      end

      def value_sets_repo
        self.class.value_sets_repo
      end

      # The ValueSet [Set]
      def value_set
        return @value_set if @value_set

        if @use_expansions
          process_with_expansions
        else
          process_value_set
        end
      end

      # Read the desired valueset from a JSON file
      #
      # @param filename [String] the name of the file
      def read_value_set(filename)
        @value_set_model = FHIR::Json.from_json(File.read(filename))
      end

      def code_system_set(code_system)
        filter_code_set(code_system)
      end

      def expansion_as_fhir_value_set
        expansion_backbone = FHIR::ValueSet::Expansion.new
        expansion_backbone.timestamp = DateTime.now.strftime('%Y-%m-%dT%H:%M:%S%:z')
        expansion_backbone.contains = value_set.map do |code|
          FHIR::ValueSet::Expansion::Contains.new({ system: code[:system], code: code[:code] })
        end
        expansion_backbone.total = expansion_backbone.contains.length
        expansion_value_set = @value_set_model.deep_dup # Make a copy so that the original definition is left intact
        expansion_value_set.expansion = expansion_backbone
        expansion_value_set
      end

      # Return the url of the valueset
      def url
        @value_set_model.url
      end

      # Return the number of codes in the valueset
      def count
        @value_set.length
      end

      def all_included_code_systems
        (included_code_systems + code_systems_in_codings).uniq
      end

      def included_code_systems
        @value_set_model.compose.include.map(&:system).compact.uniq
      end

      def code_systems_in_codings
        return [] if value_set.blank?

        value_set
          .map { |coding| coding[:system] }
          .compact
          .uniq
      end

      TOO_COSTLY_URL = 'http://hl7.org/fhir/StructureDefinition/valueset-toocostly'.freeze
      def too_costly?
        @value_set_model&.expansion&.extension&.find { |vs| vs.url == TOO_COSTLY_URL }&.value
      end

      UNCLOSED_URL = 'http://hl7.org/fhir/StructureDefinition/valueset-unclosed'.freeze
      def unclosed?
        @value_set_model&.expansion&.extension&.find { |vs| vs.url == UNCLOSED_URL }&.value
      end

      def expansion_present?
        !!@value_set_model&.expansion&.contains
      end

      # Delegates to process_expanded_valueset if there's already an expansion
      # Otherwise it delegates to process_valueset to do the expansion
      def process_with_expansions
        if expansion_present?
          # This is moved into a nested clause so we can tell in the debug statements which path we're taking
          if too_costly? || unclosed?
            Inferno.logger.debug("ValueSet too costly or unclosed: #{url}")
            process_value_set
          else
            Inferno.logger.debug("Processing expanded valueset: #{url}")
            process_expanded_value_set
          end
        else
          Inferno.logger.debug("Processing composed valueset: #{url}")
          process_value_set
        end
      end

      # Creates the whole valueset
      #
      # Creates a [Set] representing the valueset
      def process_value_set
        Inferno.logger.debug "Processing #{@value_set_model.url}"
        include_set = Set.new
        @value_set_model.compose.include.each do |include|
          # Cumulative of each include
          include_set.merge(get_code_sets(include))
        end
        @value_set_model.compose.exclude.each do |exclude|
          # Remove excluded codes
          include_set.subtract(get_code_sets(exclude))
        end
        @value_set = include_set
      end

      def process_expanded_value_set
        include_set = Set.new
        @value_set_model.expansion.contains.each do |contain|
          include_set.add(system: contain.system, code: contain.code)
        end
        @value_set = include_set
      end

      # Checks if the provided code is in the valueset
      #
      # Codes should be provided as a [Hash] type object
      #
      # e.g. {system: 'http://loinc.org', code: '1234'}
      #
      # @param [Hash] code the code to evaluate
      # @return [Boolean]
      def contains_code?(code)
        @value_set.include? code
      end

      def generate_bloom
        require 'bloomer'

        @bf = Bloomer::Scalable.create_with_sufficient_size(value_set.length)
        value_set.each do |cc|
          @bf.add_without_duplication("#{cc[:system]}|#{cc[:code]}")
        end
        @bf
      end

      # Saves the valueset bloomfilter to a msgpack file
      #
      # @param [String] filename the name of the file
      def save_bloom_to_file(
        filename = "resources/validators/bloom/#{(URI(url).host + URI(url).path).gsub(%r{[./]}, '_')}.msgpack"
      )
        generate_bloom unless @bf
        bloom_file = File.new(filename, 'wb')
        bloom_file.write(@bf.to_msgpack) unless @bf.nil?
        filename
      end

      # Saves the valueset to a csv
      # @param [String] filename the name of the file
      def save_csv_to_file(filename = "resources/validators/csv/#{(URI(url).host + URI(url).path).gsub(%r{[./]},
                                                                                                       '_')}.csv")
        CSV.open(filename, 'wb') do |csv|
          value_set.each do |code|
            csv << [code[:system], code[:code]]
          end
        end
      end

      # Load a code system from a file
      #
      # @param [String] filename the file containing the code system JSON
      def self.load_system(filename)
        # TODO: Generalize this
        cs = FHIR::Json.from_json(File.read(filename))
        cs_set = Set.new
        load_codes = lambda do |concept|
          concept.each do |concept_code|
            cs_set.add(system: cs.url, code: concept_code.code)
            load_codes.call(concept_code.concept) unless concept_code.concept.empty?
          end
        end
        load_codes.call(cs.concept)
        cs_set
      end

      private

      # Get all the code systems from within an include/exclude and return the set representing the intersection
      #
      # See: http://hl7.org/fhir/stu3/valueset.html#compositions
      #
      # @param [ValueSet::Compose::Include] vscs the FHIR ValueSet include or exclude
      def get_code_sets(vscs)
        intersection_set = nil

        # Get Concepts
        if !vscs.concept.empty?
          intersection_set = Set.new
          vscs.concept.each do |concept|
            intersection_set.add(system: vscs.system, code: concept.code)
          end
          # Filter based on the filters. Note there cannot be both concepts and filters within a single include/exclude
        elsif !vscs.filter.empty?
          intersection_set = filter_code_set(vscs.system, vscs.filter.first)
          vscs.filter.drop(1).each do |filter|
            intersection_set = intersection_set.intersection(filter_code_set(vscs.system, filter))
          end
          # Import whole code systems if given
        elsif vscs.system
          intersection_set = filter_code_set(vscs.system)
        end

        unless vscs.valueSet.empty?
          # If no concepts or filtered systems were present and already created the intersection_set
          im_val_set = import_value_set(vscs.valueSet.first).value_set
          vscs.valueSet.drop(1).each do |im_val|
            im_val_set = im_val_set.intersection(import_value_set(im_val).value_set)
          end
          intersection_set = intersection_set.nil? ? im_val_set : intersection_set.intersection(im_val_set)
        end
        intersection_set
      end

      # Provides a codeset based on the system and filters provided
      # @param [String] system the code system url
      # @param [FHIR::ValueSet::Compose::Include::Filter] filter the filter object
      # @return [Set] the filtered set of codes
      def filter_code_set(system, filter = nil, _version = nil)
        fhir_codesystem = File.join(PACKAGE_DIR, "#{FHIRPackageManager.encode_name(system)}.json")
        if CODE_SYS.include? system
          Inferno.logger.debug "  loading #{system} codes..."
          return filter.nil? ? CODE_SYS[system].call : CODE_SYS[system].call(filter)
        elsif File.exist?(fhir_codesystem)
          if umls_abbreviation(system).nil?
            fhir_cs = Inferno::Terminology::Codesystem
              .new(FHIR::Json.from_json(File.read(fhir_codesystem)))

            raise UnknownCodeSystemException, system if fhir_cs.codesystem_model.concept.empty?

            return fhir_cs.filter_codes(filter)
          end
        end

        filter_clause = lambda do |filter| # rubocop:disable Lint/ShadowingOuterLocalVariable
          where = +''
          case filter.op
          when 'in'
            col = filter.property
            vals = filter.value.split(',')
            where << "( #{col} = '#{vals[0]}'"
            # Remove the first element after we've used it
            vals.shift
            vals.each do |val|
              where << " OR #{col} = '#{val}' "
            end
            where << ')'
          when '='
            col = filter.property
            where << "#{col} = '#{filter.value}'"
          else
            Inferno.logger.debug "Cannot handle filter operation: #{filter.op}"
          end
          where
        end

        filtered_set = Set.new
        raise FilterOperationException, filter&.op unless ['=', 'in', 'is-a', nil].include? filter&.op
        raise UnknownCodeSystemException, system if umls_abbreviation(system).nil?

        # Fix for some weirdness around UMLS and provider taxonomy subsetting
        if system == 'http://nucc.org/provider-taxonomy'
          @db.execute(
            "SELECT code FROM mrconso WHERE SAB = '#{umls_abbreviation(system)}' AND TTY IN('PT', 'OP')"
          ) do |row|
            filtered_set.add(system:, code: row[0])
          end
        elsif filter.nil?
          @db.execute("SELECT code FROM mrconso WHERE SAB = '#{umls_abbreviation(system)}'") do |row|
            filtered_set.add(system:, code: row[0])
          end
        elsif ['=', 'in', nil].include? filter&.op
          if FILTER_PROP[filter.property]
            @db.execute(
              "SELECT code FROM mrsat WHERE SAB = '#{umls_abbreviation(system)}' " \
              "AND ATN = '#{fp_self(filter.property)}' AND ATV = '#{fp_self(filter.value)}'"
            ) do |row|
              filtered_set.add(system:, code: row[0])
            end
          else
            @db.execute(
              "SELECT code FROM mrconso WHERE SAB = '#{umls_abbreviation(system)}' AND #{filter_clause.call(filter)}"
            ) do |row|
              filtered_set.add(system:, code: row[0])
            end
          end
        elsif filter&.op == 'is-a'
          filtered_set = filter_is_a(system, filter)
        else
          raise FilterOperationException, filter&.op
        end
        filtered_set
      rescue UnknownCodeSystemException => e
        Inferno.logger.debug e.message
        filtered_set.presence || Set.new
      end

      # Imports the ValueSet with the provided URL from the known local ValueSet Authority
      #
      # @param [Object] url the url of the desired valueset
      # @return [Set] the imported valueset
      def import_value_set(desired_url)
        value_sets_repo.find(desired_url)
      end

      # Filters UMLS codes for "is-a" filters
      #
      # @param [String] system The code system url
      # @param [FHIR::ValueSet::Compose::Include::Filter] filter the filter object
      # @return [Set] the filtered codes
      def filter_is_a(system, filter)
        children = {}
        find_children = lambda do |_parent, system| # rubocop:disable Lint/ShadowingOuterLocalVariable
          @db.execute("SELECT c1.code, c2.code
          FROM mrrel r
            JOIN mrconso c1 ON c1.aui=r.aui1
            JOIN mrconso c2 ON c2.aui=r.aui2
          WHERE r.rel='CHD' AND r.SAB= '#{umls_abbreviation(system)}'") do |row|
            children[row[0]] ||= []
            children[row[0]] << row[1]
          end
        end
        # Get all the children/parent hierarchy
        find_children.call(filter.value, system)

        desired_children = Set.new
        subsume = lambda do |parent|
          # Only execute if we haven't processed this parent yet
          par = { system:, code: parent }
          unless desired_children.include? par
            desired_children.add(system:, code: parent)
            children[parent]&.each do |child|
              subsume.call(child)
            end
          end
        end
        subsume.call(filter.value)
        desired_children
      end

      # fp_self is short for filter_prop_or_self
      # @param [String] prop The property name
      # @return [String] either the value from FILTER_PROP for that key, or prop
      #   if that key isn't in FILTER_PROP
      def fp_self(prop)
        FILTER_PROP[prop] || prop
      end
    end
  end
end
