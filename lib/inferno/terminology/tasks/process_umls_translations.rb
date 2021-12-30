require 'find'
require_relative 'download_umls_notice'
require_relative 'temp_dir'

module Inferno
  module Terminology
    module Tasks
      class ProcessUMLSTranslations
        include DownloadUMLSNotice

        def run # rubocop:disable Metrics/CyclomaticComplexity
          Inferno.logger.info 'Looking for `./tmp/terminology/MRCONSO.RRF`...'
          input_file = Find.find(File.join(TEMP_DIR, 'terminology')).find { |f| /MRCONSO.RRF$/ =~f }
          if input_file
            start = Time.now
            output_filename = File.join(TEMP_DIR, 'translations_umls.txt')
            output = File.open(output_filename, 'w:UTF-8')
            line = 0
            excluded_systems = Hash.new(0)
            begin
              entire_file = File.read(input_file)
              Inferno.logger.info "Writing to #{output_filename}..."
              current_umls_concept = nil
              translation = Array.new(10)
              entire_file.split("\n").each do |l|
                row = l.split('|')
                line += 1
                concept = row[0]
                if concept != current_umls_concept && !current_umls_concept.nil?
                  output.write("#{translation.join('|')}\n") unless translation[1..-2].compact.length < 2
                  translation = Array.new(10)
                  current_umls_concept = concept
                  translation[0] = current_umls_concept
                elsif current_umls_concept.nil?
                  current_umls_concept = concept
                  translation[0] = current_umls_concept
                end
                code_system = row[11]
                code = row[13]
                translation[9] = row[14]
                case code_system
                when 'SNOMEDCT_US'
                  translation[1] = code if row[4] == 'PF' && ['FN', 'OAF'].include?(row[12])
                when 'LNC'
                  translation[2] = code
                when 'ICD10CM', 'ICD10PCS'
                  translation[3] = code if row[12] == 'PT'
                when 'ICD9CM'
                  translation[4] = code if row[12] == 'PT'
                when 'MTHICD9'
                  translation[4] = code
                when 'RXNORM'
                  translation[5] = code
                when 'CVX'
                  translation[6] = code if ['PT', 'OP'].include?(row[12])
                when 'CPT'
                  translation[7] = code if row[12] == 'PT'
                when 'HCPCS'
                  translation[8] = code if row[12] == 'PT'
                when 'SRC'
                  # 'SRC' rows define the data sources in the file
                else
                  excluded_systems[code_system] += 1
                end
              end
            rescue StandardError => e
              Inferno.logger.info "Error at line #{line}"
              Inferno.logger.info e.message
            end
            output.close
            Inferno.logger.info "Processed #{line} lines."
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
