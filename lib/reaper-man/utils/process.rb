require 'reaper-man'

module ReaperMan
  module Utils
    # Shellout helper
    module Process

      # NOTE: This is extracted from the elecksee gem and some
      # features removed that are not required here. Should be
      # wrapped up into standalone gem so it's more reusable.

      class CommandFailed < StandardError
        attr_accessor :original, :result
        def initialize(orig, result=nil)
          @original = orig
          @result = result
          super(orig.to_s)
        end
      end

      class Timeout < CommandFailed
      end

      class CommandResult
        attr_reader :original, :stdout, :stderr
        def initialize(result)
          @original = result
          if(result.class.ancestors.map(&:to_s).include?('ChildProcess::AbstractProcess'))
            extract_childprocess
          elsif(result.class.to_s == 'Mixlib::ShellOut')
            extract_shellout
          else
            raise TypeError.new("Unknown process result type received: #{result.class}")
          end
        end

        def extract_childprocess
          original.io.stdout.rewind
          original.io.stderr.rewind
          @stdout = original.io.stdout.read
          @stderr = original.io.stderr.read
          original.io.stdout.delete
          original.io.stderr.delete
        end

        def extract_shellout
          @stdout = original.stdout
          @stderr = original.stderr
        end
      end

      # Simple helper to shell out
      def shellout(cmd, args={})
        result = nil
        if(defined?(ChildProcess))
          cmd_type = :childprocess
        else
          cmd_type = :mixlib_shellout
        end
        com_block = nil
        case cmd_type
        when :childprocess
          require 'tempfile'
          com_block = lambda{ child_process_command(cmd, args) }
        when :mixlib_shellout
          require 'mixlib/shellout'
          com_block = lambda{ mixlib_shellout_command(cmd, args) }
        else
          raise ArgumentError.new("Unknown shellout helper provided: #{cmd_type}")
        end
        result = defined?(Bundler) ? Bundler.with_clean_env{ com_block.call } : com_block.call
        result == false ? false : CommandResult.new(result)
      end

      def child_process_command(cmd, args)
        s_out = Tempfile.new('stdout')
        s_err = Tempfile.new('stderr')
        s_out.sync
        s_err.sync
        c_proc = ChildProcess.build(*Shellwords.split(cmd))
        c_proc.environment.merge(args.fetch(:environment, {}))
        c_proc.io.stdout = s_out
        c_proc.io.stderr = s_err
        c_proc.start
        begin
          c_proc.poll_for_exit(args[:timeout] || 10)
        rescue ChildProcess::TimeoutError
          c_proc.stop
        ensure
          raise CommandFailed.new("Command failed: #{cmd}", CommandResult.new(c_proc)) if c_proc.crashed?
        end
        c_proc
      end

      def mixlib_shellout_command(cmd, args)
        shlout = nil
        begin
          shlout = Mixlib::ShellOut.new(cmd,
            :timeout => args[:timeout] || 10,
            :environment => args.fetch(:environment, {})
          )
          shlout.run_command
          shlout.error!
          shlout
        rescue Mixlib::ShellOut::ShellCommandFailed, CommandFailed, Mixlib::ShellOut::CommandTimeout => e
          raise CommandFailed.new(e, CommandResult.new(shlout))
        end
      end

    end
  end
end
