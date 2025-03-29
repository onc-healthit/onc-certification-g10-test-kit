While code in this test kit is intended to be as simple and as
easy-to-understand as possible, sometimes unanticipated testing requirements are
introduced that require special handling. The ability for Inferno to
accommodate these requirements is a key feature of the Inferno framework.
However, this does add complexity to maintenance of the tests.

The following is a list of unusual or unorthodox methods used in the (g)(10)
Test Kit that maintainers should be aware of. These are also opportunities
for improvement of the Inferno Framework if this type of functionality would be
of broad use beyond US Core.

The following links are to a specific snapshot in time of the repository; this
list should be maintained as the repository evolves.

* Locking short ids: 
   * [/lib/onc_certification_g10_test_kit.rb#L438](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit.rb#L438)
* Add some magic around option definitions:
   * [/lib/onc_certification_g10_test_kit/g10_options.rb](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/g10_options.rb)
* Combining/deduplicating outputs:
   * [/lib/onc_certification_g10_test_kit/incorrectly_permitted_tls_versions_messages_setup_test.rb](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/incorrectly_permitted_tls_versions_messages_setup_test.rb)
* Reliance on groups containing mixed groups/tests only displaying the groups in the ui:
    * [/lib/onc_certification_g10_test_kit/multi_patient_api_stu1.rb#L73-L86](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/multi_patient_api_stu1.rb#L73-L86)
    * [/lib/onc_certification_g10_test_kit/single_patient_api_group.rb#L88-L112](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/single_patient_api_group.rb#L88-L112)
    * [/lib/onc_certification_g10_test_kit/single_patient_api_group.rb#L154](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/single_patient_api_group.rb#L154)
    * [/lib/onc_certification_g10_test_kit/smart_ehr_practitioner_app_group.rb#L474-L506](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/smart_ehr_practitioner_app_group.rb#L474-L506)
    * [/lib/onc_certification_g10_test_kit/smart_standalone_patient_app_group.rb#L381-L413](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/smart_standalone_patient_app_group.rb#L381-L413)
    * [/lib/onc_certification_g10_test_kit/smart_v1_scopes_group.rb#L221-L239](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/smart_v1_scopes_group.rb#L221-L239)
* These complicated test imports (one for each us core version):
    * [/lib/onc_certification_g10_test_kit/single_patient_api_group.rb#L114-L130](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/single_patient_api_group.rb#L114-L130)
* Deleting inputs
    * [/lib/onc_certification_g10_test_kit/smart_ehr_patient_launch_group_stu2.rb#L124-L126](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/smart_ehr_patient_launch_group_stu2.rb#L124-L126)
* Configuring nested tests/groups
    * [/lib/onc_certification_g10_test_kit/smart_ehr_practitioner_app_group.rb#L256-L270](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/smart_ehr_practitioner_app_group.rb#L256-L270)
    * [/lib/onc_certification_g10_test_kit/smart_standalone_patient_app_group.rb#L309-L323](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/smart_standalone_patient_app_group.rb#L309-L323)
    * [/lib/onc_certification_g10_test_kit/smart_v1_scopes_group.rb#L195-L209](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/smart_v1_scopes_group.rb#L195-L209)
    * [/lib/onc_certification_g10_test_kit/token_introspection_group.rb#L83-L108](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/token_introspection_group.rb#L83-L108)
* Replacing groups 
    * [/lib/onc_certification_g10_test_kit/smart_fine_grained_scopes_group.rb#L97-L107](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/smart_fine_grained_scopes_group.rb#L97-L107)
* Reordering groups 
    * [/lib/onc_certification_g10_test_kit/smart_fine_grained_scopes_group.rb#L109-L120](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/smart_fine_grained_scopes_group.rb#L109-L120)
* Removing tests 
    * [/lib/onc_certification_g10_test_kit/smart_fine_grained_scopes_group.rb#L122-L124](https://github.com/onc-healthit/onc-certification-g10-test-kit/blob/fe9ab4a628e3990ee03ce5998f3b7d90692ef0c5/lib/onc_certification_g10_test_kit/smart_fine_grained_scopes_group.rb#L122-L124)
