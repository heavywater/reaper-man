require 'zlib'
require 'fileutils'

require 'reaper'

module Reaper
  # Repository generator
  class Generator

    autoload :Apt, 'reaper/generator/apt'
    autoload :Rpm, 'reaper/generator/rpm'
    autoload :Rubygems, 'reaper/generator/rubygems'

    include Utils::Checksum

    # @return [String]
    attr_reader :package_system
    # @return [Rash]
    attr_reader :package_config
    # @return [Signer, NilClass]
    attr_reader :signer
    # @return [Rash]
    attr_reader :options

    # Create new instance
    #
    # @param args [Hash]
    # @option args [String] :package_system apt/gem/etc...
    # @option args [Hash] :package_config
    # @option args [Signer] :signer
    def initialize(args={})
      args = args.dup
      @package_system = args.delete(:package_system)
      @package_config = (args.delete(:package_config) || {}).to_rash
      @signer = args.delete(:signer)
      @options = args.to_rash
      extend self.class.const_get(package_system.to_s.split('_').map(&:capitalize).join.to_sym)
    end

    # Generate new repository
    def generate!
      raise NoMethodError.new 'Not implemented'
    end

    # Create new file
    #
    # @param name [String] argument list joined to output directory
    # @yield block executed with file
    # @yieldparam [String] path to file
    # @return [String] path to file
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

    # Updates a file
    #
    # @param name [String] argument list joined to output directory
    # @yield block executed with file
    # @yieldparam [String] path to file
    # @return [String] path to file
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

    # Compress a file (gzip)
    #
    # @param name [String] argument list joined to output directory
    # @return [String] path to compressed file
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
