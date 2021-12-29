class Bloomer
  class Scalable
    # Scalable bloom filters report very inaccurate sizes because they contain
    # multiple filters and don't check them all before adding something. This
    # makes them check all of the filters before adding an element so that the
    # size is more accurate.
    def add_without_duplication(string)
      return false if include? string

      add string
    end

    def self.create_with_sufficient_size(length = 256)
      size = initial_size(length)
      new(size, 0.00001)
    end

    def self.initial_size(length)
      size = 2**Math.log2(length).ceil

      size < 256 ? 256 : size
    end
  end
end
