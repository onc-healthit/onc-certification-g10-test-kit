require 'csv'
require 'find'
require_relative 'download_umls_notice'
require_relative 'temp_dir'

module Inferno
  module Terminology
    module Tasks
      class ProcessUMLS
        include TempDir
        include DownloadUMLSNotice

        attr_reader :version

        def initialize(version:)
          @version = version
        end

        def run # rubocop:disable Metrics/CyclomaticComplexity
          Inferno.logger.info 'Looking for `./tmp/terminology/MRCONSO.RRF`...'
          input_file = Find.find(versioned_temp_dir).find { |f| /MRCONSO.RRF$/ =~f }
          if input_file
            start = Time.now
            output_filename = File.join(versioned_temp_dir, 'terminology_umls.txt')
            output = File.open(output_filename, 'w:UTF-8')
            line = 0
            excluded = 0
            excluded_systems = Hash.new(0)
            begin
              Inferno.logger.info "Writing to #{output_filename}..."
              CSV.foreach(input_file, headers: false, col_sep: '|', quote_char: "\x00") do |row|
                line += 1
                include_code = false
                code_system = row[11]
                code = row[13]
                description = row[14]
                case code_system
                when 'SNOMEDCT_US'
                  code_system = 'SNOMED'
                  include_code = (row[4] == 'PF' && ['FN', 'OAF'].include?(row[12]))
                when 'LNC'
                  code_system = 'LOINC'
                  include_code = true
                when 'ICD10CM', 'ICD10PCS'
                  code_system = 'ICD10'
                  include_code = (row[12] == 'PT')
                when 'ICD9CM'
                  code_system = 'ICD9'
                  include_code = (row[12] == 'PT')
                when 'CPT', 'HCPCS'
                  include_code = (row[12] == 'PT')
                when 'MTHICD9'
                  code_system = 'ICD9'
                  include_code = true
                when 'RXNORM'
                  include_code = true
                when 'CVX'
                  include_code = ['PT', 'OP'].include?(row[12])
                when 'SRC'
                  # 'SRC' rows define the data sources in the file
                  include_code = false
                else
                  include_code = false
                  excluded_systems[code_system] += 1
                end
                if include_code
                  output.write("#{code_system}|#{code}|#{description}\n")
                else
                  excluded += 1
                end
              end
            rescue StandardError => e
              Inferno.logger.info "Error at line #{line}"
              Inferno.logger.info e.message
            end
            output.close
            Inferno.logger.info "Processed #{line} lines, excluding #{excluded} redundant entries."
            Inferno.logger.info "Excluded code systems: #{excluded_systems}" unless excluded_systems.empty?
            finish = Time.now
            minutes = ((finish - start) / 60)
            seconds = (minutes - minutes.floor) * 60
            Inferno.logger.info "Completed in #{minutes.floor} minute(s) #{seconds.floor} second(s)."
            Inferno.logger.info 'Done.'
          else
            download_umls_notice
          end
        end
      end
    end
  end
end
