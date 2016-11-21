require 'ello/kinesis_consumer/base_processor'
require 'ello/mailchimp_wrapper'

module Ello
  module KinesisConsumer
    class MailchimpProcessor < BaseProcessor

      def invitation_was_sent(record)
        mailchimp.upsert_to_users_list record['invitation']['email'],
                                       record['invitation']['subscription_preferences'],
                                       [],
                                       { ACCOUNT: 'FALSE', SYSTEM: record['invitation']['is_system_generated'].to_s.upcase }
      end

      def user_was_created(record)
        mailchimp.upsert_to_users_list record['email'],
                                       record['subscription_preferences'],
                                       [],
                                       { ACCOUNT: 'TRUE' }
      end
      add_transaction_tracer :user_was_created, category: :task

      def user_changed_email(record)
        mailchimp.remove_from_users_list record['previous_email']
        mailchimp.upsert_to_users_list record['email'], record['subscription_preferences']
      end
      add_transaction_tracer :user_changed_email, category: :task

      def user_changed_subscription_preferences(record)
        mailchimp.upsert_to_users_list record['email'],
                                       record['subscription_preferences'],
                                       record['followed_categories'] || []
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
