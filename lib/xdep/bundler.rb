require "rubygems"
require "xdep/output"

class XDep
  module Bundler
    module Common
      # I think 2.4.0 added MissingSpecError
      SPEC_MISSING = defined?(Gem::MissingSpecError) ? Gem::MissingSpecError : Gem::LoadError

      # > 50 million downloads according to rubygems.com
      KNOWN_DEPENDENCIES = %w[
        actionmailer actionpack actionview activemodel activerecord
        activesupport addressable arel aws-sdk builder
        bundler coderay coffee-rails coffee-script coffee-script-source
        daemons diff-lcs erubis eventmachine execjs
        faraday ffi hike i18n jquery-rails
        json mail method_source mime-types mini_portile
        minitest multi_json multipart-post net-ssh nokogiri
        polyglot pry rack rack-test rails
        railties rake rest-client rspec rspec-core
        rspec-expectations rspec-mocks rspec-support rubygems-bundler sass
        sass-rails sinatra slop sprockets sprockets-rails
        thor thread_safe tilt tzinfo
        uglifier
      ].freeze

      protected

      def known_dependencies
        KNOWN_DEPENDENCIES
      end

      private

      def find_spec(name)
        Gem::Specification.find_by_name(name)
      rescue SPEC_MISSING => e
        warn "WARNING: #{e}: #{name}"
        nil
      end
    end

    class GemfileOutput < XDep::Output
      include Common

      GEM = /\A(\s*)gem\s+(["'])(\S+)\2/

      def process(input, output)
        last_line = nil
        input.each_line do |line|
          if line =~ GEM
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
    end

    class CSVOutput < XDep::CSVOutput
      include Common

      GEM = /\bgem\s+(["'])(\S+)\1/
      COMMENT = /\A\s*#/

      protected

      def get_rows(input)
        rows = []

        input.each_line do |line|
          next if line =~ COMMENT || line !~ GEM || ignore?($2)

          spec = find_spec($2)
          if spec.nil?
            row = [$2, nil, "Gem not found"]
          else
            row = [spec.name, spec.version.to_s, spec.summary]
          end

          row.unshift "Ruby"
          rows << row
        end

        rows
      end
    end
  end
end
