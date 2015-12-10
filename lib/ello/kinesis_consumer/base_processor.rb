require 'knowtify/client'

module Ello
  module KinesisConsumer
    class BaseProcessor

      attr_reader :stream_reader

      def self.prefix
        name.split('::').last.gsub('Processor', '').downcase
      end

      def initialize(stream_name: ENV['KINESIS_STREAM_NAME'], logger: Ello::KinesisConsumer.logger)
        @stream_reader = StreamReader.new(stream_name: stream_name,
                                          prefix: self.class.prefix,
                                          logger: logger)
        @logger = logger
      end

      def run!
        @stream_reader.run! do |record, schema_name|
          @logger.info "#{schema_name}: #{record}"
          method_name = schema_name.underscore
          send method_name, record if respond_to?(method_name)
        end
      end

    end
  end
end
