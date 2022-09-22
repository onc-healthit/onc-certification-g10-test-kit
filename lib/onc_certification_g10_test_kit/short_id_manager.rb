module ONCCertificationG10TestKit
  module ShortIDManager
    class << self
      def current_short_id_map
        @current_short_id_map ||=
          all_children(G10CertificationSuite).each_with_object({}) do |runnable, mapping|
            mapping[runnable.id] = runnable.short_id
          end
      end

      def all_children(runnable)
        runnable
          .children
          .flat_map { |child| [child] + all_children(child) }
      end

      def save_current_short_id_map
        File.write(File.join(__dir__, 'short_id_map.yml'), current_short_id_map.to_yaml)
      end
    end
  end
end
