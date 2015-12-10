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

begin
  require 'honeybadger'
  Honeybadger.start
rescue LoadError
  puts 'Honeybadger is unavailable, skipping'
end

$LOAD_PATH.unshift File.expand_path('./lib', __FILE__)
require 'ello/kinesis_consumer'


Ello::KinesisConsumer.logger.level = Logger::INFO

namespace :ello do
  task :process_knowtify_events do
    begin
      Ello::LibratoReporter.run!
      Ello::KinesisConsumer::KnowtifyProcessor.new.run!
    rescue StandardError => e
      Honeybadger.notify(e) if defined?(Honeybadger)
      raise e
    end
  end

  task :process_mailchimp_events do
    begin
      Ello::LibratoReporter.run!
      Ello::KinesisConsumer::MailchimpProcessor.new.run!
    rescue StandardError => e
      Honeybadger.notify(e) if defined?(Honeybadger)
      raise e
    end
  end
end
