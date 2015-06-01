require 'reaper-man'

module ReaperMan
  class Command
    class Sign < Command

      def execute!
        run_action 'Signing file(s)' do
          signer = Signer.new(opts)
          files = Dir.glob(File.join(args.first, '**', '*'))
          files.delete_if do |path|
            !File.file?(path)
          end
          signer.package(*files)
          nil
        end
      end

    end
  end
end
