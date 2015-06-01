require 'reaper-man'

module ReaperMan
  class Command
    class Sign < Command

      def execute!
        run_action 'Signing file(s)' do
          signer = Signer.new(config)
          files = Dir.glob(File.join(arguments.first, '**', '*'))
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
