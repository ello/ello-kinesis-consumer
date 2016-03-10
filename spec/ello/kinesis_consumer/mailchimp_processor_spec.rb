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

    describe 'when presented with a UserWasCreated event' do
      let(:schema_name) { 'user_was_created' }
      let(:record) do
        {
          'email' => 'jay@ello.co',
          'username' => 'jayzes',
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
          'jay@ello.co',
          {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => false
          })
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
          'jz@ello.co',
          {
            'users_email_list' => true,
            'onboarding_drip' => true,
            'daily_ello' => true,
            'weekly_ello' => false
          })
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
          })
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
  end
end
