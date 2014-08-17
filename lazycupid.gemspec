# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'LazyCupid/version'

Gem::Specification.new do |spec|
  spec.name          = "lazycupid"
  spec.version       = LazyCupid::VERSION
  spec.authors       = ["Nick Prokesch"]
  spec.email         = ["nick@prokes.ch"]
  spec.summary       = %q{An OKCupid bot designed to get you a ton of visitors and messages}
  spec.description   = %q{Interacts with okcupid based on user preferences}
  spec.homepage      = "http://nick.prokes.ch"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.require_paths    = ["lib"]
  spec.bindir = 'bin'
  spec.executables << 'lazycupid'

  spec.add_dependency "dotenv", "~> 0.11"
  spec.add_dependency "mechanize", "~> 2.7"
  spec.add_dependency "progress_bar", "~> 1.0"
  spec.add_dependency "highline", "~> 1.6"
  spec.add_dependency "chronic", "~> 0.10"
  spec.add_dependency "time-lord", "~> 1.0"
  spec.add_dependency "pg", "~> 0.17"
  spec.add_dependency "rufus-scheduler", "~> 2.0"
  spec.add_dependency "sequel", "~> 4.3"
  spec.add_dependency "uuidtools", "~> 2.1"
  spec.add_dependency "bloat_check", "~> 0.0"
  spec.add_dependency "lingua", "~> 0.6"
  spec.add_dependency "watir-webdriver", "~> 0.6"
  spec.add_dependency "watir-scroll", "~> 0.1"
  spec.add_dependency "uclassify", "~> 0.1"
  spec.add_dependency "cliutils", "~> 2.2"
  spec.add_dependency "hr", "~> 0.0"
end