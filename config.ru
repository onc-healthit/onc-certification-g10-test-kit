require 'inferno'

inferno_spec = Bundler.locked_gems.specs.find { |spec| spec.name == 'inferno_core' }

inferno_path =
  if inferno_spec.respond_to? :stub
    File.join(inferno_spec.stub.full_gem_path, 'lib', 'inferno')
  elsif inferno_spec.source.is_a? Bundler::Source::Path
    File.join(inferno_spec.source.path.to_s, 'lib', 'inferno')
  else
    raise 'Unable to locate inferno static assets'
  end

use Rack::Static, urls: ['/public'], root: inferno_path

Inferno::Application.finalize!

use Inferno::Utils::Middleware::RequestLogger

run Inferno::Web.app
