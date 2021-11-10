module Inferno
  module Terminology
    module Tasks
      module TempDir
        def versioned_temp_dir
          File.join(TEMP_DIR, version)
        end

        def umls_zip_path
          File.join(versioned_temp_dir, 'umls.zip')
        end

        def umls_dir
          File.join(versioned_temp_dir, 'umls')
        end

        def umls_subset_dir
          File.join(versioned_temp_dir, 'umls_subset')
        end

        def pipe_files
          Dir.glob(File.join(versioned_temp_dir, '*.pipe'))
        end
      end
    end
  end
end
