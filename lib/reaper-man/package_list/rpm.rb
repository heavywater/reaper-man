require 'reaper-man'

module ReaperMan
  class PackageList
    class Processor
      # Package list process for RPM packages
      class Rpm < Processor

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
            if(hash.get(:yum, origin, dist, :components, component, arch_name, package_name))
              if(version)
                deleted = hash[:yum][origin][dist][:components][component][arch_name][package_name].delete(version)
              else
                deleted = hash[:yum][origin][dist][:components][component][arch_name].delete(package_name)
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
          fields = shellout('rpm --querytags').stdout.split("\n").map do |line|
            line.strip!
            unless(line.empty? || line.start_with?('HEADER'))
              line
            end
          end.compact

          fmt = fields.map do |k|
            ["\\[#{k}\\]", "[%{#{k}}\n]"]
          end.flatten.join("\n")

          cmd = "rpm -q -p #{package} --queryformat 'output:\n#{fmt}'"
          result = shellout(cmd).stdout.sub(/.*output:/, '')

          data = Smash.new
          key = nil
          result.split("\n").each do |item|
            item.strip!
            next if item.empty?
            if(item.start_with?('[') && item.end_with?(']'))
              key = item.tr('[]', '')
            else
              if(data[key])
                if(!data[key].is_a?(Array))
                  data[key] = [data[key]]
                end
                data[key] << item
              else
                data[key] = item
              end
            end
          end
          data[:generated_sha] = checksum(File.open(package, 'r'), :sha1)
          data[:generated_size] = File.size(package)
          data[:generated_header] = extract_header_information(package)
          data
        end

        # Insert package information into package list
        #
        # @param hash [Hash] package list contents
        # @param info [Hash] package information
        # @param package [String] path to package file
        # @return [Array<String>] package paths within package list contents
        def inject_package(hash, info, package)
          arch = info['ARCH']
          arch = arch == 'all' ? all_map : [arch]
          arch.map do |arch|
            package_file_name = File.join(
              package_root, package_bucket, origin,
              dist, component, File.basename(package)
            )
            hash.deep_merge!(
              'yum' => {
                origin => {
                  dist => {
                    'components' => {
                      component => {
                        arch => {
                          info['NAME'] => {
                            info['NEVR'] => info.merge(:generated_path => package_file_name)
                          }
                        }
                      }
                    }
                  }
                }
              }
            )
            File.join('yum', origin, package_file_name)
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

        # Extract the start and end points of the header within the
        # package
        #
        # @param package [String] path to package
        # @return [Smash<start,end>]
        # @note ported from: http://yum.baseurl.org/gitweb?p=yum.git;a=blob;f=yum/packages.py;h=eebeb9dfd264b887b054187276cea12ced3a0bc2;hb=HEAD#l2212
        def extract_header_information(package)
          io = File.open(package, 'rb')

          # read past lead and 8 bytes of signature header
          io.seek(104)
          binindex = io.read(4)
          sigindex, _ = binindex.unpack('I>')

          bindata = io.read(4)
          sigdata, _ = bindata.unpack('I>')

          # seeked in to 112 bytes

          # each index is 4 32bit segments == 16 bytes

          sigindexsize = sigindex * 16
          sigsize = sigdata + sigindexsize

          # Round to next 8 byte boundary

          disttoboundary = (sigsize % 8)
          unless(disttoboundary == 0)
            disttoboundary = 8 - disttoboundary
          end

          # 112 bytes - 96 == lead
          # 8 == magic and reserved
          # 8 == signature header data

          hdrstart = 112 + sigsize + disttoboundary

          # seek to start of header
          io.seek(hdrstart)
          # seek past magic
          io.seek(8, IO::SEEK_CUR)

          binindex = io.read(4)

          hdrindex, _ = binindex.unpack('I>')
          bindata = io.read(4)
          hdrdata, _ = bindata.unpack('I>')

          # each index is 4 32bit segments - so each is 16 bytes

          hdrindexsize = hdrindex * 16

          # add 16 to the hdrsize to account for 16 bytes of misc data
          # between the end of the sig and the header

          hdrsize = hdrdata + hdrindexsize + 16

          # header end is hdrstart + hdrsize

          hdrend = hdrstart + hdrsize

          Smash.new(
            :start => hdrstart,
            :end => hdrend
          )
        end

      end
    end
  end
end
