module Reaper
  class Generator
    module Apt

      def generate!
        generate_dists(package_config[:apt])
      end

      def generate_dists(pkg_hash)
        pkg_hash.each do |origin_name, dists|
          dists.each do |dist_name, dist_args|
            dist_args[:components].each do |component_name, arches|
              arches.each do |arch_name, packages|
                package_file(origin_name, dist_name, component_name, arch_name, packages)
                release_headers = Rash.new
                release_headers['Label'] = dist_args['label']
                release_headers['Archive'] = dist_name
                sign_file_if_setup do
                  release_file(origin_name, dist_name, component_name, arch_name, release_headers)
                end
              end
            end
            release_headers = Rash[
              %w(Codename Suite Label Description Version).map do |field_name|
                if(val = dist_args[field_name.downcase])
                  [field_name, val]
                end
              end.compact
            ]
            release_headers['Components'] = dist_args[:components].keys.join(' ')
            sign_file_if_setup do
              release_file(origin_name, dist_name, release_headers)
            end
          end
        end
      end

      def sign_file_if_setup
        path = yield
        if(signer && options[:sign])
          signer.file(path)
        end
        path
      end

      def package_file(*args)
        pkgs = args.pop
        create_file(*args.push('Packages')) do |file|
          pkgs.each do |pkg_name, pkgs|
            pkgs.each do |pkg_version, pkg_meta|
              pkg_meta.each do |field_name, field_value|
                if(field_value)
                  file.puts "#{field_name}: #{field_value}"
                end
              end
              file.puts
            end
          end
        end
        compress_file(*args)
      end

      def compress_file(*path)
        compressed_path = path.dup
        compressed_path.push("#{compressed_path.pop}.gz")
        file = File.open(for_file(path))
        create_file(compressed_path) do |file|
          compressor = Zlib::GzipWriter.new(file)
          while(data = file.read(2048))
            compressor.write(data)
          end
          compressor.close
        end
      end

      def release_file(*args)
        header = args.detect{|a| a.is_a?(Hash)}
        header ? args.delete(header) : header = Rash.new
        header.merge(Rash[%w(Origin Codename Component Architecture).zip(args)])
        header['Date'] = Time.now.utc.strftime('%a, %d %b %Y %H:%M:%S %Z')
        create_file(*args.dup.push('Release')) do |file|
          contents = Dir.glob(File.join(File.dirname(file.path), '**', '*'))
          header_content = header.map do |key, value|
            next unless value
            "#{key.to_s.capitalize}: #{value}"
          end.compact.join("\n")
          file.puts header_content
          [['MD5Sum', :md5], ['SHA1', :sha1], ['SHA256', :sha256]].each do |field, digest|
            file.puts "#{field}:"
            contents.each do |content|
              next if File.expand_path(content) == File.expand_path(file.path) || File.directory?(content)
              File.open(content, 'r') do |content_file|
                line = [' ']
                line << checksum(content_file, digest)
                line << content_file.size
                line << content_file.path.sub(File.dirname(file.path), '').sub(/^\//, '')
                file.puts line.join(' ')
              end
            end
          end
        end
      end


    end
  end
end
