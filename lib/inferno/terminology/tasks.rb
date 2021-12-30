Dir.glob(File.join(__dir__, 'tasks', '*.rb')).each do |path|
  require_relative path.delete_prefix("#{__dir__}/")
end

module Inferno
  module Terminology
    module Tasks
      TEMP_DIR = 'tmp/terminology'.freeze
    end
  end
end
