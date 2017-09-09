require "fileutils"
require "tempfile"

require "xdep/bundler"
require "xdep/npm"
require "xdep/version"

class XDep
  Error = Class.new(StandardError)

  REPORT_BASENAME = "dependencies".freeze
  REPORT_EXTENSION = ".explained".freeze

  FORMAT_HANDLERS = {
    :csv => {
      # TODO: put these in XDep::XXXX
      "Gemfile" => XDep::Bundler::CSVOutput,
      "gems.rb" => XDep::Bundler::CSVOutput,
      "package.json" => XDep::Npm::CSVOutput
    },
    :source => {
      "Gemfile" => XDep::Bundler::GemfileOutput,
      "gems.rb" => XDep::Bundler::GemfileOutput
    },
  }

  VALID_SOURCES = FORMAT_HANDLERS.values.map(&:keys).flatten.uniq

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

  def create_handler(filename)
    klass = FORMAT_HANDLERS[@format][filename]
    raise Error, "#{filename} does not support format #@format" unless klass
    klass.new(@options)
  end

  def output_as_original(sources)
    handlers = {}

    sources.each do |source|
      basename = File.basename(source)
      handlers[basename] ||= create_handler(basename)

      File.open(source) do |input|
        output = Tempfile.new(REPORT_BASENAME)
        begin
          handlers[basename].process(input, output)
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
    handlers = sources.each_with_object({}) do |source, h|
      basename = File.basename(source)
      h[basename] ||= create_handler(basename)
    end

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
      elsif !VALID_SOURCES.include?(File.basename(source))
        raise ArgumentError, "Don't know how to process: #{source}"
      else
        source
      end
    end
  end

  def find_sources(root)
    VALID_SOURCES.map { |name| File.join(root, name) }.select { |path| File.file?(path) }
  end
end
