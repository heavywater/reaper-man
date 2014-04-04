require 'zlib'
require 'fileutils'

module Reaper

  class Generator

    autoload :Apt, 'reaper/generator/apt'
    autoload :Rpm, 'reaper/generator/rpm'
    autoload :Rubygems, 'reaper/generator/rubygems'

    include Utils::Checksum

    attr_reader :package_system, :package_config, :signer, :options

    def initialize(args={})
      args = args.dup
      @package_system = args.delete(:package_system)
      @package_config = args.delete(:package_config)
      @signer = args.delete(:signer)
      @options = args
      extend self.class.const_get(package_system.to_s.split('_').map(&:capitalize).join.to_sym)
    end

    def generate!
      raise NoMethodError.new 'Not implemented'
    end

    def create_file(*name)
      path = File.join(options[:output_directory], *name)
      FileUtils.mkdir_p(File.dirname(path))
      file = File.open(path, 'wb+')
      if(block_given?)
        yield file
      end
      file.close unless file.closed?
      path
    end

    def for_file(*name)
      path = File.join(options[:output_directory], *name)
      FileUtils.mkdir_p(File.dirname(path))
      if(block_given?)
        file = File.open(path, 'a+')
        yield file
        file.close
      end
      path
    end

    def compress_file(*path)
      compressed_path = path.dup
      compressed_path.push("#{compressed_path.pop}.gz")
      base_file = File.open(for_file(path))
      create_file(compressed_path) do |file|
        compressor = Zlib::GzipWriter.new(file)
        while(data = base_file.read(2048))
          compressor.write(data)
        end
        compressor.close
      end
    end

  end

end
