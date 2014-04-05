require 'rubygems/package'

module Reaper
  class PackageList
    class Processor
      class Gem < Processor

        def initialize(*_)
        end

        def add(hash, package)
          info = extract_fields(package)
          filenames = inject_package(hash, info, package)
          filenames
        end

        def remove(hash, package_name, version, args={})
          deleted = false
          if(hash['rubygems'][package_name])
            if(version)
              deleted = hash['rubygems'][package_name].delete(version)
            else
              deleted = hash['rubygems'].delete(package_name)
            end
          end
          !!deleted
        end

        def extract_fields(package)
          spec = ::Gem::Package.open(File.open(package)){|pack| pack.metadata}
          fields = Rash[
            spec.to_yaml_properties.map do |var_name|
              [var_name.to_s.tr('@', ''), spec.instance_variable_get(var_name)]
            end
          ]
          fields['dependencies'] = fields['dependencies'].map do |dep|
            [dep.name, dep.requirement.to_s]
          end
          fields
        end

        def inject_package(hash, info, package)
          package_path = File.join(
            'rubygems', 'gems', "#{info['name']}-#{info['version']}.gem"
          )
          classification = info['version'].prerelease? ? 'prerelease' : 'release'
          info['version'] = info['version'].version
          hash.deep_merge!(
            'rubygem' => {
              classification => {
                info['name'] => {
                  info['version'].to_s => info.merge('package_path' => package_path)
                }
              }
            }
          )
          package_path
        end

      end
    end
  end
end
