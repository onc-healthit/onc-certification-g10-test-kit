# 2.1.0

* Update patient ID inputs from a single list of patient IDs to the patient ID
  from a SMART launch plus a list of additional patient IDs.
* Add missing `Accept` header to test `5.2.05`.
* Fix a bug which caused the terminology build to run in `development` rather
  than `production` mode, causing it to be unable to see the database created by
  `setup.sh`.
* Add terminologies based on `BCP 47` (used to represent human languages) to the
  set of terminologies with relaxed checks on the total number of codes.
* Fix a bug with the terminology build caused by not having a `tmp` folder.
* Update Bulk Data file download tests to follow redirects. Inferno will not
  include an `Authorization` header when following a redirect for a bulk data
  file download.
* Fix a bug where some terminology messages from the FHIR validator were not
  being excluded.
* Update the title and description of Visual Inspection and Attestation test
  `6.6.05`.
* Update the input forms to display inputs in a more reasonable order and fix
  incorrect input titles.
* Relax the requirements for advertising support for the `Group/[id]/$export`
  Operation in a server's CapabilityStatement. This test will now pass if any
  Group Operations are listed, and warnings will be displayed if no Operation is
  declared at `Group/[id]/$export` or if the Operation has a url other than the
  url of the Operation defined in the Bulk Data IG. An additional warning will
  be displayed if the server does not declare that it instantiates the Bulk Data
  IG.
* Update US Core Test Kit from `v0.1.1` to `v0.2.1`:
  * Reference resolution tests now only check Must Support references
  * Reference resolution tests now requests and display them in the UI
  * Reference resolution tests removed for profiles with no Must Support
    references
  * Fix a string interpolation bug in reference search checks.
  * Fix a bug in the error message for mismatched ids in read tests.
* Update SMART App Launch Test Kit from `v0.1.1` to `v0.1.2`:
  * Update scope validation for taken refresh to accept a subset of the
    originally granted scopes.
  * Lengthen PKCE code verifier to match spec.
* Update Inferno Core from `v0.2.0` to `v0.3.0`
  * Various minor UI improvements
  * Improve how inputs are handled in the backend so that the UI can display
    inputs exactly as received from the JSON api rather than needing to
    determine that itself.
  * Add the ability to specify the order in which inputs appear in the UI.
  * Add the ability to copy/paste JSON/YAML versions of inputs in the UI.
  * Update the preset input selection UI.
  * Add an inputs/outputs to test and report displays in the UI.
  * Add the ability to display a custom banner at the top of the page.
  * Update the UI for suite configuration messages. Info and warning messages
    will now be displayed in addition to error messages.
  * Update the UI to not omit required indicators from locked inputs.
  * Fix a bug where sometimes in an input would appear twice in the UI.
  * Fix a bug where the *New Session* button was using the wrong url.
  * Fix a bug where primitive extensions were stripped from resources before
    they were validated.
  * Fix a bug where a test run could be created without all of the required
    inputs.

# 2.1.0.rc1

Initial 2.1.0 release candidate

# 2.0.0

Initial public release

# 2.0.0.rc3

* Fix links in invalid aud & invalid launch groups.

# 2.0.0.rc2

* Fix terminology build.
* Add invalid launch group.
* Omit bulk data tests for Medication and Location if no resources are
  available.
* Update SMART App Launch and Bulk Data IG links.

# 2.0.0.rc1

Initial release candidate
