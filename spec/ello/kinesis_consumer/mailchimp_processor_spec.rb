require 'spec_helper'

describe Ello::KinesisConsumer::MailchimpProcessor, freeze_time: true do

  it 'sets the prefix name to "mailchimp"' do
    expect(described_class.prefix).to eq('mailchimp')
    expect(StreamReader).to receive(:new).with(stream_name: 'foo',
                                               prefix: 'mailchimp')
    described_class.new(stream_name: 'foo')
  end

  describe 'processing events' do

    let(:processor) { described_class.new }

    before do
      allow_any_instance_of(StreamReader).to receive(:run!).and_yield(record, schema_name)
      allow_any_instance_of(MailchimpWrapper).to receive(:upsert_to_users_list)
      allow_any_instance_of(MailchimpWrapper).to receive(:remove_from_users_list)
    end

    describe 'when presented with a InvitationWasSent event' do
      let(:schema_name) { 'invitation_was_sent' }
      let(:record) do
        {
          'invitation' => {
            'email' => 'jay@ello.co',
            'is_system_generated' => 'true',
            'subscription_preferences' => {
              'users_email_list' => true,
              'invitation_drip' => true,
              'onboarding_drip' => false,
              'daily_ello' => true,
              'weekly_ello' => true
            }
          }
        }
      end

      it 'adds to the users list with the proper interest groups' do
        expect_any_instance_of(MailchimpWrapper).to receive(:upsert_to_users_list).with(
          email: 'jay@ello.co',
          preferences: {
            'users_email_list' => true,
            'invitation_drip' => true,
            'onboarding_drip' => false,
            'daily_ello' => true,
            'weekly_ello' => true
          },
          merge_fields: { ACCOUNT: 'FALSE', SYSTEM: 'TRUE' },
          force_resubscribe: false)
        processor.run!
      end
    end

    describe 'when presented with a StartedSignUp event' do
      let(:schema_name) { 'started_sign_up' }
      let(:record) do
        {
          'email' => 'jay@ello.co',
          'subscription_preferences' => {
            'users_email_list' => true,
            'invitation_drip' => true,
            'onboarding_drip' => false,
            'daily_ello' => true,
            'weekly_ello' => true
          }
        }
      end

      it 'adds to the users list with the proper interest groups' do
        expect_any_instance_of(MailchimpWrapper).to receive(:upsert_to_users_list).with(
          email: 'jay@ello.co',
          preferences: {
            'users_email_list' => true,
            'invitation_drip' => true,
            'onboarding_drip' => false,
            'daily_ello' => true,
            'weekly_ello' => true
          },
          categories: [],
          merge_fields: { ACCOUNT: 'FALSE', SYSTEM: 'TRUE' },
          force_resubscribe: true)
        processor.run!
      end
    end

    describe 'when presented with a UserWasCreated event' do
      let(:schema_name) { 'user_was_created' }
      let(:record) do
        {
          'email' => 'jay@ello.co',
          'username' => 'jayzes',
          'followed_categories' => ['Art'],
          'created_at' => Time.now.to_f,
          'has_experimental_features' => false,
          'subscription_preferences' => {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => false
          }
        }
      end

      it 'adds to the users list with the proper interest groups' do
        expect_any_instance_of(MailchimpWrapper).to receive(:upsert_to_users_list).with(
          email: 'jay@ello.co',
          preferences: {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => false
          },
          categories: [],
          merge_fields: { ACCOUNT: 'TRUE' },
          force_resubscribe: true)
        processor.run!
      end
    end

    describe 'when presented with a UserChangedEmail event' do
      let(:schema_name) { 'user_changed_email' }
      let(:record) do
        {
          'email' => 'jz@ello.co',
          'previous_email' => 'jay@ello.co',
          'username' => 'jayzes',
          'created_at' => Time.now.to_f,
          'has_experimental_features' => true,
          'subscription_preferences' => {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => false
          }
        }
      end

      it 'updates the record in Mailchimp' do
        expect_any_instance_of(MailchimpWrapper).to receive(:remove_from_users_list).with('jay@ello.co')
        expect_any_instance_of(MailchimpWrapper).to receive(:upsert_to_users_list).with(
          email: 'jz@ello.co',
          preferences: {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => false
          },
          force_resubscribe: false)
        processor.run!
      end
    end

    describe 'when presented with a UserChangedSubscriptionPreferences event' do
      let(:schema_name) { 'user_changed_subscription_preferences' }
      let(:record) do
        {
          'username' => 'testuser',
          'email' => 'jay@ello.co',
          'created_at' => Time.now.to_f,
          'has_experimental_features' => false,
          'followed_categories' => %w(Art Writing),
          'subscription_preferences' => {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => true
          }
        }
      end

      it 'updates a record in Mailchimp' do
        expect_any_instance_of(MailchimpWrapper).to receive(:upsert_to_users_list).with(
          email: 'jay@ello.co',
          preferences: {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => true
          },
          categories: %w(Art Writing),
          force_resubscribe: false)
        processor.run!
      end
    end

    describe 'when presented with a UserWasDestroyed event' do
      let(:schema_name) { 'user_was_deleted' }
      let(:record) do
        {
          'email' => 'jay@ello.co',
          'deleted_at' => Time.now.to_f,
          'subscription_preferences' => {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => true
          }
        }
      end

      it 'removes the email from the users list in Mailchimp' do
        expect_any_instance_of(MailchimpWrapper).to receive(:remove_from_users_list).with('jay@ello.co')
        processor.run!
      end
    end

    describe 'when presented with a UserTokenGranted event' do
      let(:schema_name) { 'user_token_granted' }
      let(:now) { Time.now.to_f }
      let(:record) do
        {
          'username' => 'testuser',
          'name' => 'jay',
          'email' => 'jay@ello.co',
          'created_at' => now,
          'has_experimental_features' => false,
          'followed_categories' => %w(Art Writing),
          'subscription_preferences' => {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => true
          }
        }
      end

      it 'updates a record in Mailchimp' do
        expect_any_instance_of(MailchimpWrapper).to receive(:upsert_to_users_list).with(
          'jay@ello.co',
          {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => true
          },
          %w(Art Writing),
          {
            USERNAME: 'testuser',
            NAME: 'jay',
            HAS_AVATAR: nil,
            HAS_COVER: nil,
            HAS_BIO: nil,
            HAS_LINKS: nil,
            LOCATION: nil,

            CREATED_AT: now,
            UPDATED_AT: nil,
            LAST_SEEN: nil,
            LAST_POST: nil,
            LAST_CMMNT: nil,
            LAST_LOVE: nil,

            LOVES_GVN: nil,
            POSTS: nil,
            FOLLOWERS: nil,
            FOLLOWING: nil,
            INVITES: nil,
            COMMENTS: nil,
            REPOSTS: nil,
            LOVES_RCVD: nil,
            SALEABLE: nil,

            COLLAB: nil,
            HIREABLE: nil,
          }
        )
        processor.run!
      end
    end
  end
end
