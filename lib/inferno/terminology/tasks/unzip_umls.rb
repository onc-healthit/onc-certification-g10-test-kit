require 'zip'
require_relative 'temp_dir'

module Inferno
  module Terminology
    module Tasks
      class UnzipUMLS
        include TempDir

        attr_reader :version

        def initialize(version:)
          @version = version
        end

        def run
          # https://stackoverflow.com/questions/19754883/how-to-unzip-a-zip-file-containing-folders-and-files-in-rails-while-keeping-the
          Zip::File.open(umls_zip_path) do |zip_file|
            # Handle entries one by one
            zip_file.each do |entry|
              # Extract to file/directory/symlink
              Inferno.logger.info "Extracting #{entry.name}"
              f_path = File.join(umls_dir, entry.name)
              FileUtils.mkdir_p(File.dirname(f_path))
              zip_file.extract(entry, f_path) unless File.exist?(f_path)
            end
          end

          wildcard_path = "#{umls_dir}/20*"
          Zip::File.open(File.expand_path("#{Dir[wildcard_path][0]}/mmsys.zip")) do |zip_file|
            zip_file.each do |entry|
              Inferno.logger.info "Extracting #{entry.name}"
              f_path = File.join((Dir[wildcard_path][0]).to_s, entry.name)
              FileUtils.mkdir_p(File.dirname(f_path))
              zip_file.extract(entry, f_path) unless File.exist?(f_path)
            end
          end
        end
      end
    end
  end
end
