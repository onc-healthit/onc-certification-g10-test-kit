module Inferno
  module Terminology
    module Tasks
      class DownloadFHIRTerminology
        def run
          FileUtils.mkdir_p PACKAGE_DIR

          download_fhir_r4
          download_fhir_expansions
          download_us_core
        end

        def download_fhir_r4
          FHIRPackageManager.get_package('hl7.fhir.r4.core#4.0.1', PACKAGE_DIR, ['ValueSet', 'CodeSystem'])
        end

        def download_us_core
          FHIRPackageManager.get_package('hl7.fhir.us.core#3.1.1', PACKAGE_DIR, ['ValueSet', 'CodeSystem'])
        end

        def download_fhir_expansions
          FHIRPackageManager.get_package('hl7.fhir.r4.expansions#4.0.1', PACKAGE_DIR, ['ValueSet', 'CodeSystem'])
        end
      end
    end
  end
end
