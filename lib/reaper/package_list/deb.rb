module Reaper
  class PackageList
    class Processor
      class Deb < Processor

        attr_reader :origin, :dist, :component, :all_map, :package_root, :package_bucket

        DEFAULT_ROOT = 'pool'
        DEFAULT_BUCKET = 'public'
        DEFAULT_ALL_MAP = ['amd64', 'i386']

        def initialize(args={})
          @origin = args[:origin]
          @dist = args[:codename]
          @component = args[:component]
          @package_root = args.fetch(:package_root, DEFAULT_ROOT)
          @package_bucket = args.fetch(:package_bucket, DEFAULT_BUCKET)
          unless(dist && component)
            raise 'Both `codename` and `component` must contain valid values'
          end
          @all_map = args.fetch(:all_map, DEFAULT_ALL_MAP)
        end

        def add(hash, package)
          info = extract_fields(package)
          info.merge!(generate_checksums(package))
          inject_package(hash, info, package)
          true
        end

        def remove(hash, package_name, version, args={})
          hash = hash.to_rash
          arch = [args.fetch(:arch, all_map)].flatten.compact
          deleted = false
          arch.each do |arch_name|
            arch_name = "binary-#{arch_name}"
            if(hash.retrieve(:apt, origin, dist, :components, component, arch_name, package_name))
              if(version)
                deleted = hash[:apt][origin][dist][:components][component][arch_name][package_name].delete(version)
              else
                deleted = hash[:apt][origin][dist][:components][component][arch_name].delete(package_name)
              end
            end
          end
          !!deleted
        end

        def extract_fields(package)
          content = shellout("dpkg-deb -f '#{package}'")
          Rash[content.scan(/([^\s][^:]+):\s+(([^\n]|\n\s)+)/).map{|a| a.slice(0,2)}]
        end

        def inject_package(hash, info, package)
          arch = info['Architecture']
          arch = arch == 'all' ? all_map : [arch]
          arch.each do |arch|
            hash.deep_merge!(
              'apt' => {
                origin => {
                  dist => {
                    'components' => {
                      component => {
                        "binary-#{arch}" => {
                          info['Package'] => {
                            info['Version'] => info.merge!(
                              'Filename' => File.join(
                                package_root, package_bucket, origin,
                                dist, component, "binary-#{arch}",
                                File.basename(package)
                              )
                            )
                          }
                        }
                      }
                    }
                  }
                }
              }
            )
          end
          true
        end

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
