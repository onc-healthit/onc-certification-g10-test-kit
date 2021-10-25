# Inferno Template

This is a template repository for an
[Inferno](https://github.com/inferno-community/inferno-core) test kit.

## Instructions

- Clone this repo.
- Write your tests in the `lib` folder.
- Put the `package.tgz` for the IG you're writing tests for in
  `lib/your_test_kit_name/igs` and update this path in `docker-compose.yml`.
  This will ensure that the validator has access to the resources needed to
  validate resources against your IG.
- Run `setup.sh` in this repo to pull the needed docker images and set up the
  database.
- Run `run.sh` to build your tests and run inferno.
- Navigate to `http://localhost` to access Inferno, where your test suite will
  be available. To access the FHIR resource validator, navigate to
  `http://localhost/validator`.

## Distributing tests

In order to make your test suite available to others, it needs to be organized
like a standard ruby gem (ruby libraries are called gems).

- Fill in the information in the `gemspec` file in the root of this repository.
  The name of this file should match the `spec.name` within the file. This will
  be the name of the gem you create. For example, if your file is
  `my_test_kit.gemspec` and its `spec.name` is `'my_test_kit'`, then others will
  be able to install your gem with `gem install my_test_kit`. There are
  [recommended naming conventions for
  gems](https://guides.rubygems.org/name-your-gem/).
- Your tests must be in `lib`
- `lib` should contain only one file. All other files should be in a
  subdirectory. The file in lib be what people use to import your gem after they
  have installed it. For example, if your test kit contains a file
  `lib/my_test_suite.rb`, then after installing your test kit gem, I could
  include your test suite with `require 'my_test_suite'`.
- **Optional:** Once your gemspec file has been updated, you can publish your
  gem on [rubygems, the official ruby gem repository](https://rubygems.org/). If
  you don't publish your gem on rubygems, users will still be able to install it
  if it is located in a public git repository. To publish your gem on rubygems,
  you will first need to [make an account on
  rubygems](https://guides.rubygems.org/publishing/#publishing-to-rubygemsorg)
  and then run `gem build *.gemspec` and `gem push *.gem`.

## Example Inferno test kits

- https://github.com/inferno-community/ips-test-kit
- https://github.com/inferno-community/shc-vaccination-test-kit
