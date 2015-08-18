# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ello/kinesis_consumer/version'

Gem::Specification.new do |spec|
  spec.name          = "ello-kinesis-consumer"
  spec.version       = Ello::KinesisConsumer::VERSION
  spec.authors       = ["Jay Zeschin"]
  spec.email         = ["jay@ello.co"]

  spec.summary       = %q{A runner for setting up workers to process events from a Kinesis stream}
  spec.homepage      = "https://github.com/ello/ello-kinesis-consumer"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = nil
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "fakeredis"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "timecop"

  spec.add_dependency "aws-sdk-core", "~> 2.1.13"
  spec.add_dependency "redis", "~> 3.2.1"
  spec.add_dependency "avro", "~> 1.7.7"
end