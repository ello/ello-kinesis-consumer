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

      def user_token_granted(record)
        mailchimp.upsert_to_users_list record['email'],
                                       record['subscription_preferences'],
                                       record['followed_categories'] || [],
                                       merge_fields_for_user(record)
      end
      add_transaction_tracer :user_token_granted, category: :task

      private

      def mailchimp
        MailchimpWrapper.new
      end

      def merge_fields_for_user(user_record, overrides = {})
        {
          USERNAME: user_record['username'],
          NAME: user_record['name'],
          HAS_AVATAR: user_record['has_avatar'],
          HAS_COVER: user_record['has_cover_image'],
          HAS_BIO: user_record['has_bio'],
          HAS_LINKS: user_record['has_links'],
          LOCATION: user_record['location'],

          CREATED_AT: user_record['created_at'],
          UPDATED_AT: user_record['updated_at'],
          LAST_SEEN: user_record['last_seen_at'],
          LAST_POST: user_record['last_posted_at'],
          LAST_CMMNT: user_record['last_commented_at'],
          LAST_LOVE: user_record['last_loved_at'],

          LOVES_GVN: user_record['loves_count'],
          POSTS: user_record['posts_count'],
          FOLLOWERS: user_record['followers_count'],
          FOLLOWING: user_record['following_count'],
          INVITES: user_record['invitations_count'],
          COMMENTS: user_record['comments_count'],
          REPOSTS: user_record['reposts_count'],
          LOVES_RCVD: user_record['loves_received_count'],
          SALEABLE: user_record['saleable_posts_count'],

          COLLAB: user_record['is_collaborateable'],
          HIREABLE: user_record['is_hireable'],
        }.merge(overrides)
      end
    end
  end
end
