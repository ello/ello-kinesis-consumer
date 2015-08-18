require 'aws-sdk-core'

module Ello
  module KinesisConsumer
    class StreamReader

      # Assume only one shard for now
      BATCH_SIZE = 10

      def initialize(stream_name:, prefix: '', logger: Ello::KinesisConsumer.logger)
        @stream_name = stream_name
        @tracker = SequenceNumberTracker.new(key_prefix: [ stream_name, prefix ].compact.join('-'))
        @logger = logger
      end

      def run!(&block)
        # Locate a shard id to iterate through - we only have one for now
        loop do
          begin
            iterator_opts = { stream_name: @stream_name, shard_id: shard_id }
            if seq = @tracker.last_sequence_number
              iterator_opts[:shard_iterator_type] = 'AFTER_SEQUENCE_NUMBER'
              iterator_opts[:starting_sequence_number] = seq
            else
              iterator_opts[:shard_iterator_type] = 'TRIM_HORIZON'
            end
            resp = client.get_shard_iterator(iterator_opts)
            shard_iterator = resp.shard_iterator

            # Iterate!
            loop do
              @logger.info "Getting records for #{shard_iterator}"
              resp = client.get_records({
                shard_iterator: shard_iterator,
                limit: BATCH_SIZE,
              })

              resp.records.each do |record|
                AvroParser.new(record.data).each_with_schema_name(&block)
                @tracker.last_sequence_number = record.sequence_number
              end

              shard_iterator = resp.next_shard_iterator
            end

          rescue Aws::Kinesis::Errors::ExpiredIteratorException
            @logger.info "Iterator expired! Fetching a new one."
          end
        end
      end

      private

      def client
        @client ||= Aws::Kinesis::Client.new
      end

      def shard_id
        @shard_id ||= begin
                        resp = client.describe_stream(stream_name: @stream_name, limit: 1)
                        resp.stream_description.shards[0].shard_id
                      end
      end
    end
  end
end