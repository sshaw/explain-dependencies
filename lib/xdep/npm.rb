require "json"
require "xdep/output"

class XDep
  module Npm
    class CSVOutput < XDep::CSVOutput
      KNOWN_DEPENDENCIES = []

      def self.accepts?(filename)
        filename == "package.json"
      end

      protected

      def known_dependencies
        KNOWN_DEPENDENCIES
      end

      def get_rows(input)
        rows = []

        Dir.chdir(File.dirname(input.path)) do
          # This is very slow...
          ls.each do |name, version|
            info = describe("#{name}@#{version["version"]}")
            license = info["licenses"] ? format_licenses(info["licenses"]) : info["license"]
            rows << [ "JavaScript", name, version["version"], info["description"], info["homepage"], license ]
          end
        end

        rows
      end

      private

      def ls
        out = `npm ls --depth=0 --json 2>&1`
        raise Error, "Failed to execute npm: #{out}" unless $?.exitstatus.zero?
        parse_json(out)["dependencies"]
      end

      def describe(pkg)
        # Include license and licenses else we won't get JSON output if one doesn't exist
        out = `npm view #{pkg} description homepage license licenses --json 2>&1`
        raise Error, "Failed to execute npm: #{out}" unless $?.exitstatus.zero?
        parse_json(out)
      end

      def parse_json(out)
        JSON.parse(out)
      rescue JSON::ParserError => e
        raise Error, "Failed to parse npm output: #{e}"
      end

      def format_licenses(licenses)
        licenses.map do |data|
          s = data["type"]
          s << " (#{data["url"]})" if data["url"]
          s
        end.join(", ")
      end
    end
  end
end
