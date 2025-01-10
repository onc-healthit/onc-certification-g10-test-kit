The (g)(10) Test Kit provides its own terminology validation instead of relying
on the HL7 FHIR Validator's integration with an externally hosted terminology
service.  The test kit does this by instructing the HL7 FHIR Validator to not perform
terminology validation during FHIR Resource Validation, and then separately
the tests validate terminology via the `validate_code` method
provided in this test kit.  This method validates the codes against
locally-installed terminology packages (described below).

The (g)(10) Test Kit performs its own terminology validation to avoid creating
a runtime dependency on an externally-hosted service.  Since the (g)(10) Test
Kit was first created, the HL7 FHIR Validator and associated terminology service has
been improved substantially in functionality and stability.  One area for
possible improvement of this test kit is to reevaluate its approach to
terminology validation to better leverage the HL7 Validator to reduce the amount
of code that needs to be maintained.

## Terminology Installation

Developers should install terminology files into their test kit directory as
described in the instructions in the [README of this
repository](https://github.com/onc-healthit/onc-certification-g10-test-kit?tab=readme-ov-file#terminology-support).
The terminology files are not distributed within this repository to avoid
violating licensing associated with these 3rd party terminology content.
However, groups of developers within an organization may choose to save a single
copy of the terminology files to share internally (if licensing agreements are
not violated) to avoid the effort involved in downloading and preparing the
terminology files themselves.  All terminology files are stored in the `resources/terminology/`
directory.

Please note that you need at least 10GB of memory to download and install the
terminology files.  For Docker users, you can update Docker Desktop memory by
opening Docker Desktop and going to Settings -> Resources and increasing the
memory.

## Updating Terminology

As described in the README, the terminology files are downloaded from UMLS,
processed into small files, and saved in each local installation of the
test kit in the `resources/terminology/` directory.  The test developers are
responsible for maintaining the scripts that install these files.  These
scripts are typically required to be updated with each SVAP update to accommodate
any new CodeSystems or ValueSets referenced in new versions of US Core.  Additionally,
the version of UMLS should be updated approximately yearly to incorporate any
new valid codes that may have been introduced.  These two updates are typically done together,
and the following instructions assume this is the case. During this process,
metadata about the CodeSystems and ValueSets (e.g. number of codes in each) is
also updated and stored within the test kit.  This enables the (g)(10) Test Kit
to provide a warning to users if they need to rerun the terminology update
process.

Developers can also inspect previous commits to this repository
to see what changes were made to update to a new yearly release.  For example: [FI-3100: Update (g)(10) Certfication Test Kit Terminology Package to 2024 Version](https://github.com/onc-healthit/onc-certification-g10-test-kit/pull/570).

One possible area of improvement is to refactor this code to reduce the number of
places that need to be updated during this process.  It has not been prioritized
due to how infrequently this is done.

Note that this code is capable of processing multiple years of UMLS data, which would
allow any terminology codes that were allowable in previous years but are no longer allowed
due to deprecation to be included in the test kit.  Due to the long processing times
and minor real-world impact this feature has to allowable codes, the test kit
has been configured to only process the most recent year of UMLS data since
v3.2.0 ([release
notes](https://github.com/onc-healthit/onc-certification-g10-test-kit/releases/tag/v3.2.0)).

Steps to update required terminology in the test kit to include new version of UMLS and to accommodate new versions of US Core:
1.	Update `default_version` in [Rakefile](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/main/Rakefile) with new year (e.g. from 2024 to 2025).
2.	Update `version` on line 7 in [bin/create_umls.sh](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/main/bin/create_umls.sh) to new year.
3.	Update `version` on line 8 in [bin/prepare_terminology.sh](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/main/bin/prepare_terminology.sh) to new year.
4.	In [lib/inferno/terminology/tasks/expand_value_set_to_file.rb](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/main/lib/inferno/terminology/tasks/expand_value_set_to_file.rb) update the each loop to the new year.
5.	Create .prop file in [resources](https://github.com/onc-healthit/onc-certification-g10-test-kit/tree/main/resources) folder by copying previous year and updating release_version on line 8 ([example](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/main/resources/inferno_2024.prop))
6.	In [lib/inferno/terminology/tasks/run_umls_jar.rb](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/main/lib/inferno/terminology/tasks/run_umls_jar.rb) add new year .prop file to list
7.	In [bin/run_terminology](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/main/bin/run_terminology.sh):
    1.	Update running prepare terminology script on line 14 to new year
    2.	Update cleanup task on line 21 to new year - bundle exec rake terminology:cleanup_precursors[“<YEAR>”]
8.	In [lib/inferno/terminology/tasks/download_umls.rb](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/main/lib/inferno/terminology/tasks/download_umls.rb), add new year UMLS download link to list: `https://download.nlm.nih.gov/umls/kss/<YEAR>AA/umls-<YEAR>AA-full.zip`
9.	Update which FHIR terminology we are using in [lib/inferno/terminology/tasks/download_fhir_terminology.rb](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/main/lib/inferno/terminology/tasks/download_fhir_terminology.rb):
    1.	Add new us core package version FHIRPackageManager.get_package('hl7.fhir.us.core#<‘VERSION>, PACKAGE_DIR, ['ValueSet', 'CodeSystem’])
  (Can find most recent version information here: https://registry.fhir.org/package/hl7.fhir.us.core%7C4.0.0)
    2.	Update vsac version FHIRPackageManager.get_package('us.nlm.vsac#<VERSION>, File.join(PACKAGE_DIR, 'vsac'), ['ValueSet', 'CodeSystem']) 
10.	Update [lib/inferno/terminology/expected_manifest.yml](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/main/lib/inferno/terminology/expected_manifest.yml) to contain new number of values in each value set so that bundle exec rake terminology:check_built_terminology  runs without failure
11.	[resources/value_sets.yml](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/main/resources/value_sets.yml) needs to be updated to include the VS bindings from the new US Core version. This involves adding all of the bindings from the US Core version’s metadata in the US Core Test Kit, and then removing any duplicates.  For example, in v7.0.0, a binding for Observation.status was added in the Treatment Intervention preferences, so [this binding](https://github.com/inferno-framework/us-core-test-kit/blob/b480ccf3e296b190dce5511d595de5e1a07e9c1a/lib/us_core_test_kit/generated/v7.0.0/treatment_intervention_preference/metadata.yml#L202-L205) needed to be copied to the value_sets.yml file.  Note that this requires a detailed understanding of what has changed between US Core versions.

After updating the terminology in the developer's local installation of the test
kit, the developer should run the tests against the Inferno Reference Server
loaded with data to ensure that 100% of the tests pass.  Additionally, the
developer can use commands as described in the README to spot check that
expected codes appear in the value sets.

##Notes from recent updates

* v7.0.0: Ran into some issues with where US Core v7 was not in simplifier
  registry, since US Core 7  builds on VSAC 0.18.0 and that package is huge, so
  has been refused by the package registry infrastructure for now. The code that
  exists to grab the US Core and VSAC packages did not work therefore, and I had
  to add special cases for those packages to grab them from specific urls in
  fhir_package_manager.rb