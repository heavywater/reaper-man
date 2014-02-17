module Reaper

  class Signer

    autoload :Rpm, 'reaper/signer/rpm'
    autoload :Deb, 'reaper/signer/deb'

    include Utils::Process

    attr_reader :key_id, :sign_chunk_size, :sign_type, :package_system

    def initialize(args={})
      @key_id = args[:signing_key]
      @sign_chunk_size = args[:signing_chunk_size] || 20
      @sign_type = args[:signing_type] || 'origin'
      @package_system = args[:package_system]
      case package_system.to_sym
      when :deb, :apt
        extend Deb
      when :rpm, :yum
        extend Rpm
      else
        raise TypeError.new "Unknown packaging type requested (#{package_system})"
      end
    end

    def file(src, dst=nil)
      opts = ['--detach-sign', '--armor']
      dst ||= src.sub(/#{Regexp.escape(File.extname(src))}$/, '.gpg')
      opts << "--output '#{dst}'"
      cmd = (['gpg'] + opts + [src]).join(' ')
      shellout!(cmd)
    end

  end

end
