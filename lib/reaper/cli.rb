require 'mixlib/cli'
require 'stringio'

module Reaper
  class Cli

    autoload :Repo, 'reaper/cli/repo'
    autoload :Package, 'reaper/cli/package'
    autoload :Sign, 'reaper/cli/sign'

    include Mixlib::CLI

    banner 'reaper ACTION'

    class << self
      # make options fall through
      def inherited(klass)
        klass.options = self.options
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

    CLI_MAP = {
      :repo => Repo,
      :package => Package,
      :sign => Sign
    }

    class << self
      def init!
        obj = new
        obj.config = Config.new(obj.config)
        obj
      end
    end

    def actions
      self.class.instance_methods(false)
    end

    def action(doing)
      print "#{doing}... "
      yield
      puts "done!"
    end

    def help
      opt_to_desc = self.class.options.values.map{|x|x[:long].length}.max + 2
      puts "Usage: #{self.class.banner} (options)"
      self.class.options.values.each do |opt|
        str = [
          opt[:short].split(' ').first,
          opt[:long],
        ].compact.join(', ') + [
          ' ' * (opt_to_desc - opt[:long].length),
          opt[:required] ? '(Required)' : nil,
          opt[:description]
        ].compact.join(' ')
        puts "\t#{str}"
      end
    end

    def process!
      orig_out = $stdout
      obj = nil
      begin
        obj = CLI_MAP[ARGV.first.to_sym].init!
      rescue => e
        help
        raise
      end
      method = ARGV[1].to_sym
      if(obj.class.instance_methods(false).map(&:to_sym).include?(method))
        obj.send(method)
      else
        obj.help
      end
    end

    def load_json(path)
      if(File.exist?(path.to_s))
        MultiJson.load(File.read(path)).to_rash
      else
        raise Error::FileNotFound.new("No file found at provided path (#{path})")
      end
    end

    def signer
      Signer.new(
        :key_id => config[:signing_key],
        :sign_type => config[:signing_type],
        :package_system => config.fetch(:package_system, 'deb')
      )
    end

  end
end
