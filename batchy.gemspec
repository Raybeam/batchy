$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "batchy/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "batchy"
  s.version     = Batchy::VERSION
  s.authors     = ["Bob Briski"]
  s.email       = ["bbriski@raybeam.com"]
  s.homepage    = "https://github.com/Raybeam/batchy"
  s.summary     = "Set up and tear down a batch"
  s.description = "For handling all of the exceptions, states, timeouts, etc of batch processes"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "activerecord", "~> 3.0"
  s.add_dependency "activesupport", "~> 3.0"
  s.add_dependency "addressable", "~> 2.2"
  s.add_dependency "andand", "~> 1.3"
  s.add_dependency "rake"
  s.add_dependency "sys-proctable"

  s.add_development_dependency "rspec"
  s.add_development_dependency "factory_girl"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "database_cleaner"
end