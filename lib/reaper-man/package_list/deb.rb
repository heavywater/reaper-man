require 'reaper-man'

module ReaperMan
  class PackageList
    class Processor
      # Package list process for debian packages
      class Deb < Processor

        # @return [String]
        attr_reader :origin
        # @return [String]
        attr_reader :dist
        # @return [String]
        attr_reader :component
        # @return [Array<String>] architectures
        attr_reader :all_map
        # @return [String] prefix for package file location
        attr_reader :package_root
        # @return [String] namespace for packages
        attr_reader :package_bucket

        # default package root prefix
        DEFAULT_ROOT = 'pool'
        # default namespace for packages
        DEFAULT_BUCKET = 'public'
        # default architectures to define
        DEFAULT_ALL_MAP = ['amd64', 'i386']

        # Create new instance
        #
        # @param args [Hash]
        # @option args [String] :origin
        # @option args [String] :codename
        # @option args [String] :component
        # @option args [String] :package_root
        # @option args [String] :package_bucket
        # @option args [Array<String>] :all_map
        def initialize(args={})
          @origin = args[:origin].to_s
          @dist = args[:codename].to_s
          @component = args[:component].to_s
          @package_root = args.fetch(:package_root, DEFAULT_ROOT)
          @package_bucket = args.fetch(:package_bucket, DEFAULT_BUCKET)
          if(dist.empty? || component.empty?)
            raise 'Both `codename` and `component` must contain valid values'
          end
          @all_map = args.fetch(:all_map, DEFAULT_ALL_MAP)
        end

        # Add a package to the list
        #
        # @param conf [Hash]
        # @param package [String] path to package
        def add(hash, package)
          info = extract_fields(package)
          info.merge!(generate_checksums(package))
          filenames = inject_package(hash, info, package)
          filenames
        end

        # Remove package from the list
        #
        # @param conf [Hash] configuration hash
        # @param package_name [String] name
        # @param version [String]
        def remove(hash, package_name, version, args={})
          hash = hash.to_smash
          arch = [args.fetch(:arch, all_map)].flatten.compact
          deleted = false
          arch.each do |arch_name|
            arch_name = "binary-#{arch_name}"
            if(hash.get(:apt, origin, dist, :components, component, arch_name, package_name))
              if(version)
                deleted = hash[:apt][origin][dist][:components][component][arch_name][package_name].delete(version)
              else
                deleted = hash[:apt][origin][dist][:components][component][arch_name].delete(package_name)
              end
            end
          end
          !!deleted
        end

        # Extract package metadata
        #
        # @param package [String] path to package
        # @return [Hash]
        def extract_fields(package)
          content = shellout("dpkg-deb -f '#{package}'")
          Smash[content.stdout.scan(/([^\s][^:]+):\s+(([^\n]|\n\s)+)/).map{|a| a.slice(0,2)}]
        end

        # Insert package information into package list
        #
        # @param hash [Hash] package list contents
        # @param info [Hash] package information
        # @param package [String] path to package file
        # @return [Array<String>] package paths within package list contents
        def inject_package(hash, info, package)
          arch = info['Architecture']
          arch = arch == 'all' ? all_map : [arch]
          arch.map do |arch|
            package_file_name = File.join(
              package_root, package_bucket, origin,
              dist, component, "binary-#{arch}",
              File.basename(package)
            )
            hash.deep_merge!(
              'apt' => {
                origin => {
                  dist => {
                    'components' => {
                      component => {
                        "binary-#{arch}" => {
                          info['Package'] => {
                            info['Version'] => info.merge!(
                              'Filename' => package_file_name,
                              'Size' => File.size(package)
                            )
                          }
                        },
                        "binary-i386" => {
                        }
                      }
                    }
                  }
                }
              }
            )
            File.join('apt', origin, package_file_name)
          end
        end

        # Generate required checksums for given package
        #
        # @param package [String] path to package file
        # @return [Hash] checksums
        def generate_checksums(package)
          File.open(package, 'r') do |pkg|
            {
              'MD5sum' => checksum(pkg.rewind && pkg, :md5),
              'SHA1' => checksum(pkg.rewind && pkg, :sha1),
              'SHA256' => checksum(pkg.rewind && pkg, :sha256)
            }
          end
        end

      end
    end
  end
end
