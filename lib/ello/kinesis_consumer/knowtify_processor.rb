require 'knowtify/client'
require 'ello/kinesis_consumer/base_processor'

module Ello
  module KinesisConsumer
    class KnowtifyProcessor < BaseProcessor

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

      def user_changed_subscription_preferences(record)
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
