require "json"
require "xdep/output"

class XDep
  module Npm
    class CSVOutput < XDep::CSVOutput
      NPM_INFO = /=\s*(["'])(.+)\1/
      # TODO
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
        spec = JSON.load(input)

        spec.values_at("dependencies", "devDependencies").compact.each do |deps|
          deps.keys.each do |dep|
            # TODO: this can take a while...
            m = npm(dep).scan(NPM_INFO).map(&:last)
            if m.any?
              row = [ dep, m[0], m[1] ]
            else
              row = [ dep, nil, "Error: #{out}" ]
            end

            row.unshift "JavaScript"
            rows << row
          end
        end

        rows
      end

      private

      def npm(dep)
        # TODO: check for yarn
        out = `npm view -g #{dep} version description 2>&1`
        raise Error, "Failed to execute npm: #{out}" unless $?.exitstatus.zero?
        out
      end
    end
  end
end
