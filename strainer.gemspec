Gem::Specification.new do |gem|
  gem.version       = '0.1.1'
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

  gem.add_runtime_dependency 'chef', '~> 10.12.0'
  gem.add_runtime_dependency 'term-ansicolor', '~> 1.0.7'

  gem.add_development_dependency 'yard', '~> 0.8.2'
end
