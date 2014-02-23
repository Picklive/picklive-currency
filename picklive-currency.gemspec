# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require 'picklive/currency/autoload'

Gem::Specification.new do |s|
  s.name        = "picklive-currency"
  s.version     = "1.0.0"
  s.authors     = ["Levente Bagi"]
  s.email       = ["levente@picklive.com"]
  s.homepage    = "https://tech.picklive.com"
  s.summary     = %q{Picklive Currency}
  s.description = %q{Currency classes that can represent GBP, USD or Chips}

  s.rubyforge_project = "picklive-currency"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "actionpack"
  s.add_development_dependency "rspec"

end
