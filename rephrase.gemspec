require_relative './lib/rephrase/version'

Gem::Specification.new do |s|
  s.name        = 'Rephrase'
  s.version     = Rephrase::VERSION
  s.licenses    = ['MIT']
  s.summary     = 'Rephrase: a gem for manipulating Ruby code'
  s.author      = 'Sharon Rosner'
  s.email       = 'ciconia@gmail.com'
  s.files       = `git ls-files README.md CHANGELOG.md lib`.split
  s.homepage    = 'http://github.com/digital-fabric/rephrase'
  s.metadata    = {
    "source_code_uri" => "https://github.com/digital-fabric/rephrase"
  }
  s.rdoc_options = ["--title", "Rephrase", "--main", "README.md"]
  s.extra_rdoc_files = ["README.md"]
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 2.7'

  s.add_development_dependency  'minitest',       '5.11.3'
end
