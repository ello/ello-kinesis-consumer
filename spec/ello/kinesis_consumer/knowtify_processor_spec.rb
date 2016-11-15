require 'spec_helper'

describe Ello::KinesisConsumer::KnowtifyProcessor, freeze_time: true do

  it 'sets the prefix name to "knowtify"' do
    expect(described_class.prefix).to eq('knowtify')
    expect(StreamReader).to receive(:new).with(stream_name: 'foo', prefix: 'knowtify')
    described_class.new(stream_name: 'foo')
  end

  describe 'processing events' do

    let(:processor) { described_class.new }

    before do
      allow_any_instance_of(Knowtify::Client).to receive(:upsert)
      allow_any_instance_of(Knowtify::Client).to receive(:delete)
      allow_any_instance_of(StreamReader).to receive(:run!).and_yield(record, schema_name)
    end

    describe 'when presented with a InvitationWasSent event' do
      let(:schema_name) { 'invitation_was_sent' }
      let(:record) do
        {
          'invitation' => {
            'email' => 'test@example.com',
            'is_system_generated' => 'true',
            'subscription_preferences' => {
              'users_email_list' => true,
              'daily_ello' => true,
              'weekly_ello' => true,
              'onboarding_drip' => false,
              'invitation_drip' => true
            }
          }
        }
      end

      it 'creates a record in Knowtify' do
        expect_any_instance_of(Knowtify::Client).to receive(:upsert).with([{
          email: 'test@example.com',
          data: {
            subscribed_to_users_email_list: true,
            subscribed_to_daily_ello: true,
            subscribed_to_weekly_ello: true,
            subscribed_to_onboarding_drip: false,
            subscribed_to_invitation_drip: true,
            system_generated_invite: 'true',
            has_account: false
          }
        }])
        processor.run!
      end
    end

    describe 'when presented with a UserWasCreated event' do
      let(:schema_name) { 'user_was_created' }
      let(:record) do
        {
          'email' => 'test@example.com',
          'username' => 'testuser',
          'followed_categories' => ['Art'],
          'created_at' => Time.now.to_f,
          'subscription_preferences' => {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => true,
            'invitation_drip' => false
          }
        }
      end

      it 'creates a record in Knowtify' do
        expect_any_instance_of(Knowtify::Client).to receive(:upsert).with([{
          email: 'test@example.com',
          name: 'testuser',
          data: {
            username: 'testuser',
            followed_categories: ['Art'],
            created_at: Time.now.to_datetime,
            subscribed_to_users_email_list: true,
            subscribed_to_onboarding_drip: true,
            subscribed_to_daily_ello: true,
            subscribed_to_weekly_ello: true,
            subscribed_to_invitation_drip: false,
            has_account: true
          }
        }])
        processor.run!
      end
    end

    describe 'when presented with a UserChangedEmail event' do
      let(:schema_name) { 'user_changed_email' }
      let(:record) do
        {
          'username' => 'testuser',
          'email' => 'test2@example.com',
          'previous_email' => 'test@example.com',
          'created_at' => Time.now.to_f,
          'subscription_preferences' => {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => true
          }
        }
      end

      it 'removes and recreates a record in Knowtify' do
        expect_any_instance_of(Knowtify::Client).to receive(:delete).with([ 'test@example.com' ])
        expect_any_instance_of(Knowtify::Client).to receive(:upsert).with([{
          email: 'test2@example.com',
          name: 'testuser',
          data: {
            username: 'testuser',
            created_at: Time.now.to_datetime,
            subscribed_to_users_email_list: true,
            subscribed_to_onboarding_drip: true,
            subscribed_to_daily_ello: true,
            subscribed_to_weekly_ello: true
          }
        }])
        processor.run!
      end
    end

    describe 'when presented with a UserChangedSubscriptionPreferences event' do
      let(:schema_name) { 'user_changed_subscription_preferences' }
      let(:record) do
        {
          'username' => 'testuser',
          'email' => 'test2@example.com',
          'created_at' => Time.now.to_f,
          'subscription_preferences' => {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => true
          }
        }
      end

      it 'updates a record in Knowtify' do
        expect_any_instance_of(Knowtify::Client).to receive(:upsert).with([{
          email: 'test2@example.com',
          name: 'testuser',
          data: {
            username: 'testuser',
            created_at: Time.now.to_datetime,
            subscribed_to_users_email_list: true,
            subscribed_to_onboarding_drip: true,
            subscribed_to_daily_ello: true,
            subscribed_to_weekly_ello: true
          }
        }])
        processor.run!
      end
    end

    describe 'when presented with a UserWasDestroyed event' do
      let(:schema_name) { 'user_was_deleted' }
      let(:record) do
        {
          'email' => 'test@example.com',
          'deleted_at' => Time.now.to_f,
          'subscription_preferences' => {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => true
          }
        }
      end

      it 'removes a record in Knowtify' do
        expect_any_instance_of(Knowtify::Client).to receive(:delete).with([ 'test@example.com' ])
        processor.run!
      end
    end
  end

end
