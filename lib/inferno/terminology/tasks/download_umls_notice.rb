module Inferno
  module Terminology
    module Tasks
      module DownloadUMLSNotice
        def download_umls_notice
          Inferno.logger.info <<~NOTICE
            UMLS file not found. Download the US National Library of Medicine (NLM) Unified
            Medical Language System (UMLS) Full Release files:
            https://www.nlm.nih.gov/research/umls/licensedcontent/umlsknowledgesources.html

            Install the metathesaurus with the following data sources:
            CVX|CVX;ICD10CM|ICD10CM;ICD10PCS|ICD10PCS;ICD9CM|ICD9CM;LNC|LNC;MTHICD9|ICD9CM;RXNORM|RXNORM;SNOMEDCT_US|SNOMEDCT;CPT;HCPCS
            After installation, copy `{install path}/META/MRCONSO.RRF` into your
            `./tmp/terminology` folder, and rerun this task.
          NOTICE
        end
      end
    end
  end
end
