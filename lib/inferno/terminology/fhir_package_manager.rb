require 'rubygems/package'
require 'tempfile'
require 'zlib'
require 'json'

require_relative '../exceptions'

module Inferno
  module Terminology
    module FHIRPackageManager
      class << self
        REGISTRY_SERVER_URL = 'https://packages.fhir.org'.freeze
        # Get the FHIR Package from the registry.
        #
        # e.g. get_package('hl7.fhir.us.core#3.1.1')
        #
        # @param [String] package The FHIR Package
        def get_package(package, destination, desired_types = [])
          package_url = package
            .split('#')
            .prepend(REGISTRY_SERVER_URL)
            .join('/')

          tar_file_name = "tmp/#{package.split('#').join('-')}.tgz"

          File.open(tar_file_name, 'w') do |output_file|
            output_file.binmode
            block = proc do |response|
              response.read_body do |chunk|
                output_file.write chunk
              end
            end
            RestClient::Request.execute(method: :get, url: package_url, block_response: block)
          end

          tar = Gem::Package::TarReader.new(Zlib::GzipReader.open("tmp/#{package.split('#').join('-')}.tgz"))

          path = File.join destination.split('/')
          FileUtils.mkdir_p(path)

          tar.each do |entry|
            next if entry.directory?

            next unless entry.full_name.start_with? 'package/'

            file_name = entry.full_name.split('/').last
            next if desired_types.present? && !file_name.start_with?(*desired_types)

            resource = JSON.parse(entry.read) if file_name.end_with? '.json'
            next unless resource&.[]('url')

            encoded_name = "#{encode_name(resource['url'])}.json"
            encoded_file_name = File.join(path, encoded_name)
            if File.exist?(encoded_file_name) && !resource['url'] == JSON.parse(File.read(encoded_file_name))['url']
              raise FileExistsException, "#{encoded_name} already exists for #{resource['url']}"
            end

            File.write(encoded_file_name, resource.to_json)
          end
          File.delete(tar_file_name)
        end

        def encode_name(name)
          Zlib.crc32(name)
        end
      end
    end
  end
end
