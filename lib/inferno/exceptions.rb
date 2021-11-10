module Inferno
  class UnknownValueSetException < StandardError
    def initialize(value_set)
      super("Unknown ValueSet: #{value_set}")
    end
  end

  class FilterOperationException < StandardError
    def initialize(filter_op)
      super("Cannot Handle Filter Operation: #{filter_op}")
    end
  end

  class UnknownCodeSystemException < StandardError
    def initialize(code_system)
      super("Unknown Code System: #{code_system}")
    end
  end

  class FileExistsException < StandardError
    def initialize(value_set)
      super(value_set.to_s)
    end
  end

  class ProhibitedSystemException < StandardError
    def initialize(url)
      super("Inferno is unable to validate codes from #{url} due to license restrictions")
    end
  end
end
