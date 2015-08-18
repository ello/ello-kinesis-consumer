$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ello/kinesis_consumer'
require 'fakeredis/rspec'
require 'pry'

require 'dotenv'
Dotenv.load

require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = 'spec/support/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.filter_sensitive_data('<KNOWTIFY_API_TOKEN>') { ENV['KNOWTIFY_API_TOKEN'] }
  c.filter_sensitive_data('<AWS_ACCESS_KEY_ID>') { ENV['AWS_ACCESS_KEY_ID'] }
  c.filter_sensitive_data('<AWS_SECRET_ACCESS_KEY>') { ENV['AWS_SECRET_ACCESS_KEY'] }
end

require 'timecop'
RSpec.configure do |c|
  c.around(:each, freeze_time: true) do |example|
    Timecop.freeze(Date.today) do
      example.run
    end
  end
end