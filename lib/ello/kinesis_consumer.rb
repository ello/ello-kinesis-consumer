require 'logger'
require 'ello/string_extensions'
require 'ello/hash_extensions'
require 'ello/librato_reporter'

require 'ello/kinesis_consumer/version'
require 'ello/kinesis_consumer/avro_parser'
require 'ello/kinesis_consumer/sequence_number_tracker'
require 'ello/kinesis_consumer/stream_reader'

require 'ello/kinesis_consumer/knowtify_processor'

module Ello
  module KinesisConsumer
    class << self
      def logger
        @logger ||= Logger.new(STDOUT)
      end
    end
  end
end
