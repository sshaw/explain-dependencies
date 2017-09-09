require "csv"

class XDep
  class Output
    def initialize(options = nil)
      @options = options || {}
    end

    protected

    def known_dependencies(name)
      [].freeze
    end

    def ignore?(name)
      @options[:ignore] == true && known_dependencies.include?(name)
    end
  end

  class CSVOutput < Output
    HEADER = %w[Language Name Version Description].freeze

    def process(input, output)
      rows = get_rows(input)
      rows.sort_by! { |r| r[1] }

      mode = output.pos.zero? ? "w" : "a"
      CSV.open(output, mode) do |csv|
        csv << HEADER if output.pos.zero?
        rows.each { |r| csv << r }
      end
    end

    protected

    def get_rows(input)
      raise NotImplementedError
    end
  end
end
