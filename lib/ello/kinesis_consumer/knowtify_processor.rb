module Ello
  module KinesisConsumer
    class KnowtifyProcessor

      def initialize(stream_name: ENV['KINESIS_STREAM_NAME'], logger: Ello::KinesisConsumer.logger)
        @stream_reader = StreamReader.new(stream_name: stream_name, logger: logger)
        @logger = logger
      end

      def run!
        @stream_reader.run! do |record, schema_name|
          method_name = schema_name.underscore
          if respond_to?(method_name)
            send method_name, record
          end
        end
      end

      def user_was_created(record)
        @logger.info "UserWasCreated: #{record}"
      end

      def user_was_updated(record)
        @logger.info "UserWasUpdated: #{record}"
      end

      def user_was_deleted(record)
        @logger.info "UserWasDeleted: #{record}"
      end

    end
  end
end
