$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + "/lib/"
require "reaper-man/version"
Gem::Specification.new do |s|
  s.name = "reaper-man"
  s.version = ReaperMan::VERSION.version
  s.summary = "Reap packages"
  s.author = "Chris Roberts"
  s.email = "code@chrisroberts.org"
  s.homepage = "https://github.com/spox/reaper-man"
  s.description = "Grow code, reap packages"
  s.require_path = "lib"
  s.required_ruby_version = "~> 2.2", "< 2.6"
  s.add_runtime_dependency "bogo-cli"
  s.add_runtime_dependency "childprocess"
  s.add_runtime_dependency "xml-simple"
  s.add_development_dependency "minitest"
  s.add_development_dependency "rufo", "~> 0.3.0"
  s.add_development_dependency "rake", "~> 10"
  s.add_development_dependency "rspec", "~> 3.5"
  s.executables << "reaper-man"
  s.files = Dir["lib/**/*"] + %w(reaper-man.gemspec README.md CHANGELOG.md CONTRIBUTING.md LICENSE)
end
