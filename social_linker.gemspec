# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'social_linker/version'

Gem::Specification.new do |spec|
  spec.name          = "social_linker"
  spec.version       = SocialLinker::VERSION
  spec.authors       = ["murb"]
  spec.email         = ["info@murb.nl"]

  spec.summary       = "Social linker generates share-links for the different social networks from a simple SocialLinker::Subject class"
  spec.description   = "Social linker generates share-links for the different social networks from a simple SocialLinker::Subject class.

Supported networks are: Twitter, Facebook, LinkedIn, Google+, Pinterest, and email"
  spec.homepage      = "https://murb.nl/blog?tags=social_linker"
  spec.license       = "MIT"


  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
