require 'ello/kinesis_consumer/base_processor'
require 'ello/mailchimp_wrapper'

module Ello
  module KinesisConsumer
    class MailchimpProcessor < BaseProcessor

      # def user_got_experimental_features(record)
      #   # Subscribe to experimental
      #   hash = subscriber_hash(record['email'])
      #   experimental_list.members(hash).upsert(
      #     body: {
      #       email_address: record['email'],
      #       status: 'subscribed'
      #     })
      # end

      # def user_lost_experimental_features(record)
      #   # Unsubscribe from experimental
      #   hash = subscriber_hash(record['email'])
      #   experimental_list.members(hash).update(
      #     body: {
      #       status: 'unsubscribed'
      #     })
      # end

      def user_was_created(record)
        mailchimp.upsert_to_users_list record['email'], record['subscription_preferences']
      end

      def user_changed_email(record)
        mailchimp.remove_from_users_list record['previous_email']
        mailchimp.upsert_to_users_list record['email'], record['subscription_preferences']
        # Same for experimental list?
      end

      def user_changed_subscription_preferences(record)
        # Update specified groups
        mailchimp.upsert_to_users_list record['email'], record['subscription_preferences']
      end

      def user_was_deleted(record)
        # Remove email from users list
        mailchimp.remove_from_users_list record['email']
      end

      private

      def mailchimp
        MailchimpWrapper.new
      end

    end
  end
end
