# coding: utf-8

Gem::Specification.new do |spec|
  spec.name          = "tennis-jobs-rmq"
  spec.version       = "0.4.0"
  spec.authors       = ["Nicolas ZERMATI"]
  spec.email         = ["nicoolas25@gmail.com"]

  spec.summary       = %q{A RabbitMQ backend for tennis-jobs.}
  spec.description   = %q{A RabbitMQ backend for tennis-jobs.}
  spec.homepage      = "https://github.com/nicoolas25/tennis-rmq"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "bunny"
  spec.add_runtime_dependency "tennis-jobs", "~> 0.4"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "codeclimate-test-reporter"
end
