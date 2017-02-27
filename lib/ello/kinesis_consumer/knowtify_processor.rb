require 'knowtify/client'
require 'ello/kinesis_consumer/base_processor'

module Ello
  module KinesisConsumer
    class KnowtifyProcessor < BaseProcessor

      def invitation_was_sent(record)
        knowtify_client.upsert [{ email: record['invitation']['email'],
                                  data: {
                                    subscribed_to_users_email_list: record['invitation']['subscription_preferences']['users_email_list'],
                                    subscribed_to_daily_ello: record['invitation']['subscription_preferences']['daily_ello'],
                                    subscribed_to_weekly_ello: record['invitation']['subscription_preferences']['weekly_ello'],
                                    subscribed_to_onboarding_drip: record['invitation']['subscription_preferences']['onboarding_drip'],
                                    subscribed_to_invitation_drip: true,
                                    system_generated_invite: record['invitation']['is_system_generated'],
                                    has_account: false
                                  }
                                }]
      end

      def started_sign_up(record)
        knowtify_client.upsert [{ email: record['email'],
                                  data: {
                                    subscribed_to_users_email_list: record['subscription_preferences']['users_email_list'],
                                    subscribed_to_daily_ello: record['subscription_preferences']['daily_ello'],
                                    subscribed_to_weekly_ello: record['subscription_preferences']['weekly_ello'],
                                    subscribed_to_onboarding_drip: record['subscription_preferences']['onboarding_drip'],
                                    subscribed_to_invitation_drip: true,
                                    system_generated_invite: true,
                                    has_account: false
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
                                      subscribed_to_invitation_drip: false,
                                      followed_categories: record['followed_categories'],
                                      created_at: Time.at(record['created_at']).to_datetime,
                                      has_account: true
                                    }
                                  }]
        rescue TypeError
          @logger.error "Unable to parse date: #{record['created_at']}"
        end
      end
      add_transaction_tracer :user_was_created, category: :task


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
          @logger.error "Unable to parse date: #{record['created_at']}"
        end
      end
      add_transaction_tracer :user_changed_email, category: :task

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
          @logger.error "Unable to parse date: #{record['created_at']}"
        end
      end
      add_transaction_tracer :user_changed_subscription_preferences, category: :task

      def user_was_deleted(record)
        knowtify_client.delete [ record['email'] ]
      end
      add_transaction_tracer :user_was_deleted, category: :task

      def user_was_locked(record)
        knowtify_client.delete [ record['email'] ]
      end
      add_transaction_tracer :user_was_locked, category: :task

      def user_was_unlocked(record)
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
          @logger.error "Unable to parse date: #{record['created_at']}"
        end
      end
      add_transaction_tracer :user_was_unlocked, category: :task

      private

      def knowtify_client
        @knowtify_client ||= Knowtify::Client.new
      end

    end
  end
end
