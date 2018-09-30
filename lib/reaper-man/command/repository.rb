require "reaper-man"

module ReaperMan
  class Command
    class Repository < Command
      autoload :Generate, "reaper-man/command/repository/generate"
    end
  end
end
