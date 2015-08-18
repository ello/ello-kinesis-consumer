require 'knowtify/client'

module Ello
  module KinesisConsumer
    class KnowtifyProcessor

      def initialize(stream_name: ENV['KINESIS_STREAM_NAME'], logger: Ello::KinesisConsumer.logger)
        @stream_reader = StreamReader.new(stream_name: stream_name, prefix: 'knowtify', logger: logger)
        @logger = logger
      end

      def run!
        @stream_reader.run! do |record, schema_name|
          @logger.info "#{schema_name}: #{record}"
          method_name = schema_name.underscore
          if respond_to?(method_name)
            send method_name, record
          end
        end
      end

      def user_was_created(record)
        knowtify_client.upsert [{ email: record['email'],
                                  data: {
                                    username: record['username'],
                                    created_at: Date.iso8601(record['created_at']).to_datetime
                                  }
                                }]
      end

      def user_changed_email(record)
        knowtify_client.delete [ record['previous_email'] ]
        knowtify_client.upsert [{ email: record['email'],
                                  data: {
                                    username: record['username'],
                                    created_at: Date.iso8601(record['created_at']).to_datetime
                                  }
                                }]
      end

      def user_was_deleted(record)
        knowtify_client.delete [ record['email'] ]
      end

      private

      def knowtify_client
        @knowtify_client ||= Knowtify::Client.new
      end

    end
  end
end
