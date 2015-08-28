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
          send method_name, record if respond_to?(method_name)
        end
      end

      def user_was_created(record)
        begin
          knowtify_client.upsert [{ email: record['email'],
                                    name: record['username'],
                                    data: {
                                      username: record['username'],
                                      subscription_preferences: (record['subscription_preferences'] || {}).symbolize_keys,
                                      created_at: Time.at(record['created_at']).to_datetime
                                    }
                                  }]
        rescue TypeError
          @logger.info "Unable to parse date: #{record['created_at']}"
        end
      end

      def user_changed_email(record)
        begin
          knowtify_client.delete [ record['previous_email'] ]
          knowtify_client.upsert [{ email: record['email'],
                                    name: record['username'],
                                    data: {
                                      username: record['username'],
                                      subscription_preferences: (record['subscription_preferences'] || {}).symbolize_keys,
                                      created_at: Time.at(record['created_at']).to_datetime
                                    }
                                  }]
        rescue TypeError
          @logger.info "Unable to parse date: #{record['created_at']}"
        end
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
