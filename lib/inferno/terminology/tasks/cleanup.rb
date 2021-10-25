module Inferno
  module Terminology
    module Tasks
      class Cleanup
        def run
          Inferno.logger.info "removing all terminology build files in #{TEMP_DIR}"

          FileUtils.remove_dir File.join(TEMP_DIR)
        end
      end
    end
  end
end
