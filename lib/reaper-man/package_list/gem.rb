require "reaper-man"
require "rubygems/package"

module ReaperMan
  class PackageList
    class Processor
      class Gem < Processor

        # Add a package to the list
        #
        # @param conf [Hash]
        # @param package [String] path to package
        def add(hash, package)
          if hash["rubygem"] && !hash.to_smash.get(:rubygem, :clean)
            hash["rubygem"] = clean(hash["rubygem"])
            hash["rubygem"]["clean"] = true
          end
          info = extract_fields(package)
          filenames = inject_package(hash, info, package)
          filenames
        end

        # Remove package from the list
        #
        # @param conf [Hash] configuration hash
        # @param package_name [String] name
        # @param version [String]
        def remove(hash, package_name, version, args = {})
          deleted = false
          if hash["rubygems"][package_name]
            if version
              deleted = hash["rubygems"][package_name].delete(version)
            else
              deleted = hash["rubygems"].delete(package_name)
            end
          end
          !!deleted
        end

        # Extract package metadata
        #
        # @param package [String] path to package
        # @return [Hash]
        def extract_fields(package)
          spec = ::Gem::Package.new(package).spec
          fields = Smash[
            spec.class.attribute_names.map do |var_name|
              value = spec.send(var_name)
              next if value.nil? || (value.respond_to?(:empty?) && value.empty?)
              [var_name, value]
            end.compact
          ]
          fields["dependencies"] = fields["dependencies"].map do |dep|
            [dep.name, dep.requirement.to_s.split(",").map(&:strip)]
          end
          if fields["required_ruby_version"]
            fields["required_ruby_version"] = fields["required_ruby_version"].
              to_s.split(",").map(&:strip)
          end
          fields
        end

        # Insert package information into package list
        #
        # @param hash [Hash] package list contents
        # @param info [Hash] package information
        # @param package [String] path to package file
        # @return [Array<String>] package paths within package list contents
        def inject_package(hash, info, package)
          package_path = File.join(
            "rubygems", "gems", "#{info["name"]}-#{info["version"]}.gem"
          )
          classification = info["version"].prerelease? ? "prerelease" : "release"
          info["version"] = info["version"].version
          hash.deep_merge!(
            "rubygem" => {
              classification => {
                info["name"] => {
                  info["version"].to_s => info.merge("package_path" => package_path),
                },
              },
            },
          )
          package_path
        end

        # Clean data hash of empty values
        #
        # @param hash [Hash] package list information
        # @return [Smash]
        def clean(hash)
          Smash[
            hash.map { |k, v|
              v = clean(v) if v.is_a?(Hash)
              next if v.nil? || (v.respond_to?(:empty?) && v.empty?)
              [k, v]
            }
          ]
        end
      end
    end
  end
end
