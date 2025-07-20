# -*- encoding: utf-8 -*-
# stub: votd 3.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "votd".freeze
  s.version = "3.0.2".freeze

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Steve Clarke".freeze, "Chris Clarke".freeze]
  s.date = "2020-04-01"
  s.email = ["steve@sevenview.ca".freeze, "chris@seven7.ca".freeze]
  s.executables = ["votd".freeze]
  s.files = ["bin/votd".freeze]
  s.homepage = "https://github.com/sevenview/votd".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.3".freeze)
  s.rubygems_version = "3.0.6".freeze
  s.summary = "Generate a (Bible) Verse of the Day using various web service wrappers".freeze

  s.installed_by_version = "3.6.2".freeze

  s.specification_version = 4

  s.add_runtime_dependency(%q<httparty>.freeze, [">= 0".freeze])
  s.add_runtime_dependency(%q<feedjira>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rake>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<webmock>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<guard-rspec>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<guard-bundler>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<yard>.freeze, [">= 0".freeze])
  s.add_development_dependency(%q<redcarpet>.freeze, [">= 0".freeze])
end
