#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'
Bundler.require
Dotenv.load

# Wire up Redis
uri = URI.parse(ENV['REDIS_URL'] || 'redis://localhost:6379')
Redis.current = Redis.new(:url => uri)
last_sequence_number = Redis.current.get('drip-kinesis-last-seq')

stream_name = ENV['KINESIS_STREAM_NAME']
client = Aws::Kinesis::Client.new

# Locate a shard id to iterate through
# We only have one for now.
resp = client.describe_stream(stream_name: stream_name, limit: 1)
shard_id = resp.stream_description.shards[0].shard_id

# Get an initial iterator
loop do
  begin
    iterator_opts = {
      stream_name: stream_name,
      shard_id: shard_id,
    }
    if last_sequence_number
      iterator_opts[:shard_iterator_type] = 'AFTER_SEQUENCE_NUMBER'
      iterator_opts[:starting_sequence_number] = last_sequence_number
    else
      iterator_opts[:shard_iterator_type] = 'TRIM_HORIZON'
    end
    resp = client.get_shard_iterator(iterator_opts)
    shard_iterator = resp.shard_iterator


    # Iterate!
    loop do
      puts "Getting records for #{shard_iterator}"
      resp = client.get_records({
        shard_iterator: shard_iterator,
        limit: 10,
      })

      resp.records.each do |record|
        begin
          file = StringIO.new(record.data)
          reader = Avro::DataFile::Reader.new(file, Avro::IO::DatumReader.new)
          reader.each do |avro_record|
            event_name = reader.datum_reader.readers_schema.name
            puts "[#{record.sequence_number}] #{event_name}: #{avro_record}"
          end
        rescue Avro::DataFile::DataFileError => e
          puts "[#{record.sequence_number}] Unable to parse Avro record: #{e.inspect}"
        end
        last_sequence_number = record.sequence_number
        Redis.current.set('drip-kinesis-last-seq', last_sequence_number)
      end

      shard_iterator = resp.next_shard_iterator
    end

  rescue Aws::Kinesis::Errors::ExpiredIteratorException
    puts "Iterator expired! Fetching a new one."
  end
end
