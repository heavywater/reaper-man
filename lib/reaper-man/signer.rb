require 'reaper-man'

module ReaperMan
  # File signer
  class Signer

    autoload :Rpm, 'reaper-man/signer/rpm'
    autoload :Deb, 'reaper-man/signer/deb'
    autoload :Rubygems, 'reaper-man/signer/rubygems'

    include Utils::Process

    attr_reader :key_id
    attr_reader :sign_chunk_size
    attr_reader :sign_type
    attr_reader :package_system
    attr_reader :key_password

    # Create new instance
    #
    # @param args [Hash]
    # @option args [String] :signing_key
    # @option args [String] :signing_chunk_size (defaults to 1)
    # @option args [String] :signing_type (defaults to 'origin')
    # @option args [String] :key_password (defaults to `ENV['REAPER_KEY_PASSWORD']`)
    # @option args [String] :package_system
    def initialize(args={})
      args = args.to_smash
      @key_id = args[:signing_key]
      @sign_chunk_size = args.fetch(:signing_chunk_size, 1)
      @sign_type = args.fetch(:signing_type, 'origin')
      @key_password = args.fetch(:key_password, ENV['REAPER_KEY_PASSWORD'])
      @package_system = args[:package_system]
      case package_system.to_sym
      when :deb, :apt
        extend Deb
      when :rpm, :yum
        extend Rpm
      when :gem, :rubygems
        extend Rubygems
      else
        raise TypeError.new "Unknown packaging type requested (#{package_system})"
      end
    end

    # Sign the file
    #
    # @param src [String] path to source file
    # @param dst [String] path for destination file
    # @return [String] destination file path
    def file(src, dst=nil)
      opts = ['--detach-sign', '--armor']
      dst ||= src.sub(/#{Regexp.escape(File.extname(src))}$/, '.gpg')
      opts << "--output '#{dst}'"
      cmd = (['gpg'] + opts + [src]).join(' ')
      shellout!(cmd)
      dst
    end

  end

end
