# G10CertificationTestKit (Preview Version)

This is a preview version of an
[Inferno](https://github.com/inferno-framework/inferno-core) test kit for
services seeking to meet the requirements of the Standardized API for Patient
and Population Services criterion § 170.315(g)(10) in the 2015 Edition Cures
Update.

## Instructions

- Clone this repo.
- run `setup.sh`
- run `run.sh`
- navigate to `http://localhost`

### Terminology Support
#### Terminology prerequisites

In order to validate terminologies, Inferno must be loaded with files generated
from the Unified Medical Language System (UMLS).  The UMLS is distributed by the
National Library of Medicine (NLM) and requires an account to access.

Inferno provides some rake tasks which may make this process easier, as well as
a Dockerfile and docker-compose file that will create the validators in a
self-contained environment.

Prerequisites:

* A UMLS account
* A working Docker toolchain, which has been assigned at least 10GB of RAM (The
  Metathesaurus step requires 8GB of RAM for the Java process)
  * Note: the Docker terminology process will not run unless Docker has access
    to at least 10GB of RAM.
* At least 90 GB of free disk space on the Host OS, for
  downloading/unzipping/processing the terminology files.
  * Note: this space needs to be allocated on the host because Docker maps these
    files through to the Host, to allow for building in the dedicated
    terminology container.
  * Note: see the `.env` file section below for a way to reduce this space
    requirement to around 40 GB.
* A copy of the Inferno repository, which contains the required Docker and Ruby
  files

You can prebuild the terminology docker container by running the following
command:

```shell
docker-compose -f terminology_compose.yml build
```

Once the container is built, you will have to add your UMLS API key to a file
named `.env` at the root of the inferno project. This API key is used to
authenticate the user to download the UMLS zip files. To find your UMLS API key,
sign into [the UTS homepage](https://uts.nlm.nih.gov/uts/), click on `My
Profile` in the top right, and copy the `API KEY` value from the `UMLS Licensee
Profile`.

The relevant entries in the `.env` file should look like this (replacing
`your_api_key` with your UMLS API key):

```shell
UMLS_API_KEY=your_api_key
CLEANUP=true
```

Note that _anything_ after the equals sign in `.env` will be considered part of
the variable, so don't wrap your API key in quotation marks.

Optionally: you can add a second environment variable, named `CLEANUP` and set
to `true`, to that same file. This tells the build system to delete the "build
files"--everything except for the finished databases--between each version
build. This caps the space requirement at ~40 GB, rather than 90 GB.

Once that file exists, you can run the terminology creation task by using the
following command:

```shell
docker-compose -f terminology_compose.yml up
```

This will run the terminology creation steps in order. These tasks may take
several hours. If the creation task is cancelled in progress and restarted, it
will restart after the last _completed_ step. Intermediate files are saved to
`tmp/terminology` in the Inferno repository that the Docker Compose job is run
from, and the validators are saved to `resources/terminology/validators/bloom`,
where Inferno can use them for validation.

#### Cleanup

Once the terminology building is done, you should remove your UMLS API key from
the system.

Optionally, the files and folders in `tmp/terminology/` can be deleted after
terminology building to free up space, as they are several GB in size. If you
intend to re-run the terminology builder, these files can be left to speed up
building in the future, since the builder will be able to skip the initial
download/preprocessing steps.

#### Verifying a Successful Terminology Build

The following rake task will check that the built terminology contains the
expected number of codes for each system:

```shell
bundle exec rake terminology:check_built_terminology
```

#### Spot Checking the Terminology Files

You can use the following `rake` command to spot check the validators to make
sure they are installed correctly:

```shell
bundle exec rake "terminology:check_code[91935009,http://snomed.info/sct, http://hl7.org/fhir/us/core/ValueSet/us-core-allergy-substance]"
```

Should return:

```
X http://snomed.info/sct|91935009  is not in http://hl7.org/fhir/us/core/ValueSet/us-core-allergy-substance
```

And

```shell
bundle exec rake "terminology:check_code[91935009,http://snomed.info/sct]"
```

Should return:

```
✓ http://snomed.info/sct|91935009  is in http://snomed.info/sct
```

#### Restricting access to CodeSystems based on licensing terms

Running instances of Inferno can be configured to exclude terminology validation
for codes based on applicable categories of additional restrictions, as defined
by the [UMLS license
agreement](https://www.nlm.nih.gov/research/umls/knowledge_sources/metathesaurus/release/license_agreement.html).

By default, Inferno will not restrict validation of codes. To configure an
instance of Inferno to exclude certain CodeSystems for validation, rename the
`resources/terminology/terminology_config.yml.example` to
`terminology_config.yml`, and update the file based on the example content.
Inferno will provide an informational message on the landing page that describes
which CodeSystems will not be validated in this running instance based on this
configuration file.  If Inferno tests receive a code from an excluded
CodeSystem, a warning indicating that Inferno cannot validate the code will be
provided along with the test result.

#### Manual build instructions

**TODO:** Update this section

If this Docker-based method does not work based on your architecture, manual
setup and creation of the terminology validators is documented [on this wiki
page](https://github.com/onc-healthit/inferno/wiki/Installing-Terminology-Validators#building-the-validators-without-docker)

#### UMLS Data Sources

Some material in the UMLS Metathesaurus is from copyrighted sources of the
respective copyright holders. Users of the UMLS Metathesaurus are solely
responsible for compliance with any copyright, patent or trademark restrictions
and are referred to the copyright, patent or trademark notices appearing in the
original sources, all of which are hereby incorporated by reference.

      Bodenreider O. The Unified Medical Language System (UMLS): integrating biomedical terminology.
      Nucleic Acids Res. 2004 Jan 1;32(Database issue):D267-70. doi: 10.1093/nar/gkh061.
      PubMed PMID: 14681409; PubMed Central PMCID: PMC308795.
