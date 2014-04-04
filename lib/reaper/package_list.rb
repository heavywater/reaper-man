require 'multi_json'

module Reaper
  class PackageList

    class Processor
      autoload :Rpm, 'reaper/package_list/rpm'
      autoload :Deb, 'reaper/package_list/deb'
      autoload :Gem, 'reaper/package_list/gem'

      include Utils::Process
      include Utils::Checksum

      def add(hash, package)
        raise NoMethodError.new 'Not implemented'
      end

      def remove(hash, package, version=nil)
        raise NoMethodError.new 'Not implemented'
      end
    end

    attr_reader :path, :options, :init_mtime, :content

    def initialize(path, args={})
      @path = path
      @options = args.dup
      @content = Rash.new
      init_list!
    end

    def add_package(package)
      package_handler(File.extname(package).tr('.', '')).add(content, package)
    end

    def remove_package(package, version=nil)
      ext = File.extname(package).tr('.', '')
      if(ext.empty?)
        ext = %w(deb) # rpm)
      else
        ext = [ext]
      end
      ext.each do |ext_name|
        package_handler(ext_name).remove(content, package, version)
      end
    end

    def serialize
      MultiJson.dump(content)
    end

    def write!
      new_file = !File.exists?(path)
      File.open(path, File::CREAT|File::RDWR) do |file|
        file.flock(File::LOCK_EX)
        if(!new_file && init_mtime != file.mtime)
          file.rewind
          content.deep_merge!(
            MultiJson.load(
              file.read
            )
          )
          file.rewind
        end
        pos = file.write MultiJson.dump(content, :pretty => true)
        file.truncate(pos)
      end
    end

    private

    def package_handler(pkg_ext)
      Processor.const_get(pkg_ext.capitalize).new(options)
    end

    def init_list!
      write! unless File.exist?(path)
      @init_mtime = File.mtime(path)
      content.deep_merge!(
        MultiJson.load(
          File.open(path, 'r') do |file|
            file.flock(File::LOCK_SH)
            file.read
          end
        )
      )
    end

  end
end
