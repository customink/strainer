$:.unshift File.expand_path('../lib', __FILE__)
require 'strainer/version'

Gem::Specification.new do |gem|
  gem.version       = Strainer::VERSION
  gem.authors       = ['Seth Vargo']
  gem.email         = ['sethvargo@gmail.com']
  gem.description   = %q{Run isolated cookbook tests against your chef repository with Strainer.}
  gem.summary       = %q{Strainer allows you to run cookbook tests in an isolated environment while still keeping a single Gemfile and repository for all your cookbooks.}
  gem.homepage      = 'https://github.com/customink/strainer'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'strainer'
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'berkshelf', '~> 2.0'

  gem.add_development_dependency 'redcarpet'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'rake'
end
