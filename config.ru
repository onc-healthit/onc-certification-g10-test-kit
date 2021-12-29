require 'inferno'

inferno_spec = Bundler.locked_gems.specs.find { |spec| spec.name == 'inferno_core' }

base_path =
  if inferno_spec.respond_to? :stub
    inferno_spec.stub.full_gem_path
  elsif inferno_spec.source.is_a? Bundler::Source::Path
    inferno_spec.source.path.to_s
  elsif inferno_spec.source.specs.local_search('inferno_core').present?
    inferno_spec.source.specs.local_search('inferno_core').first.full_gem_path
  else
    raise 'Unable to locate inferno static assets'
  end

inferno_path = File.join(base_path, 'lib', 'inferno')

use Rack::Static, urls: ['/public'], root: inferno_path

Inferno::Application.finalize!

use Inferno::Utils::Middleware::RequestLogger

run Inferno::Web.app
