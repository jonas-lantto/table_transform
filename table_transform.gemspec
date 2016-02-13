# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'table_transform/version'

Gem::Specification.new do |spec|
  spec.name          = 'table_transform'
  spec.version       = TableTransform::VERSION
  spec.authors       = ['Jonas Lantto']
  spec.email         = ['j@lantto.net']

  spec.summary       = %q{Utility to work with csv type data in a name safe environment with utilities to transform data}
  spec.description   = %q{}
  spec.homepage      = 'https://github.com/jonas-lantto/table_transform'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler',    '~> 1.10'
  spec.add_development_dependency 'rake',       '~> 10.0'
  spec.add_development_dependency 'minitest',   '~> 5.0'
  spec.add_development_dependency 'write_xlsx', '~> 0.83'
  spec.add_development_dependency 'roo',        '~> 2.3'
end
