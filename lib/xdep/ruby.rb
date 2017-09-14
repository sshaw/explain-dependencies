require "xdep/output"

class XDep
  module Ruby
    module Helper
      COMMENT = /\A\s*#/
      GEMFILE = /\A(\s*)gem\s+(["'])(\S+)\2/
      GEMSPEC = %r|\A(\s*)\w+\.add(?:_development)?_dependency[(\s+]?(["'])(\S+)\2|

      # I think 2.4.0 added MissingSpecError
      SPEC_MISSING = defined?(Gem::MissingSpecError) ? Gem::MissingSpecError : Gem::LoadError

      # > 50 million downloads according to rubygems.com, with a few exceptions
      KNOWN_DEPENDENCIES = %w[
        actionmailer actionpack actionview activemodel activerecord
        activesupport addressable arel aws-sdk builder
        bundler coderay coffee-rails coffee-script coffee-script-source
        daemons diff-lcs erubis eventmachine execjs
        faraday ffi hike i18n jquery-rails
        json mail method_source mime-types mini_portile
        minitest multi_json multipart-post mysql2 net-ssh nokogiri
        polyglot pry rack rack-test rails
        railties rake rest-client rspec rspec-core
        rspec-expectations rspec-mocks rspec-support rubygems-bundler sass
        sass-rails sinatra slop sprockets sprockets-rails sqlite3
        thor thread_safe tilt tzinfo
        uglifier
      ].freeze

      private

      def known_dependencies
        KNOWN_DEPENDENCIES
      end

      def output_ruby(input, output, match)
        last_line = nil
        input.each_line do |line|
          if line =~ match
            lead = $1
            name = $3

            if !ignore?(name)
              spec = find_spec(name)
              next unless spec

              comment = "#{lead}# #{spec.summary}"
              # Allow for multiple runs without adding the comment over and over
              # strip to account for changes in indentation
              output.puts(comment) unless last_line.strip == comment.strip
            end
          end

          last_line = line
          output.puts(line)
        end
      end

      def find_spec(name)
        Gem::Specification.find_by_name(name)
      rescue SPEC_MISSING
        raise Error, "Cannot find dependency #{name}; is it installed locally?"
      end
    end

    class CSV < XDep::CSVOutput
      include Helper

      def self.accepts?(filename)
        Bundler::GemfileOutput.accepts?(filename) || RubyGems::GemspecOutput.accepts?(filename)
      end

      protected

      def get_rows(input)
        rows = []

        input.each_line do |line|
          next if line =~ COMMENT || line !~ GEMFILE && line !~ GEMSPEC
          next if ignore?($3)

          spec = find_spec($3)
          if spec.nil?
            row = [$3, nil, "Gem not found"]
          else
            row = [spec.name, spec.version.to_s, spec.summary, spec.homepage, spec.licenses.join(", ")]
          end

          row.unshift "Ruby"
          rows << row
        end

        rows
      end
    end
  end

  module RubyGems
    CSVOutput = Ruby::CSV

    class GemspecOutput < Output
      include Ruby::Helper

      def self.accepts?(filename)
        (filename =~ /\w\.gemspec\z/) != nil
      end

      def process(input, output)
        output_ruby(input, output, GEMSPEC)
      end
    end
  end

  module Bundler
    CSVOutput = Ruby::CSV

    class GemfileOutput < Output
      include Ruby::Helper

      def self.accepts?(filename)
        filename == "Gemfile"
      end

      def process(input, output)
        output_ruby(input, output, GEMFILE)
      end
    end
  end
end
