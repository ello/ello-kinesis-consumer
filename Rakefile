begin
  require 'dotenv'
  Dotenv.load
rescue LoadError
  puts 'Dotenv is unavailable, skipping'
end

begin
  require "bundler/gem_tasks"
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec

rescue LoadError
  puts 'Rspec is unavailable, skipping'
end

$LOAD_PATH.unshift File.expand_path('./lib', __FILE__)
require 'ello/kinesis_consumer'

namespace :ello do
  task :process_knowtify_events do
    Ello::KinesisConsumer::KnowtifyProcessor.new.run!
  end
end
