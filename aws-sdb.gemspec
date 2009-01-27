gem_spec = Gem::Specification.new do |s|
  s.name = "aws-sdb"
  s.rubyforge_project = s.name
  s.version = "0.4.0"
  s.has_rdoc = false
  s.extra_rdoc_files = ["README", "LICENSE"]
  s.summary = "Amazon SDB API"
  s.description = s.summary
  s.author = "Tim Dysinger"
  s.email = "tim+aws-sdb@dysinger.net"
  s.homepage = "http://github.com/dysinger/aws-sdb"
  s.add_dependency "uuidtools"
  s.require_path = 'lib'
  s.files = %w(LICENSE README Rakefile) + Dir.glob("{lib,spec}/**/*")
end
