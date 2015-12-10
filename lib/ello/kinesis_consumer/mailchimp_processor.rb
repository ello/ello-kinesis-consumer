require 'ello/kinesis_consumer/base_processor'
require 'ello/mailchimp_wrapper'

module Ello
  module KinesisConsumer
    class MailchimpProcessor < BaseProcessor

      def user_received_experimental_features(record)
        mailchimp.upsert_to_experimental_list record['email']
      end

      def user_lost_experimental_features(record)
        mailchimp.remove_from_experimental_list record['email']
      end

      def user_was_created(record)
        mailchimp.upsert_to_users_list record['email'], record['subscription_preferences']
        if record['has_experimental_features']
          mailchimp.upsert_to_experimental_list record['email']
        end
      end

      def user_changed_email(record)
        mailchimp.remove_from_users_list record['previous_email']
        mailchimp.upsert_to_users_list record['email'], record['subscription_preferences']
        if record['has_experimental_features']
          mailchimp.remove_from_experimental_list record['previous_email']
          mailchimp.upsert_to_experimental_list record['email']
        end
      end

      def user_changed_subscription_preferences(record)
        mailchimp.upsert_to_users_list record['email'], record['subscription_preferences']
        if record['has_experimental_features']
          mailchimp.upsert_to_experimental_list record['email']
        else
          mailchimp.remove_from_experimental_list record['email']
        end
      end

      def user_was_deleted(record)
        mailchimp.remove_from_users_list record['email']
        mailchimp.remove_from_experimental_list record['email']
      end

      private

      def mailchimp
        MailchimpWrapper.new
      end

    end
  end
end
