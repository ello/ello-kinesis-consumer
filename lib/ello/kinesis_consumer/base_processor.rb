require 'knowtify/client'
require 'newrelic_rpm'

module Ello
  module KinesisConsumer
    class BaseProcessor

      include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

      attr_reader :stream_reader

      def self.prefix
        name.split('::').last.gsub('Processor', '').downcase
      end

      def initialize(stream_name: ENV['KINESIS_STREAM_NAME'])
        @stream_reader = StreamReader.new(stream_name: stream_name,
                                          prefix: self.class.prefix)
        @logger = StreamReader.logger
      end

      def run!
        @stream_reader.run! do |record, schema_name|
          @logger.debug "#{schema_name}: #{record}"
          method_name = schema_name.underscore
          send method_name, record if respond_to?(method_name)
        end
      end

    end
  end
end
