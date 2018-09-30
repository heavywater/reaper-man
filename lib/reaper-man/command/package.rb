require "reaper-man"

module ReaperMan
  class Command
    class Package < Command
      autoload :Add, "reaper-man/command/package/add"
      autoload :Remove, "reaper-man/command/package/remove"
    end
  end
end
