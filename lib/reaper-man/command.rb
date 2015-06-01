require 'reaper-man'

module ReaperMan
  class Command < Bogo::Cli::Command

    autoload :Repository, 'reaper-man/command/repository'
    autoload :Package, 'reaper-man/command/package'
    autoload :Sign, 'reaper-man/command/sign'

  end
end
