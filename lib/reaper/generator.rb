require 'zlib'
require 'fileutils'

module Reaper

  class Generator

    autoload :Apt, 'reaper/generator/apt'
    autoload :Rpm, 'reaper/generator/rpm'

    include Utils::Checksum

    attr_reader :package_system, :package_config, :signer, :options

    def initialize(args={})
      args = args.dup
      @package_system = args.delete(:package_system)
      @package_config = args.delete(:package_config)
      @signer = args.delete(:signer)
      @options = args
      case package_system.to_sym
      when :apt
        extend Apt
      when :rpm
        extend Rpm
      end
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


  end

end
