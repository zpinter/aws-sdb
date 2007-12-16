require 'rubygems'
require 'spec/rake/spectask'
require 'rake/gempackagetask'

Spec::Rake::SpecTask.new

gem_spec = Gem::Specification.new do |s|
  s.name = "aws-sdb"
  s.version = "0.0.1"
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.summary = "Amazon SDB API"
  s.description = s.summary
  s.author = "Tim Dysinger"
  s.email = "tim@dysinger.net"
  s.homepage = "http://dysinger.net"
  # s.add_dependency "uuidtools"
  s.require_path = 'lib'
  s.autorequire = s.name.gsub('-','/')
  s.files = %w(LICENSE README Rakefile) + Dir.glob("{lib,spec}/**/*")
end

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.gem_spec = gem_spec
end

task :install => [:package] do
  sh %{sudo gem install pkg/#{gem_spec.name}-#{gem_spec.version}}
end
