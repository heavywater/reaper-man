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
            spec.to_yaml_properties.map do |var_name|
              [var_name.to_s.tr("@", ""), spec.instance_variable_get(var_name)]
            end
          ]
          fields["dependencies"] = fields["dependencies"].map do |dep|
            [dep.name, dep.requirement.to_s.split(",").map(&:strip)]
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
      end
    end
  end
end
