require 'mixlib/cli'
require 'stringio'

require 'reaper'

module Reaper
  # Command line interface
  class Cli

    autoload :Repo, 'reaper/cli/repo'
    autoload :Package, 'reaper/cli/package'
    autoload :Sign, 'reaper/cli/sign'

    include Mixlib::CLI

    banner 'reaper (package|repo|sign)'

    class << self

      # Allow options to fall into subclasses
      #
      # @param klass [Class]
      def inherited(klass)
        klass.send(:include, Mixlib::CLI)
        self.options.each do |args|
          klass.option(*args)
        end
      end

    end

    option(:configuration,
      :short => '-c JSON_FILE',
      :long => '--config JSON_FILE',
      :description => 'Use configuration provided via JSON file'
    )
    option(:signing_key,
      :short => '-k SIGNING_KEY',
      :long => '--signing-key SIGNING_KEY',
      :description => 'Sign generated files using given key'
    )
    option(:signing_type,
      :short => '-T TYPE',
      :long => '--signing-type TYPE',
      :description => 'Signing type name'
    )
    option(:sign,
      :long => '--[no-]sign',
      :description => 'Enable file signing',
      :boolean => true,
      :default => true
    )
    option(:package_system,
      :short => '-s PACKAGE_SYSTEM',
      :long => '--package-system PACKAGE_SYSTEM',
      :description => 'Packaging system to generate repository (apt/yum/rubygems)'
    )
    option(:packages_file,
      :short => '-p FILE',
      :long => '--packages-file FILE',
      :description => 'Path to JSON packages file'
    )

    # Mapping for CLI class to load
    CLI_MAP = {
      :repo => Repo,
      :package => Package,
      :sign => Sign
    }

    class << self

      # Initialize the CLI instance
      #
      # @return [Cli]
      def init!
        obj = new
        obj.config = Config.new(obj.config)
        obj
      end

      # Process the provided command
      def process!
        orig_out = $stdout
        obj = nil
        begin
          if(ARGV.first && klass = CLI_MAP[ARGV.first.to_sym])
            obj = klass.init!
          else
            help
            exit -1
          end
        rescue => e
          help
          raise
        end
        if(ARGV[1] && obj.class.instance_methods(false).map(&:to_sym).include?(method = ARGV[1].to_sym))
          obj.send(method)
        else
          obj.help
        end
      end

    end

    # @return [Array<Symbol>] callable actions
    def actions
      self.class.instance_methods(false)
    end

    # Perform action with custom message
    #
    # @param doing [String] message of action in progress
    # @yield block to execute wrapped in message
    # @return [Object] result of block
    def action(doing)
      print "#{doing}... "
      result = yield
      puts "done!"
      result
    end

    # Output help text
    #
    # @return [TrueClass]
    def help
      opt_to_desc = self.class.options.values.map{|x|(x[:long] || x[:short]).length}.max + 2
      puts "Usage: #{self.class.banner} (options)"
      self.class.options.values.each do |opt|
        str = opt[:short] ? "#{opt[:short].split(' ').first}, #{opt[:long]}" : (' ' * 4) + opt[:long]
        str += [
          ' ' * (opt_to_desc - opt[:long].length),
          opt[:description],
          opt[:required] ? '(required)' : nil
        ].compact.join(' ')
        puts "\t#{str}"
      end
      true
    end

    # Load JSON from file
    #
    # @param path [String] JSON file path
    # @return [Rash]
    def load_json(path)
      if(File.exist?(path.to_s))
        MultiJson.load(File.read(path)).to_rash
      else
        raise Error::FileNotFound.new("No file found at provided path (#{path})")
      end
    end

    # @return [Signer] configuration based signer instance
    def signer
      Signer.new(
        :key_id => config[:signing_key],
        :sign_type => config[:signing_type],
        :package_system => config.fetch(:package_system, 'deb'),
        :key_password => config.fetch(:signing_password, ENV['REAPER_GPG_PASSWORD'])
      )
    end

  end
end
