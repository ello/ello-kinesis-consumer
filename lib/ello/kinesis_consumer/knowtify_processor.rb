require 'knowtify/client'
require 'ello/kinesis_consumer/base_processor'

module Ello
  module KinesisConsumer
    class KnowtifyProcessor < BaseProcessor

      def invitation_was_sent(record)
        knowtify_client.upsert [{ email: record['email'],
                                  data: {
                                    subscribed_to_users_email_list: record['subscription_preferences']['users_email_list'],
                                    subscribed_to_daily_ello: record['subscription_preferences']['daily_ello'],
                                    subscribed_to_weekly_ello: record['subscription_preferences']['weekly_ello'],
                                    subscribed_to_invitation_drip: record['subscription_preferences']['invitation_drip'],
                                  }
                                }]
      end

      def user_was_created(record)
        begin
          knowtify_client.upsert [{ email: record['email'],
                                    name: record['username'],
                                    data: {
                                      username: record['username'],
                                      subscribed_to_users_email_list: record['subscription_preferences']['users_email_list'],
                                      subscribed_to_daily_ello: record['subscription_preferences']['daily_ello'],
                                      subscribed_to_weekly_ello: record['subscription_preferences']['weekly_ello'],
                                      subscribed_to_onboarding_drip: record['subscription_preferences']['onboarding_drip'],
                                      followed_categories: record['followed_categories'],
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
                                      subscribed_to_users_email_list: record['subscription_preferences']['users_email_list'],
                                      subscribed_to_daily_ello: record['subscription_preferences']['daily_ello'],
                                      subscribed_to_weekly_ello: record['subscription_preferences']['weekly_ello'],
                                      subscribed_to_onboarding_drip: record['subscription_preferences']['onboarding_drip'],
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
                                      subscribed_to_users_email_list: record['subscription_preferences']['users_email_list'],
                                      subscribed_to_daily_ello: record['subscription_preferences']['daily_ello'],
                                      subscribed_to_weekly_ello: record['subscription_preferences']['weekly_ello'],
                                      subscribed_to_onboarding_drip: record['subscription_preferences']['onboarding_drip'],
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
