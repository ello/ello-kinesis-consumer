require 'ello/kinesis_consumer/base_processor'
require 'ello/mailchimp_wrapper'

module Ello
  module KinesisConsumer
    class MailchimpProcessor < BaseProcessor

      def invitation_was_sent(record)
        mailchimp.upsert_to_users_list email: record['invitation']['email'],
                                       preferences: record['invitation']['subscription_preferences'],
                                       merge_fields: {
                                         ACCOUNT: 'FALSE',
                                         SYSTEM: record['invitation']['is_system_generated'].to_s.upcase
                                       },
                                       force_resubscribe: false
      end

      def started_sign_up(record)
        mailchimp.upsert_to_users_list email: record['email'],
                                       preferences: record['subscription_preferences'],
                                       categories: [],
                                       merge_fields: { ACCOUNT: 'FALSE', SYSTEM: 'TRUE' },
                                       force_resubscribe: true
      end

      def user_was_created(record)
        mailchimp.upsert_to_users_list email: record['email'],
                                       preferences: record['subscription_preferences'],
                                       categories: [],
                                       merge_fields: { ACCOUNT: 'TRUE' },
                                       force_resubscribe: true
      end
      add_transaction_tracer :user_was_created, category: :task

      def user_changed_email(record)
        mailchimp.remove_from_users_list record['previous_email']
        mailchimp.upsert_to_users_list email: record['email'],
                                       preferences: record['subscription_preferences'],
                                       force_resubscribe: false
      end
      add_transaction_tracer :user_changed_email, category: :task

      def user_changed_subscription_preferences(record)
        mailchimp.upsert_to_users_list email: record['email'],
                                       preferences: record['subscription_preferences'],
                                       categories: (record['followed_categories'] || []),
                                       force_resubscribe: false
      end
      add_transaction_tracer :user_changed_subscription_preferences, category: :task

      def user_was_deleted(record)
        mailchimp.remove_from_users_list record['email']
      end
      add_transaction_tracer :user_was_deleted, category: :task

      private

      def mailchimp
        MailchimpWrapper.new
      end

    end
  end
end
