require_relative 'temp_dir'

module Inferno
  module Terminology
    module Tasks
      class CleanupPrecursors
        include TempDir

        attr_reader :version

        def initialize(version:)
          @version = version
        end

        def run
          Inferno.logger.info "removing terminology precursor files in #{versioned_temp_dir}"
          FileUtils.remove_dir(umls_dir, true)
          FileUtils.remove_dir(umls_subset_dir, true)
          FileUtils.rm(umls_zip_path, force: true)
          FileUtils.rm(pipe_files, force: true)
        end
      end
    end
  end
end
