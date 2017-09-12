require "fileutils"
require "tempfile"

require "xdep/npm"
require "xdep/ruby"
require "xdep/version"

class XDep
  Error = Class.new(StandardError)

  REPORT_BASENAME = "dependencies".freeze
  REPORT_EXTENSION = ".explained".freeze

  FORMAT_HANDLERS = {
    :csv    => [ Bundler::CSVOutput, RubyGems::CSVOutput, Npm::CSVOutput ],
    :source => [ Bundler::GemfileOutput, RubyGems::GemspecOutput ]
  }

  def initialize(options = nil)
    @options = options || {}
    @format = @options[:format] || :csv
    raise ArgumentError, "Unknown output format: #{@format}" unless FORMAT_HANDLERS.include?(@format)
  end

  def process(sources)
    sources = normalize_sources(sources)
    raise ArgumentError, "No dependency files found" if sources.empty?

    if @format == :csv
      output_as_csv(sources)
    else
      output_as_original(sources)
    end
  end

  private

  def output_as_original(sources)
    handlers = create_handlers(sources)

    sources.each do |source|
      File.open(source) do |input|
        output = Tempfile.new(REPORT_BASENAME)
        begin
          handlers[File.basename(source)].process(input, output)
          output.close # On Win files must be closed before moving.
          dest = source
          dest += REPORT_EXTENSION unless @options[:add]
          FileUtils.mv(output.path, dest)
        ensure
          output.close unless output.closed?
        end
      end
    end
  end

  def output_as_csv(sources)
    handlers = create_handlers(sources)
    report = File.open("#{REPORT_BASENAME}.csv", "w")

    begin
      sources.each do |source|
        # Each handler must append
        report.seek(0, :END)
        File.open(source) do |input|
          handlers[File.basename(source)].process(input, report)
        end
      end
    ensure
      report.close
    end
  end

  def normalize_sources(sources)
     sources.flat_map do |source|
      if File.directory?(source)
        find_sources(source)
      elsif !File.file?(source)
        raise ArgumentError, "No such file: #{source}"
      elsif find_handler(File.basename(source)).nil?
        raise ArgumentError, "Don't know how to process: #{source}"
      else
        source
      end
    end
  end

  def create_handlers(sources)
    sources.each_with_object({}) do |source, h|
      basename = File.basename(source)
      unless h.include?(basename)
        klass = find_handler(basename)
        raise Error, "#{basename} does not support format #@format" unless klass

        h[basename] = klass.new(@options)
      end
    end
  end

  def find_handler(filename)
    FORMAT_HANDLERS[@format].find { |handler| handler.accepts?(filename) }
  end

  def find_sources(root)
    Dir[ File.join(root, "*") ].reject { |path| find_handler(File.basename(path)).nil? }
  end
end
