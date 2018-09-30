require "reaper-man"

module ReaperMan
  class Command
    class Sign < Command
      def execute!
        files = arguments.map do |item|
          if File.file?(item)
            item
          else
            File.directory?(item)
            i_files = Dir.glob(File.join(item, "**", "*"))
            i_files.delete_if do |path|
              !File.file?(path)
            end
            i_files
          end
        end.flatten.compact.uniq
        run_action "Signing file(s)" do
          signer = Signer.new(config)
          signer.package(*files)
          nil
        end
        ui.info "Files signed:"
        files.sort.each do |path|
          ui.puts "  #{ui.color(File.expand_path(path), :yellow)}"
        end
      end
    end
  end
end
